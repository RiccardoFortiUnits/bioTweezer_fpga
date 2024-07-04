module tx_manager8 #(
    parameter	AVL_SIZE = 8, //in bits
                MAC_SIZE = 48,
                IP_SIZE = 32,
                BYTE_SIZE = 8)
(

    input tx_xcvr_clk,
    input tx_sync_rst,

    input [MAC_SIZE-1:0]        local_mac,
    input [IP_SIZE-1:0]         local_ip,
    input [2*BYTE_SIZE-1:0]     local_stream_1_port,
    input [2*BYTE_SIZE-1:0]     local_stream_2_port,

`ifdef FOUR_TX_PORTS
    input [2*BYTE_SIZE-1:0]     local_stream_3_port,
    input [2*BYTE_SIZE-1:0]     local_stream_4_port,
`endif

    output reg               st_tx_startofpacket = 1'b0,
    output reg               st_tx_endofpacket = 1'b0,
    output                      st_tx_valid,
    input                    st_tx_ready,
    output                   st_tx_error,

    output reg              reset_encoders,
    output                  encode_run,
    output reg              encode_arp_n_ip,
    output reg              encode_udp_n_icmp,

    output wire [MAC_SIZE-1:0]	    encode_frame_src_mac,
	output reg [MAC_SIZE-1:0]	    encode_frame_dst_mac,
	output reg [2*BYTE_SIZE-1:0]	encode_frame_packet_type,
	
	//arp encoder
	output wire [MAC_SIZE-1:0]	encode_arp_src_mac,
	output reg [MAC_SIZE-1:0]	encode_arp_dst_mac,
	output wire [IP_SIZE-1:0]	encode_arp_src_ip,
	output reg [IP_SIZE-1:0]	encode_arp_dst_ip,
	
	//ip encoder
	output reg [BYTE_SIZE-1:0]	    encode_ip_protocol,
	output wire [IP_SIZE-1:0]	    encode_ip_src_ip,
	output reg [IP_SIZE-1:0]	    encode_ip_dst_ip,
	output reg [2*BYTE_SIZE-1:0]	encode_ip_packet_length,
	
	//icmp encoder
	output reg [BYTE_SIZE-1:0]	    encode_icmp_code,
	output reg [BYTE_SIZE-1:0]	    encode_icmp_type,
	output reg [2*BYTE_SIZE-1:0]	encode_icmp_checksum,
	
	//udp encoder
	output wire [2*BYTE_SIZE-1:0]	encode_udp_src_port_0,
	output wire [2*BYTE_SIZE-1:0]	encode_udp_dst_port_0,

    output wire [2*BYTE_SIZE-1:0]	encode_udp_src_port_1,
	output wire [2*BYTE_SIZE-1:0]	encode_udp_dst_port_1,

`ifdef FOUR_TX_PORTS
	output wire [2*BYTE_SIZE-1:0]	encode_udp_src_port_2,
	output wire [2*BYTE_SIZE-1:0]	encode_udp_dst_port_2,

    output wire [2*BYTE_SIZE-1:0]	encode_udp_src_port_3,
	output wire [2*BYTE_SIZE-1:0]	encode_udp_dst_port_3,
`endif 

	output reg [2*BYTE_SIZE-1:0]	encode_udp_packet_length,

    input [2*BYTE_SIZE+IP_SIZE+MAC_SIZE-1:0]          arp_from_rx,
    input                           arp_from_rx_valid,

    input [2*BYTE_SIZE+IP_SIZE+MAC_SIZE-1:0]          icmp_from_rx,
    input                           icmp_from_rx_valid,

	input [2*BYTE_SIZE-1:0] icmp_checksum,
    output icmp_fifo_rdreq,
    input icmp_fifo_empty,
    input [10:0] icmp_fifo_rdusedw,

    output reg tx_busy = 1'b0,

    input rdempty_data_udp_fifo,
    output rdreq_data_udp_fifo,

`ifdef FOUR_TX_PORTS
    output reg [1:0] sel_tx_fifo = 2'b00,
`else
    output reg sel_tx_fifo = 1'b0,
`endif 

    input rdempty_status_udp_fifo_0,
    output reg rdreq_status_udp_fifo_0 = 1'b0,
    input [2*BYTE_SIZE+MAC_SIZE+IP_SIZE-1:0] status_from_udp_fifo_0,

    input rdempty_status_udp_fifo_1,
    output reg rdreq_status_udp_fifo_1 = 1'b0,
    input [2*BYTE_SIZE+MAC_SIZE+IP_SIZE-1:0] status_from_udp_fifo_1

`ifdef FOUR_TX_PORTS
    ,
    input rdempty_status_udp_fifo_2,
    output reg rdreq_status_udp_fifo_2 = 1'b0,
    input [2*BYTE_SIZE+MAC_SIZE+IP_SIZE-1:0] status_from_udp_fifo_2,

    input rdempty_status_udp_fifo_3,
    output reg rdreq_status_udp_fifo_3 = 1'b0,
    input [2*BYTE_SIZE+MAC_SIZE+IP_SIZE-1:0] status_from_udp_fifo_3

`endif 

);

wire [MAC_SIZE-1:0] dst_mac_from_fifo_0;
wire [IP_SIZE-1:0] dst_ip_from_fifo_0;
wire [2*BYTE_SIZE-1:0] pkt_length_from_fifo_0;

assign dst_mac_from_fifo_0 = status_from_udp_fifo_0[MAC_SIZE-1 -: MAC_SIZE];
assign dst_ip_from_fifo_0 = status_from_udp_fifo_0[MAC_SIZE+IP_SIZE-1 -: IP_SIZE];
assign pkt_length_from_fifo_0 = status_from_udp_fifo_0[2*BYTE_SIZE+MAC_SIZE+IP_SIZE-1 -: 2*BYTE_SIZE];


wire [MAC_SIZE-1:0] dst_mac_from_fifo_1;
wire [IP_SIZE-1:0] dst_ip_from_fifo_1;
wire [2*BYTE_SIZE-1:0] pkt_length_from_fifo_1;

assign dst_mac_from_fifo_1 = status_from_udp_fifo_1[MAC_SIZE-1 -: MAC_SIZE];
assign dst_ip_from_fifo_1 = status_from_udp_fifo_1[MAC_SIZE+IP_SIZE-1 -: IP_SIZE];
assign pkt_length_from_fifo_1 = status_from_udp_fifo_1[2*BYTE_SIZE+MAC_SIZE+IP_SIZE-1 -: 2*BYTE_SIZE];

`ifdef FOUR_TX_PORTS

wire [MAC_SIZE-1:0] dst_mac_from_fifo_2;
wire [IP_SIZE-1:0] dst_ip_from_fifo_2;
wire [2*BYTE_SIZE-1:0] pkt_length_from_fifo_2;

assign dst_mac_from_fifo_2 = status_from_udp_fifo_2[MAC_SIZE-1 -: MAC_SIZE];
assign dst_ip_from_fifo_2 = status_from_udp_fifo_2[MAC_SIZE+IP_SIZE-1 -: IP_SIZE];
assign pkt_length_from_fifo_2 = status_from_udp_fifo_2[2*BYTE_SIZE+MAC_SIZE+IP_SIZE-1 -: 2*BYTE_SIZE];


wire [MAC_SIZE-1:0] dst_mac_from_fifo_3;
wire [IP_SIZE-1:0] dst_ip_from_fifo_3;
wire [2*BYTE_SIZE-1:0] pkt_length_from_fifo_3;

assign dst_mac_from_fifo_3 = status_from_udp_fifo_3[MAC_SIZE-1 -: MAC_SIZE];
assign dst_ip_from_fifo_3 = status_from_udp_fifo_3[MAC_SIZE+IP_SIZE-1 -: IP_SIZE];
assign pkt_length_from_fifo_3 = status_from_udp_fifo_3[2*BYTE_SIZE+MAC_SIZE+IP_SIZE-1 -: 2*BYTE_SIZE];

`endif 


assign encode_frame_src_mac = local_mac;
assign encode_ip_src_ip = local_ip;

assign encode_arp_src_mac = local_mac;
assign encode_arp_src_ip = local_ip;

assign encode_udp_src_port_0 = local_stream_1_port;
assign encode_udp_dst_port_0 = local_stream_1_port;

assign encode_udp_src_port_1 = local_stream_2_port;
assign encode_udp_dst_port_1 = local_stream_2_port;

`ifdef FOUR_TX_PORTS
assign encode_udp_src_port_2 = local_stream_3_port;
assign encode_udp_dst_port_2 = local_stream_3_port;

assign encode_udp_src_port_3 = local_stream_4_port;
assign encode_udp_dst_port_3 = local_stream_4_port;
`endif 

reg int_icmp_fifo_rdreq = 1'b0;
assign icmp_fifo_rdreq = int_icmp_fifo_rdreq && st_tx_ready && (!icmp_fifo_empty);

reg int_rdreq_data_udp_fifo = 1'b0;
assign rdreq_data_udp_fifo = int_rdreq_data_udp_fifo && st_tx_ready && (!rdempty_data_udp_fifo);

reg int_encode_run = 1'b0;
assign encode_run = int_encode_run && st_tx_ready;

reg int_st_tx_dvalid = 1'b0;
assign st_tx_valid = int_st_tx_dvalid;


localparam	FRAME_HEADER_LENGTH = 16'd14, //length in 8-bit words
            ARP_HEADER_LENGTH = 16'd28,
            IP_PRI_HEADER_LENGTH = 16'd12,
            IP_SEC_HEADER_LENGTH = 16'd8,
            UDP_HEADER_LENGTH = 16'd8,
            ICMP_HEADER_LENGTH = 16'd4;

localparam	ARP_PACKET_TYPE = 16'h0806,
            IP_PACKET_TYPE = 16'h0800,
            ICMP_PROTOCOL_TYPE = 8'h01,
            UDP_PROTOCOL_TYPE = 8'h11;

localparam ICMP_FIFO_THR = 11'd5;

localparam  IDLE = 0,
            READ_RESPONSE_FIFO = 1,
            PRE_ENCODE_ARP_RESPONSE_1 = 2,
            PRE_ENCODE_ARP_RESPONSE_2 = 3,
            ENCODE_ARP_RESPONSE = 4,
            PRE_ENCODE_ICMP_RESPONSE_1 = 5,
            PRE_ENCODE_ICMP_RESPONSE_2 = 6,
            ENCODE_ICMP_RESPONSE = 7,
            PRE_ENCODE_ICMP_RESPONSE_1A = 8,
            PRE_ENCODE_ARP_RESPONSE_1A = 9,
            PRE_ENCODE_UDP_STREAM = 10,
            ENCODE_UDP_STREAM = 11,
            TIMING_DELAY_UDP = 12;

reg [4:0] STATE = IDLE;

reg [15:0] encode_counter;
reg [15:0] udp_length;
reg [2*BYTE_SIZE+IP_SIZE+MAC_SIZE-1:0] response_data;

reg tx_sync_rst_1, tx_sync_rst_2;

always @(posedge tx_xcvr_clk)
begin
    tx_sync_rst_1 <= tx_sync_rst;
    tx_sync_rst_2 <= tx_sync_rst_1;
end


always @ (posedge tx_xcvr_clk)
begin
    if(tx_sync_rst_2)
    begin
        reset_encoders <= 1'b1;
        int_encode_run <= 1'b0;
        st_tx_startofpacket <= 1'b0;
        st_tx_endofpacket <= 1'b0;
        int_st_tx_dvalid <= 1'b0;
        tx_busy <= 1'b0;
        rdreq_status_udp_fifo_0 <= 1'b0;
        rdreq_status_udp_fifo_1 <= 1'b0;
        `ifdef FOUR_TX_PORTS
        rdreq_status_udp_fifo_2 <= 1'b0;
        rdreq_status_udp_fifo_3 <= 1'b0;
        `endif
        int_rdreq_data_udp_fifo <= 1'b0;
        sel_tx_fifo <= 1'b0;
        STATE <= IDLE;
    end
    else
    begin
        case(STATE)

            IDLE:
            begin
                if(arp_from_rx_valid)   //new technique
                begin
                    response_data <= arp_from_rx;
                    encode_arp_n_ip <= 1'b1;
                    tx_busy <= 1'b1;
                    STATE <= PRE_ENCODE_ARP_RESPONSE_1;
                end
                else if (icmp_from_rx_valid)
                begin
                    response_data <= icmp_from_rx;
                    encode_arp_n_ip <= 1'b0;
                    encode_udp_n_icmp <= 1'b0;
                    tx_busy <= 1'b1;
                    STATE <= PRE_ENCODE_ICMP_RESPONSE_1;
                end
                else if(!rdempty_status_udp_fifo_0) // show ahead fifo
                begin
                    `ifdef FOUR_TX_PORTS
                    sel_tx_fifo <= 2'b00;
                    `else 
                    sel_tx_fifo <= 1'b0;
                    `endif 
                    encode_frame_dst_mac <= dst_mac_from_fifo_0;
                    encode_frame_packet_type <= IP_PACKET_TYPE;
                    // ip
                    encode_ip_dst_ip <= dst_ip_from_fifo_0;
                    encode_ip_protocol <= UDP_PROTOCOL_TYPE;
                    encode_ip_packet_length <= pkt_length_from_fifo_0 + IP_PRI_HEADER_LENGTH + IP_SEC_HEADER_LENGTH + UDP_HEADER_LENGTH;  //add ip and udp headers in bytes
                    //udp
                    encode_udp_packet_length <= pkt_length_from_fifo_0; //udp_encoder already sums 8
                    udp_length <= pkt_length_from_fifo_0;
                    // fifos
                    rdreq_status_udp_fifo_0 <= 1'b1;
                    encode_arp_n_ip <= 1'b0;
                    encode_udp_n_icmp <= 1'b1;
                    tx_busy <= 1'b1;
                    STATE <= TIMING_DELAY_UDP;
                end

                else if(!rdempty_status_udp_fifo_1) // show ahead fifo
                begin
                    `ifdef FOUR_TX_PORTS
                    sel_tx_fifo <= 2'b01;
                    `else 
                    sel_tx_fifo <= 1'b1;
                    `endif
                    encode_frame_dst_mac <= dst_mac_from_fifo_1;
                    encode_frame_packet_type <= IP_PACKET_TYPE;
                    // ip
                    encode_ip_dst_ip <= dst_ip_from_fifo_1;
                    encode_ip_protocol <= UDP_PROTOCOL_TYPE;
                    encode_ip_packet_length <= pkt_length_from_fifo_1 + IP_PRI_HEADER_LENGTH + IP_SEC_HEADER_LENGTH + UDP_HEADER_LENGTH;  //add ip and udp headers in bytes
                    //udp
                    encode_udp_packet_length <= pkt_length_from_fifo_1; //udp_encoder already sums 8
                    udp_length <= pkt_length_from_fifo_1;
                    // fifos
                    rdreq_status_udp_fifo_1 <= 1'b1;
                    encode_arp_n_ip <= 1'b0;
                    encode_udp_n_icmp <= 1'b1;
                    tx_busy <= 1'b1;
                    STATE <= TIMING_DELAY_UDP;
                end

`ifdef FOUR_TX_PORTS
                else if(!rdempty_status_udp_fifo_2) // show ahead fifo
                begin
                    sel_tx_fifo <= 2'b10;
                    encode_frame_dst_mac <= dst_mac_from_fifo_2;
                    encode_frame_packet_type <= IP_PACKET_TYPE;
                    // ip
                    encode_ip_dst_ip <= dst_ip_from_fifo_2;
                    encode_ip_protocol <= UDP_PROTOCOL_TYPE;
                    encode_ip_packet_length <= pkt_length_from_fifo_2 + IP_PRI_HEADER_LENGTH + IP_SEC_HEADER_LENGTH + UDP_HEADER_LENGTH;  //add ip and udp headers in bytes
                    //udp
                    encode_udp_packet_length <= pkt_length_from_fifo_2; //udp_encoder already sums 8
                    udp_length <= pkt_length_from_fifo_2;
                    // fifos
                    rdreq_status_udp_fifo_2 <= 1'b1;
                    encode_arp_n_ip <= 1'b0;
                    encode_udp_n_icmp <= 1'b1;
                    tx_busy <= 1'b1;
                    STATE <= TIMING_DELAY_UDP;
                end

                else if(!rdempty_status_udp_fifo_3) // show ahead fifo
                begin
                    sel_tx_fifo <= 2'b11;
                    encode_frame_dst_mac <= dst_mac_from_fifo_3;
                    encode_frame_packet_type <= IP_PACKET_TYPE;
                    // ip
                    encode_ip_dst_ip <= dst_ip_from_fifo_3;
                    encode_ip_protocol <= UDP_PROTOCOL_TYPE;
                    encode_ip_packet_length <= pkt_length_from_fifo_3 + IP_PRI_HEADER_LENGTH + IP_SEC_HEADER_LENGTH + UDP_HEADER_LENGTH;  //add ip and udp headers in bytes
                    //udp
                    encode_udp_packet_length <= pkt_length_from_fifo_3; //udp_encoder already sums 8
                    udp_length <= pkt_length_from_fifo_3;
                    // fifos
                    rdreq_status_udp_fifo_3 <= 1'b1;
                    encode_arp_n_ip <= 1'b0;
                    encode_udp_n_icmp <= 1'b1;
                    tx_busy <= 1'b1;
                    STATE <= TIMING_DELAY_UDP;
                end
`endif

                else
                begin
                    tx_busy <= 1'b0;
                end

                reset_encoders <= 1'b1;
            end

            TIMING_DELAY_UDP:
            begin
                rdreq_status_udp_fifo_0 <= 1'b0;
                rdreq_status_udp_fifo_1 <= 1'b0;
                `ifdef FOUR_TX_PORTS
                rdreq_status_udp_fifo_2 <= 1'b0;
                rdreq_status_udp_fifo_3 <= 1'b0;
                `endif

                int_rdreq_data_udp_fifo <= 1'b1;
                STATE <= PRE_ENCODE_UDP_STREAM;
            end


            PRE_ENCODE_ARP_RESPONSE_1:  
            begin
                encode_frame_packet_type <= response_data[2*BYTE_SIZE+IP_SIZE+MAC_SIZE-1 -: 2*BYTE_SIZE];
                encode_frame_dst_mac <= response_data[2*BYTE_SIZE+IP_SIZE+MAC_SIZE-2*BYTE_SIZE-1 -: MAC_SIZE];
                // arp
                encode_arp_dst_mac <= response_data[2*BYTE_SIZE+IP_SIZE+MAC_SIZE-2*BYTE_SIZE-1 -: MAC_SIZE];
                encode_arp_dst_ip <= response_data[2*BYTE_SIZE+IP_SIZE+MAC_SIZE-2*BYTE_SIZE-MAC_SIZE-1 -: IP_SIZE];
                STATE <= PRE_ENCODE_ARP_RESPONSE_1A;
            end

            PRE_ENCODE_ARP_RESPONSE_1A:
            begin
                STATE <= PRE_ENCODE_ARP_RESPONSE_2;
            end

            PRE_ENCODE_ARP_RESPONSE_2:
            begin
                int_st_tx_dvalid <= 1'b1;
                st_tx_startofpacket <= 1'b1;
                int_encode_run <= 1'b1;
                reset_encoders <= 1'b0;
                encode_counter <= FRAME_HEADER_LENGTH + ARP_HEADER_LENGTH - 1'b1; //in 32-bit words
                STATE <= ENCODE_ARP_RESPONSE;
            end

            ENCODE_ARP_RESPONSE:
            begin
                if(st_tx_ready)
                begin
                    st_tx_startofpacket <= 1'b0;
                    encode_counter <= encode_counter - 1'b1;
                    if ( encode_counter == 0 )
						begin
						  // finished encoding, submit
							st_tx_endofpacket <= 1'b0;
							int_st_tx_dvalid <= 1'b0;
							int_encode_run <= 1'b0;
							reset_encoders <= 1'b1;
                            STATE <= IDLE;
						end
						else if (encode_counter == 1)
						begin
							encode_counter <= encode_counter - 1'b1;
							st_tx_endofpacket <= 1'b1;
                        end
                end
            end


            PRE_ENCODE_ICMP_RESPONSE_1:
            begin
                encode_frame_dst_mac <= response_data[2*BYTE_SIZE+IP_SIZE+MAC_SIZE-2*BYTE_SIZE-1 -: MAC_SIZE];
                encode_frame_packet_type <= IP_PACKET_TYPE;
                // ip
                encode_ip_dst_ip <= response_data[2*BYTE_SIZE+IP_SIZE+MAC_SIZE-2*BYTE_SIZE-MAC_SIZE-1 -: IP_SIZE];
                encode_ip_protocol <= ICMP_PROTOCOL_TYPE;
                encode_ip_packet_length <= response_data[2*BYTE_SIZE+IP_SIZE+MAC_SIZE-1 -: 2*BYTE_SIZE] + IP_PRI_HEADER_LENGTH + IP_SEC_HEADER_LENGTH + ICMP_HEADER_LENGTH - 16'd2;  //add ip and icmp headers but subtract 2
                // icmp
                encode_icmp_type <= 8'h00;  //echo reply
                encode_icmp_code <= 8'h00;  //echo reply
                encode_icmp_checksum <= icmp_checksum + 16'h0800;
                STATE <= PRE_ENCODE_ICMP_RESPONSE_1A;

            end

            PRE_ENCODE_ICMP_RESPONSE_1A:
            begin
                if(icmp_fifo_rdusedw > ICMP_FIFO_THR)
                begin
                    int_icmp_fifo_rdreq <= 1'b1;
                    STATE <= PRE_ENCODE_ICMP_RESPONSE_2;
                end
            end

            PRE_ENCODE_ICMP_RESPONSE_2:
            begin
                if(!icmp_fifo_empty)
                begin
                    reset_encoders <= 1'b0;
                    int_icmp_fifo_rdreq <= 1'b1;
                    int_st_tx_dvalid <= 1'b1;
					st_tx_startofpacket <= 1'b1;
                    int_encode_run <= 1'b1;
                    encode_counter <= FRAME_HEADER_LENGTH + (encode_ip_packet_length) - 1'b1;
                    STATE <= ENCODE_ICMP_RESPONSE;
                end
                else
                    int_icmp_fifo_rdreq <= 1'b0;
            end

            ENCODE_ICMP_RESPONSE:
            begin
                if(st_tx_ready)
                begin
                    st_tx_startofpacket <= 1'b0;
                    encode_counter <= encode_counter - 1'b1;
                    if ( encode_counter == 0 )
                    begin
                    // finished encoding, submit
                        st_tx_endofpacket <= 1'b0;
                        int_st_tx_dvalid <= 1'b0;
                        int_encode_run <= 1'b0;
                        reset_encoders <= 1'b1;
                        int_icmp_fifo_rdreq <= 1'b0;
                        STATE <= IDLE;
                    end
                    else if (encode_counter == 1)
                    begin
                        encode_counter <= encode_counter - 1'b1;
                        st_tx_endofpacket <= 1'b1;
                    end
                end
            end

            PRE_ENCODE_UDP_STREAM:
            begin
                reset_encoders <= 1'b0;
                int_st_tx_dvalid <= 1'b1;
                st_tx_startofpacket <= 1'b1;
                int_encode_run <= 1'b1;
                
                encode_counter <= FRAME_HEADER_LENGTH +  IP_PRI_HEADER_LENGTH + IP_SEC_HEADER_LENGTH + UDP_HEADER_LENGTH + encode_udp_packet_length - 1'b1;

                //check this code below

                if(udp_length == 0) //check to avoid unwanted fifo readings that belongs to the next packet
                    int_rdreq_data_udp_fifo <= 1'b0;
                else
                begin
                    int_rdreq_data_udp_fifo <= 1'b1;
                    udp_length <= udp_length - 1'b1;
                end


                STATE <= ENCODE_UDP_STREAM;

            end


            ENCODE_UDP_STREAM:
            begin
                if(st_tx_ready)
                begin
                    st_tx_startofpacket <= 1'b0;
                    encode_counter <= encode_counter - 1'b1;
                    if ( encode_counter == 0 )
						begin
						  // finished encoding, submit
							st_tx_endofpacket <= 1'b0;
							int_st_tx_dvalid <= 1'b0;
							int_encode_run <= 1'b0;
							reset_encoders <= 1'b1;
                            STATE <= IDLE;
						end
						else if (encode_counter == 1)
						begin
							encode_counter <= encode_counter - 1'b1;
							st_tx_endofpacket <= 1'b1;

                        end

                        if(udp_length == 0) //check to avoid unwanted fifo readings that belongs to the next packet
                            int_rdreq_data_udp_fifo <= 1'b0;
                        else
                        begin
                            int_rdreq_data_udp_fifo <= 1'b1;
                            udp_length <= udp_length - 1'b1;
                        end
                        
                end
            end


            default:
            begin
                reset_encoders <= 1'b1;
                int_encode_run <= 1'b0;
                `ifdef FOUR_TX_PORTS
                sel_tx_fifo <= 2'b00;
                `else
                sel_tx_fifo <= 1'b0;
                `endif
                STATE <= IDLE;
            end


        endcase
    end

end


endmodule
