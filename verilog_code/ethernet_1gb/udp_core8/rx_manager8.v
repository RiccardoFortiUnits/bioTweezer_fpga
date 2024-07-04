module rx_manager8 #(
    parameter	AVL_SIZE = 8, //in bits
                MAC_SIZE = 48,
                IP_SIZE = 32,
                BYTE_SIZE = 8)
(

    input rx_xcvr_clk,
    input rx_sync_rst,

    input [MAC_SIZE-1:0]        local_mac,
    input [IP_SIZE-1:0]         local_ip,
    input [2*BYTE_SIZE-1:0]     local_stream_1_port,
    input [2*BYTE_SIZE-1:0]     local_stream_2_port,
   

    input                   st_rx_startofpacket,
    input                   st_rx_endofpacket,
    input                   st_rx_valid,
    output                  st_rx_ready,
    input                   st_rx_error,

    //-----DECODER SECTION
    
    output reg reset_decoders,

    //frame decoder
    output                  decode_frame_run,
    input [MAC_SIZE-1:0]    decode_frame_src_mac,
    input [MAC_SIZE-1:0]    decode_frame_dst_mac,
    input [2*BYTE_SIZE-1:0] decode_frame_packet_type,

    //arp decoder
    output                  decode_arp_run,
    input                   decode_arp_valid,
    input [IP_SIZE-1:0]     decode_arp_src_ip,
    input [IP_SIZE-1:0]     decode_arp_dst_ip,
    input [2*BYTE_SIZE-1:0] decode_arp_operation,
    
    //ip decoder
    output                  decode_ip_pri_run,
    input                   decode_ip_valid,
    input [BYTE_SIZE/2-1:0] decode_ip_offset_count,
    input [BYTE_SIZE-1:0]   decode_ip_protocol,
    input [2*BYTE_SIZE-1:0] decode_ip_packet_length,
    input [BYTE_SIZE/2-1:0] decode_ip_header_length,
    
    output                  decode_ip_sec_run,
    input [IP_SIZE-1:0]     decode_ip_src_ip,
    input [IP_SIZE-1:0]     decode_ip_dst_ip,
    
    //icmp decoder
    output                  decode_icmp_run,
    input [BYTE_SIZE-1:0]   decode_icmp_type,
    input [BYTE_SIZE-1:0]   decode_icmp_code,
    input [2*BYTE_SIZE-1:0] decode_icmp_checksum,

    //udp decoder
    output                  decode_udp_run,
    input [2*BYTE_SIZE-1:0] decode_udp_src_port,
    input [2*BYTE_SIZE-1:0] decode_udp_dst_port,
    input [2*BYTE_SIZE-1:0] decode_udp_packet_length,

    output reg [2*BYTE_SIZE+IP_SIZE+MAC_SIZE-1:0] arp_to_tx,
    output reg arp_to_tx_valid = 0,

    output reg [2*BYTE_SIZE+IP_SIZE+MAC_SIZE-1:0] icmp_to_tx,
    output reg icmp_to_tx_valid = 0,
    output reg [2*BYTE_SIZE-1:0] icmp_checksum = 0,

    output icmp_fifo_run,
    output reg icmp_clear_fifo = 0,

    output reset_aligner,
    output udp_aligner_run,

    output reg [2*BYTE_SIZE+IP_SIZE+MAC_SIZE-1:0] data_udp_status_fifo,
    output reg dvalid_udp_status_fifo = 0,

    output reg select_udp_port = 1'b0,
    output reg disable_data_fifo = 1'b0,

    input tx_busy

);


assign st_rx_ready = 1'b1;

reg reg_in_frame  = 1'b0;

always @ (posedge rx_xcvr_clk)
begin
    if(rx_sync_rst)
    begin
        reg_in_frame <= 1'b0;
    end
    else
    begin
        if(st_rx_startofpacket)
            reg_in_frame <= 1'b1;
        else if (st_rx_endofpacket)
            reg_in_frame <= 1'b0;
    end
end

wire in_frame;
assign in_frame = (reg_in_frame || st_rx_startofpacket);

reg immediate_flush = 1'b0;

//control signals for decoder
reg int_decode_frame_run = 1'b0;
reg int_decode_arp_run = 1'b0;
reg int_decode_ip_pri_run = 1'b0;
reg int_decode_ip_sec_run = 1'b0;
reg int_decode_udp_run = 1'b0;
reg int_decode_icmp_run = 1'b0;
reg int_icmp_fifo_run = 1'b0;
reg int_udp_aligner_run = 1'b0;
reg int_reset_aligner = 1'b0;

assign decode_frame_run = (in_frame) && (st_rx_valid) && int_decode_frame_run;
assign decode_arp_run = (int_decode_arp_run && (st_rx_valid));
assign decode_ip_pri_run = (int_decode_ip_pri_run && (st_rx_valid));
assign decode_ip_sec_run = (int_decode_ip_sec_run && (st_rx_valid));
assign decode_icmp_run = (int_decode_icmp_run && (st_rx_valid));
assign decode_udp_run = (int_decode_udp_run && (st_rx_valid));
assign icmp_fifo_run  = (int_icmp_fifo_run && st_rx_valid);
assign udp_aligner_run = (int_udp_aligner_run && st_rx_valid);
assign reset_aligner = int_reset_aligner;


localparam	FRAME_HEADER_LENGTH = 16'd14,
            ARP_HEADER_LENGTH = 16'd28,
            IP_PRI_HEADER_LENGTH = 16'd12,
            IP_SEC_HEADER_LENGTH = 16'd8,
            UDP_HEADER_LENGTH = 16'd8,
            ICMP_HEADER_LENGTH = 16'd4;

localparam	ARP_PACKET_TYPE = 16'h0806,
            IP_PACKET_TYPE = 16'h0800,
            UDP_PROTOCOL_TYPE = 8'b00010001,
            ICMP_PROTOCOL_TYPE = 8'b00000001;



localparam  IDLE = 0,
            DECODE_FRAME_HEADER = 1,
            STOP_FRAME_HEADER = 2,
            READ_FRAME_HEADER = 3,
            FLUSH_PACKET = 4,
            DECODE_ARP_HEADER = 5,
            DECODE_IP_PRI_HEADER = 6,
            GEN_ARP_RESPONSE = 7,
            READ_IP_PRI_HEADER = 8,
            DECODE_IP_SEC_HEADER = 9,
            READ_IP_SEC_HEADER = 10,
            DECODE_UDP_HEADER = 11,
            DECODE_ICMP_HEADER = 12,
            READ_UDP_HEADER = 13,
            PREPARE_ICMP_1 = 14,
            READ_UDP_HEADER_1 = 15,
            READ_ICMP_HEADER = 16;

reg [4:0] STATE = IDLE;

reg [15:0] decode_counter;

reg [2*BYTE_SIZE-1:0] ip_payload_length;

reg rx_sync_rst_1, rx_sync_rst_2;

always @(posedge rx_xcvr_clk)
begin
    rx_sync_rst_1 <= rx_sync_rst;
    rx_sync_rst_2 <= rx_sync_rst_1;
end


always @ (posedge rx_xcvr_clk)
begin
    if(rx_sync_rst_2)
    begin
        int_decode_frame_run <= 1'b1;
        decode_counter <= 16'd0;
        reset_decoders <= 1'b1;
        int_reset_aligner <= 1'b1;
        arp_to_tx_valid <= 1'b0;
        icmp_to_tx_valid <= 1'b0;
        select_udp_port <= 1'b0;
        disable_data_fifo <= 1'b0;
        STATE <= IDLE;
    end
    else
    begin
        case(STATE)
            IDLE:
            begin
                if(st_rx_startofpacket)
                begin
                    decode_counter <= FRAME_HEADER_LENGTH - 16'd2;
                    STATE <= DECODE_FRAME_HEADER;
                end
                int_decode_frame_run <= 1'b1;
                icmp_clear_fifo <= 1'b0;
                reset_decoders <= 1'b0;
                int_reset_aligner <= 1'b1;
                disable_data_fifo <= 1'b0;
            end

            DECODE_FRAME_HEADER:
            begin
                if(st_rx_valid)
                begin
                    if(decode_counter == 0)
                    begin
                        int_decode_frame_run <= 1'b0;
                        //start both decoders to gain an extra clock cycle
                        int_decode_arp_run <= 1'b1;
                        int_decode_ip_pri_run <= 1'b1;
                        STATE <= READ_FRAME_HEADER;
                    end
                    decode_counter <= decode_counter - 16'd1;
                end
            end

            READ_FRAME_HEADER:
            begin
                if(st_rx_valid)
                begin
                    // check for correct MAC address
                    if((local_mac == decode_frame_dst_mac)	|| (decode_frame_dst_mac == 48'hFF_FF_FF_FF_FF_FF) )
                    begin
                        if (( decode_frame_packet_type == ARP_PACKET_TYPE ) && !tx_busy )
                        begin
                            int_decode_ip_pri_run <= 1'b0;
                            decode_counter <= ARP_HEADER_LENGTH - 16'd2;
                            STATE <= DECODE_ARP_HEADER;
                        end
                        else if ( decode_frame_packet_type == IP_PACKET_TYPE )
                        begin
                            int_decode_arp_run <= 1'b0;
                            decode_counter <= IP_PRI_HEADER_LENGTH - 16'd2;
                            STATE <= DECODE_IP_PRI_HEADER;
                        end
                        else
                        begin //packet type not supported
                            int_decode_arp_run <= 1'b0;
                            int_decode_ip_pri_run <= 1'b0;
                            reset_decoders <= 1'b1;
                            STATE <= FLUSH_PACKET;
                        end
                    end
                    else
                    begin   //wrong mac destination address
                            int_decode_arp_run <= 1'b0;
                            int_decode_ip_pri_run <= 1'b0;
                            reset_decoders <= 1'b1;
                            STATE <= FLUSH_PACKET;
                    end
                end
            end


            DECODE_ARP_HEADER:
            begin
                if(st_rx_valid)
                begin
                    if(decode_counter == 0)
                    begin
                        int_decode_arp_run <= 1'b0;
                        STATE <= GEN_ARP_RESPONSE;
                    end 
                    decode_counter <= decode_counter - 16'd1;
                end
            end

            GEN_ARP_RESPONSE:
            begin
                if(decode_arp_valid)
                begin
                    if ( decode_arp_dst_ip == local_ip )
                    begin
                        if ( decode_arp_operation == 16'h0001 )
                        begin
                            // set the response parameters
                            arp_to_tx <= {ARP_PACKET_TYPE, decode_frame_src_mac, decode_arp_src_ip};
                            arp_to_tx_valid <= 1'b1;
                        end
                    end
                end
                reset_decoders <= 1'b1;
                STATE <= FLUSH_PACKET;
            end

            DECODE_IP_PRI_HEADER:
            begin
                if(st_rx_valid)
                begin
                    if(decode_counter == 0)
                    begin
                        int_decode_ip_pri_run <= 1'b0;
                        int_decode_ip_sec_run <= 1'b1;
                        STATE <= READ_IP_PRI_HEADER;
                    end 
                    decode_counter <= decode_counter - 16'd1;
                end
            end

            READ_IP_PRI_HEADER:
            begin
                if(st_rx_valid)
                    begin
                    if(decode_ip_valid) //only IPv4 supported
                    begin
                        decode_counter <= IP_SEC_HEADER_LENGTH + ({12'b0, decode_ip_offset_count} << 2) - 16'd2; //warning: use offset/header length, header is variable
                        ip_payload_length <= decode_ip_packet_length - ({12'b0, decode_ip_header_length} << 2);
                        STATE <= DECODE_IP_SEC_HEADER;
                    end
                    else
                    begin
                        //only IPv4 supported
                        int_decode_ip_sec_run <= 1'b0;
                        reset_decoders <= 1'b1;
                        STATE <= FLUSH_PACKET;
                    end
                end
            end


            DECODE_IP_SEC_HEADER:
            begin
                if(st_rx_valid)
                begin
                    if(decode_counter == 0)
                    begin
                        int_decode_ip_sec_run <= 1'b0;
                        int_decode_udp_run <= 1'b1;
                        int_decode_icmp_run <= 1'b1;
                        STATE <= READ_IP_SEC_HEADER;
                    end 
                    decode_counter <= decode_counter - 16'd1;
                end
            end

            READ_IP_SEC_HEADER:
            begin
                if(st_rx_valid)     //dove sono veramente necessari questi check? se dvalid va basso, i decoders se ne accorgono, ma la macchina a stati grande no
                begin
                    if(decode_ip_dst_ip == local_ip) //check IP address
                    begin
                        if(decode_ip_protocol == UDP_PROTOCOL_TYPE)
                        begin
                            int_decode_icmp_run <= 1'b0;
                            decode_counter <= UDP_HEADER_LENGTH - 16'd2;
                            icmp_clear_fifo <= 1'b1;
                            STATE <= DECODE_UDP_HEADER;
                        end
                        else if( (decode_ip_protocol == ICMP_PROTOCOL_TYPE) && !tx_busy)
                        begin
                            int_decode_udp_run <= 1'b0;
                            decode_counter <= ICMP_HEADER_LENGTH - 16'd2;
                            int_decode_icmp_run <= 1'b1;
                            STATE <= READ_ICMP_HEADER;
                        end
                        else
                        begin
                            int_decode_udp_run <= 1'b0;
                            int_decode_icmp_run <= 1'b0;
                            icmp_clear_fifo <= 1'b1;
                            reset_decoders <= 1'b1;
                            STATE <= FLUSH_PACKET;
                        end
                    end
                    else
                    begin
                        icmp_clear_fifo <= 1'b1;
                        int_decode_udp_run <= 1'b0;
                        int_decode_icmp_run <= 1'b0;
                        reset_decoders <= 1'b1;
                        STATE <= FLUSH_PACKET;
                    end
                end
            end

            DECODE_UDP_HEADER:
            begin
                if(st_rx_valid)
                begin
                    if(decode_counter == 0)
                    begin
                        int_decode_udp_run <= 1'b0; //need to start saving udp data that is already coming
                                                    //but in a register, otherwise:
                                                    // 1. clearing the fifo is troubling
                                                    // 2. we don't know at the moment which is the correct port
                        STATE <= READ_UDP_HEADER;
                        int_udp_aligner_run <= 1'b1;
                    end 
                    decode_counter <= decode_counter - 16'd1;
                end
            end

            READ_UDP_HEADER:
            begin
            if(st_rx_valid)
            begin
                if ( ((decode_udp_dst_port == local_stream_1_port) ||(decode_udp_dst_port == local_stream_2_port)) && (decode_udp_packet_length != 16'd0) ) //port is correct
                begin
                    if(decode_udp_dst_port == local_stream_2_port)
                    begin
                        select_udp_port <= 1'b1;
                    end
                    else
                    begin
                        select_udp_port <= 1'b0;
                    end

                    if(decode_udp_packet_length == 16'd1)
                    begin
                        int_reset_aligner <= 1'b1;
                        int_udp_aligner_run <= 1'b0;
                        // write status fifo with infos
                        dvalid_udp_status_fifo <= 1'b1;
                        STATE <= FLUSH_PACKET;
                    end
                    else if(decode_udp_packet_length >= 16'd18)
                    begin
                        int_reset_aligner <= 1'b0;
                        decode_counter <= decode_udp_packet_length - 1'b1; //with udp aligner, 2 bytes have already been read
                        STATE <= READ_UDP_HEADER_1;
                    end
                    else
                    begin
                        int_reset_aligner <= 1'b0;
                        decode_counter <= decode_udp_packet_length - 2'd2; //with udp aligner, 2 bytes have already been read
                        STATE <= READ_UDP_HEADER_1;
                    end
                    data_udp_status_fifo <= {decode_udp_packet_length, decode_ip_src_ip, decode_frame_src_mac}; 
                end

                else //number of port is wrong: discard packet
                begin
                    int_udp_aligner_run <= 1'b0;
                    disable_data_fifo <= 1'b1;
                    int_reset_aligner <= 1'b1;
                    reset_decoders <= 1'b1;
                    STATE <= FLUSH_PACKET;
                end
            end
            end

            READ_UDP_HEADER_1:
            begin
                if(st_rx_valid)
                begin
                    if(decode_counter == 0 ) 
                    begin
                        immediate_flush <= 1'b0;
                        int_reset_aligner <= 1'b1;
                        int_udp_aligner_run <= 1'b0;
                        // write status fifo with infos
                        dvalid_udp_status_fifo <= 1'b1;
                        STATE <= FLUSH_PACKET;
                    end
                    else if(st_rx_endofpacket)
                    begin
                        immediate_flush <= 1'b1;
                        int_reset_aligner <= 1'b1;
                        int_udp_aligner_run <= 1'b0;
                        // write status fifo with infos
                        dvalid_udp_status_fifo <= 1'b1;
                        STATE <= FLUSH_PACKET;
                    end
                    decode_counter <= decode_counter - 1'b1;


                end

            end


            READ_ICMP_HEADER:
            begin
                if(st_rx_valid)
                begin
                    if(decode_counter == 0)
                    begin
                        int_decode_icmp_run <= 1'b0; //need to start saving udp data that is already coming
                                                    //but in a register, otherwise:
                                                    // 1. clearing the fifo is troubling
                                                    // 2. we don't know at the moment which is the correct port
                                                    // 3. we have 16 bits of carry out
                        int_icmp_fifo_run <= 1'b1;
                        STATE <= DECODE_ICMP_HEADER;
                    end 
                    decode_counter <= decode_counter - 16'd1;
                end
            end

            DECODE_ICMP_HEADER:
            begin
                if ( decode_icmp_type == 8'h08 )
                begin
                    icmp_to_tx <= {(ip_payload_length - 16'd2), decode_frame_src_mac, decode_ip_src_ip};
                    icmp_checksum <= decode_icmp_checksum;
                    icmp_to_tx_valid <= 1'b1;
                    STATE <= PREPARE_ICMP_1;
                end
                else
                begin
                //clear fifo!
                    icmp_clear_fifo <= 1'b1;
                    int_icmp_fifo_run <= 1'b0;
                    reset_decoders <= 1'b1;
                    STATE <= FLUSH_PACKET;
                end
            end

            PREPARE_ICMP_1:
            begin
                reset_decoders <= 1'b1;
                STATE <= FLUSH_PACKET;
            end

            FLUSH_PACKET:
            begin
                dvalid_udp_status_fifo <= 1'b0;
                reset_decoders <= 1'b0;
                if((st_rx_endofpacket && st_rx_valid) || immediate_flush) // eop can be high for many cycles: it matters only with valid
                begin
                    int_decode_frame_run <= 1'b1;
                    decode_counter <= 16'd0;
                    arp_to_tx_valid <= 1'b0;
                    icmp_to_tx_valid <= 1'b0;
                    int_icmp_fifo_run <= 1'b0;
                    disable_data_fifo <= 1'b0;
                    immediate_flush <= 1'b0;
                    STATE <= IDLE;
                end

            end

            default:
            begin
                int_decode_frame_run <= 1'b1;
                decode_counter <= 16'd0;
                reset_decoders <= 1'b0;
                icmp_to_tx_valid <= 1'b0;
                arp_to_tx_valid <= 1'b0;
                int_icmp_fifo_run <= 1'b0;
                select_udp_port <= 1'b0;
                disable_data_fifo <= 1'b0;
                immediate_flush <= 1'b0;
                STATE <= IDLE;
            end
        endcase
    end
end



endmodule
