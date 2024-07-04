module dec_comm8_port2 #(parameter AVL_SIZE = 8,
                    BYTE_SIZE = 8,
                    IP_SIZE = 32,
                    MAC_SIZE = 48,
                    SAMPLE_BYTES = 2, //bytes for a single sample
                    DAC_CHANNELS = 1,
                    UDP_BYTE_PER_PACKET = 3957 //((UDP_BYTE_PER_PACKET-5) % 8 = 0) (BYTE_PER_PACKET + 42 must be less than the max jumbo frame length: 4000 by default)
                    )
(
    input	        clk,
    input           reset,

    input [MAC_SIZE-1:0] source_mac,
    input [IP_SIZE-1:0] source_ip,

    // rx fifo interface from 1gb eth
    input [AVL_SIZE-1:0]	                    rx_fifo_data,
    output reg		                            rx_fifo_data_read,
    input                                       rx_fifo_data_empty,
    input [2*BYTE_SIZE+IP_SIZE+MAC_SIZE-1:0]	rx_fifo_status,
    input		                                rx_fifo_status_empty,
    output reg		                            rx_fifo_status_read,
    
    // tx fifo interface to 1gb eth
    output reg [AVL_SIZE-1:0] tx_fifo_data,
    output reg [2*BYTE_SIZE+IP_SIZE+MAC_SIZE-1:0] tx_fifo_status,
    output reg tx_fifo_data_write,
    output reg tx_fifo_status_write,
    input      tx_fifo_data_full,
    input      tx_fifo_status_full,

    // mac and ip for the destination, received for the command decoder
    input [MAC_SIZE-1:0] destination_mac,
    input [IP_SIZE-1:0] destination_ip,

    //acquisition mode
    input  mode_nCont_disc,
    input  mode_nRaw_dem,

    // ACQUISITION FIFO
	output reg      acq_rdreq_fifo_108,
	input [107:0]   acq_rddata_fifo_108,
	input           acq_rdempty_fifo_108  
);

// COMMAND LIST
// GENERAL COMMANDS:
//localparam  ; 



// // DECODER RX STATE MACHINE
// localparam  RX_IDLE = 0,
//             RX_READ_DATA = 1,
//             RX_READ_DATA_1 = 2,
//             RX_FLUSH = 3,
//             RX_UNPACK_CMD = 4,
//             RX_WAIT = 5,
//             RX_EVAL = 6;

// reg [2:0] RX_STATUS = RX_IDLE;

// localparam  COMMAND_ONLY = 4,    //length of command: 32 bit - 4 bytes
//             COMMAND_DATA = 8;    //length of command plus data: 32+32 - 8 bytes

// reg [COMMAND_DATA*AVL_SIZE-1:0] rx_buffer; //received data buffer
// reg [2*BYTE_SIZE-1:0] byte_counter; //received byte counter
// reg [COMMAND_ONLY*BYTE_SIZE-1:0] received_cmd; //command part of the incoming data
// reg [COMMAND_ONLY*BYTE_SIZE-1:0] received_data; //command part of the incoming data

// reg with_data; //if the received command is with data or not
// reg nak, ack, ver, err; //signals for the TX state machine

// always @(posedge clk)
// begin
// 	if(reset)
// 	begin
//         rx_fifo_data_read <= 1'b0;
//         rx_fifo_status_read <= 1'b0;

//         byte_counter <= 8'd0;

//         with_data <= 1'b0;
//         nak <= 1'b0;
//         ack <= 1'b0;
//         ver <= 1'b0;
//         err <= 1'b0;

//         RX_STATUS <= RX_IDLE;
//     end
//     else
//     begin
//         case(RX_STATUS)

//             RX_IDLE:
//             begin
//                 nak <= 1'b0;
//                 ack <= 1'b0;
//                 ver <= 1'b0;
//                 err <= 1'b0;
//                 if(!rx_fifo_status_empty) begin
//                     rx_fifo_status_read <= 1'b1;
//                     byte_counter <= rx_fifo_status[2*BYTE_SIZE+IP_SIZE+MAC_SIZE-1 -: 2*BYTE_SIZE];
//                     RX_STATUS <= RX_READ_DATA;
//                 end
//             end

//             RX_READ_DATA: //check if the command is with or without data while reading
//             begin
//                 rx_fifo_status_read <= 1'b0;
//                 rx_fifo_data_read <= 1'b1;
//                 byte_counter <= byte_counter - 1'b1;

//                 if(byte_counter == COMMAND_ONLY) begin
//                     with_data <= 1'b0;
//                     RX_STATUS <= RX_READ_DATA_1;
//                 end
//                 else if (byte_counter == COMMAND_DATA) begin
//                     with_data <= 1'b1;
//                     RX_STATUS <= RX_READ_DATA_1;
//                 end
//                 else begin
//                     RX_STATUS <= RX_FLUSH;
//                 end
//             end

//             RX_READ_DATA_1: //read the data from the RX FIFO
//             begin
//                 if(byte_counter == 0) begin
//                     rx_fifo_data_read <= 1'b0;
//                     RX_STATUS <= RX_UNPACK_CMD;
//                 end
                                
//                 //shifting the register
//                 rx_buffer[COMMAND_DATA*AVL_SIZE-1:AVL_SIZE] <= rx_buffer[COMMAND_DATA*AVL_SIZE-AVL_SIZE-1:0];
//                 rx_buffer[AVL_SIZE-1:0] <= rx_fifo_data;
                
//                 byte_counter <= byte_counter - 1'b1;
//             end

//             RX_UNPACK_CMD: begin //unpack the received command and data
//                 rx_fifo_data_read <= 1'b0;
//                 if (with_data) received_cmd <= rx_buffer[COMMAND_DATA*AVL_SIZE-1 -: COMMAND_ONLY*AVL_SIZE];
//                 else received_cmd <= rx_buffer[COMMAND_ONLY*AVL_SIZE-1 : 0];
//                 received_data <= rx_buffer[COMMAND_ONLY*AVL_SIZE-1 : 0];
//                 RX_STATUS <= RX_WAIT;
//             end

//             RX_WAIT: begin //delay state to add a multicycle constraint to improve timing
//                 RX_STATUS <= RX_EVAL;
//             end

//             RX_EVAL: begin //evaluate the command
//                 RX_STATUS <= RX_IDLE;                
//                 case (received_cmd) 
//                     default: 
//                     begin
//                         nak <= 1'b1;
//                         ack <= 1'b0;
//                         ver <= 1'b0;
//                         err <= 1'b0;
//                     end
//                 endcase
//             end

//             RX_FLUSH: //RX_flush the fifo if the received command has an unusual length
//             begin
//                 if(byte_counter == 8'd0) begin
//                     rx_fifo_data_read <= 1'b0;
//                     nak <= 1'b1;
//                     RX_STATUS <= RX_IDLE;
//                 end
//                 byte_counter <= byte_counter - 1'd1;
//             end

//             default:
//             begin
//                 rx_fifo_data_read <= 1'b0;
//                 rx_fifo_status_read <= 1'b0;

//                 byte_counter <= 8'd0;

//                 nak <= 1'b0;
//                 ack <= 1'b0;
//                 ver <= 1'b0;
//                 RX_STATUS <= RX_IDLE;
//             end

//         endcase
//     end
// end

wire signed [31:0] current_freq = $signed(acq_rddata_fifo_108[95-:32]);
wire signed [31:0] current_sin = $signed(acq_rddata_fifo_108[63-:32]);
wire signed [31:0] current_cos = $signed(acq_rddata_fifo_108[31-:32]);
wire frequency_change_udp = acq_rddata_fifo_108[96];

// //// DECODER TX STATE MACHINE
localparam  TX_IDLE = 0,
            TX_HEADER_MODES = 1,
            TX_HEADER_FREQ = 2,
            TX_DATA_RAW_1 = 3,
            TX_DATA_RAW_2 = 4,
            TX_DATA_RAW_3 = 5,
            TX_DATA_RAW_4 = 6,
            TX_DATA_DEM_1 = 7,
            TX_DATA_DEM_2 = 8,
            TX_SEND_PACKET = 9;

reg [3:0] TX_STATE;

reg [15:0] byte_per_packet_counter = 16'd0; //counter of the number of bytes written in the packet 
reg [4:0] freq_counter, data_counter;

always @(posedge clk ) begin
    if(reset) begin
		tx_fifo_data_write <= 1'b0;
        tx_fifo_status_write <= 1'b0;
		byte_per_packet_counter <= 16'd0;
        acq_rdreq_fifo_108 <= 1'b0;
		TX_STATE <= TX_IDLE;
	end
    else begin
        case (TX_STATE)

            TX_IDLE: begin //Wait for the FIFO to be written
                tx_fifo_data_write <= 1'b0;
                tx_fifo_status_write <= 1'b0;
                if(~acq_rdempty_fifo_108) begin //if there is something in the data fifo start the FSM
                    TX_STATE <= TX_HEADER_MODES;
                end
            end

            TX_HEADER_MODES: begin //write the MSBs of the row number for the header
                tx_fifo_data <= {{4{mode_nCont_disc}},{4{mode_nRaw_dem}}};
                tx_fifo_data_write <= 1'b1;
                tx_fifo_status_write <= 1'b0;
                byte_per_packet_counter <= byte_per_packet_counter + 1'b1;
                TX_STATE <= TX_HEADER_FREQ;                
                freq_counter <= 4'd4;
                data_counter <= 4'd8;  
            end

            TX_HEADER_FREQ: begin //write the LSBs of the row number for the header
                tx_fifo_data <= current_freq[(freq_counter*8-1)-:8];
                tx_fifo_data_write <= 1'b1;
                byte_per_packet_counter <= byte_per_packet_counter + 1'b1;
                if (freq_counter > 1) begin
                    freq_counter <= freq_counter - 1'b1;
                    TX_STATE <= TX_HEADER_FREQ;
                end
                else begin
                    if (mode_nRaw_dem) TX_STATE <= TX_DATA_DEM_1;
                    else TX_STATE <= TX_DATA_RAW_1;
                end                
            end  

            TX_DATA_RAW_1: begin
                tx_fifo_data_write <= 1'b0;
                if (~acq_rdempty_fifo_108) begin //if there is data in the FIFO read the MSBs (THE FIFO IS A LOOK AHEAD) and increment the byte per packet counter
                    if (frequency_change_udp && (byte_per_packet_counter != 5)) begin
                        TX_STATE <= TX_SEND_PACKET;
                    end
                    else begin
                        tx_fifo_data_write <= 1'b1;
                        byte_per_packet_counter <= byte_per_packet_counter + 1'b1;
                        tx_fifo_data <= current_cos[15:8];
                        TX_STATE <= TX_DATA_RAW_2;  
                    end                        
                end
                else if (timeout) begin
                    TX_STATE <= TX_SEND_PACKET;
                end
            end
            TX_DATA_RAW_2: begin
                tx_fifo_status_write <= 1'b0;
                tx_fifo_data_write <= 1'b1;
                acq_rdreq_fifo_108 <= 1'b0;
				tx_fifo_data <= current_cos[7:0];
                byte_per_packet_counter <= byte_per_packet_counter + 1'b1;
                TX_STATE <= TX_DATA_RAW_3;
            end
            TX_DATA_RAW_3: begin
                tx_fifo_status_write <= 1'b0;
                tx_fifo_data_write <= 1'b1;
                acq_rdreq_fifo_108 <= 1'b0;
				tx_fifo_data <= current_sin[15:8];
                byte_per_packet_counter <= byte_per_packet_counter + 1'b1;
                acq_rdreq_fifo_108 <= 1'b1; //being the FIFO look ahead the data will still be available the next clock cycle bringing rdreq high now
                TX_STATE <= TX_DATA_RAW_4;
            end
            TX_DATA_RAW_4: begin //read the LSBs of the fifo data and handles various cases:
                tx_fifo_status_write <= 1'b0;
                tx_fifo_data_write <= 1'b1;
                acq_rdreq_fifo_108 <= 1'b0;
				tx_fifo_data <= current_sin[7:0];
                byte_per_packet_counter <= byte_per_packet_counter + 1'b1;
                if (byte_per_packet_counter == UDP_BYTE_PER_PACKET - 1'b1) begin //-1 because byte_per_packet_counter is incresed during the same clock cycle
                    TX_STATE <= TX_SEND_PACKET;
                end
                else begin //else keep incrementin the number of bytes written in the packet and the number of samples in the row
                    TX_STATE <= TX_DATA_RAW_1;
                end
            end

            TX_DATA_DEM_1: begin //write the LSBs of the row number for the header
                tx_fifo_data_write <= 1'b0;                
                if (~acq_rdempty_fifo_108) begin
                    if (frequency_change_udp && (byte_per_packet_counter != 5)) begin
                        TX_STATE <= TX_SEND_PACKET;
                    end
                    else begin
                        TX_STATE <= TX_DATA_DEM_2;
                        data_counter <= 4'd8;   
                    end                             
                end
                else if (timeout) begin 
                    TX_STATE <= TX_SEND_PACKET;
                end
            end
            TX_DATA_DEM_2: begin //write the LSBs of the row number for the header
                tx_fifo_data <= acq_rddata_fifo_108[(data_counter*8-1)-:8];
                tx_fifo_data_write <= 1'b1;
                byte_per_packet_counter <= byte_per_packet_counter + 1'b1;
                if (data_counter == 2) begin
                    acq_rdreq_fifo_108 <= 1'b1; //being the FIFO look ahead the data will still be available the next clock cycle bringing rdreq high now
                end
                else begin
                    acq_rdreq_fifo_108 <= 1'b0;
                end 
                if (data_counter == 1) begin  
                    if (byte_per_packet_counter == UDP_BYTE_PER_PACKET - 1'b1) begin //-1 because byte_per_packet_counter is incresed during the same clock cycle
                        TX_STATE <= TX_SEND_PACKET; 
                    end   
                    else begin
                        TX_STATE <= TX_DATA_DEM_1;
                    end 
                end
                else begin
                    data_counter <= data_counter - 1'b1;
                end     
            end
            

            TX_SEND_PACKET: begin
                tx_fifo_status <= {byte_per_packet_counter, destination_ip, destination_mac};
                tx_fifo_data_write <= 1'b0;
                tx_fifo_status_write <= 1'b1;
                byte_per_packet_counter <= 16'd0;
                TX_STATE <= TX_IDLE; 
            end
            
            default: begin
                tx_fifo_data_write <= 1'b0;
                tx_fifo_status_write <= 1'b0;
                acq_rdreq_fifo_108 <= 1'b0;
                byte_per_packet_counter <= 16'd0;
                TX_STATE <= TX_IDLE;
            end

        endcase
    end
end

//If the main TX_FSM is in a waiting state for more then 40 clock cycles send the pending packet
reg timeout;
reg [7:0] timeout_counter; //counter to use the send the last UDP packet which is not complete

always @(posedge clk) begin
    if (acq_rdempty_fifo_108 && (TX_STATE == TX_DATA_RAW_1 || TX_STATE == TX_DATA_DEM_1)) begin
        timeout_counter <= timeout_counter + 1'b1;
        if (timeout_counter > 200) begin //at worst a packet is received every 64 clock cycles @ 50 MHz -> 160 clock cycles @ 125 MHz. 40 more for safety
            timeout <= 1'b1;
        end
    end
    else begin
        timeout_counter <= 0;
        timeout <= 1'b0;
    end
end

endmodule