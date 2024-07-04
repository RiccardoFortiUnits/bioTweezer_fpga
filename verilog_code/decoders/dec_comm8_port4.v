module dec_comm8_port4 #(parameter AVL_SIZE = 8,
                    BYTE_SIZE = 8,
                    IP_SIZE = 32,
                    MAC_SIZE = 48,
                    FIFO_LENGTH = 64)
(
    input	        clk,
    input           reset,
    
    // tx fifo interface to 1gb eth (for ack)
    output reg [AVL_SIZE-1:0] tx_fifo_data,
    output reg [2*BYTE_SIZE+IP_SIZE+MAC_SIZE-1:0] tx_fifo_status,
    output reg tx_fifo_data_write,
    output reg tx_fifo_status_write,
    input      tx_fifo_data_full,
    input      tx_fifo_status_full,

    input [MAC_SIZE-1:0] destination_mac,
    input [IP_SIZE-1:0] destination_ip,
    
    // atom acquisition mode
    input atommode_circle_nlegacy,
    input atommode_position_nerror,

    // ERROR/OFFSET FIFOs
    output                      lockin_rdreq_x_fifo,
    input   [FIFO_LENGTH-1:0]   lockin_rddata_x_fifo,
    input                       lockin_rdempty_x_fifo,
    output                      lockin_rdreq_y_fifo,
    input   [FIFO_LENGTH-1:0]   lockin_rddata_y_fifo,
    input                       lockin_rdempty_y_fifo,
	
    // CURRENT FIFO	
	output              current_rdreq_fifo,
	input [FIFO_LENGTH-1:0] current_rddata_fifo,
	input               current_rdempty_fifo,

	// Z value FIFO	
	output              Z_rdreq_fifo,
	input [FIFO_LENGTH-1:0] Z_rddata_fifo,
	input               Z_rdempty_fifo
);

//all the fifos are read at the same time
assign lockin_rdreq_x_fifo = rdreq_all_fifos;
assign lockin_rdreq_y_fifo = rdreq_all_fifos;
assign current_rdreq_fifo = rdreq_all_fifos;
assign Z_rdreq_fifo = rdreq_all_fifos;

// // TX STATE MACHINE

localparam  IDLE = 0,
            HEADER = 1,
            DATA_FROM_FIFO = 2,
            WAIT = 3;

localparam  ERROR_HEADER = 8'h00;
localparam  BYTE_IN_FIFO = FIFO_LENGTH/BYTE_SIZE;

reg [2:0] STATE;
reg [$clog2(BYTE_IN_FIFO)-1:0] byte_counter;
reg rdreq_all_fifos;

always @(posedge clk ) begin
    if(reset) begin
        fifo_sel_counter <= 2'b00;
        rdreq_all_fifos <= 1'b0;
		tx_fifo_data_write <= 1'b0;
        tx_fifo_status_write <= 1'b0;
        byte_counter <= 0;
		STATE <= IDLE;
	end
    else begin
        case (STATE)

            IDLE: begin
                fifo_sel_counter <= 2'b00;   
                rdreq_all_fifos <= 1'b0;             
                tx_fifo_data_write <= 1'b0;
                tx_fifo_status_write <= 1'b0;
                byte_counter <= 0;
                if(~lockin_rdempty_x_fifo) begin  //Start when the x error lockin fifo is not empty (all the fifo are written at the same time)
                    STATE <= HEADER;                            
                end
            end

            HEADER: begin //Write the header
                tx_fifo_data <= {{4{atommode_circle_nlegacy}},{4{atommode_position_nerror}}};
                tx_fifo_data_write <= 1'b1;
                STATE <= DATA_FROM_FIFO;
            end

            DATA_FROM_FIFO: begin //Write the data to the UDP fifo
                tx_fifo_data_write <= 1'b1;
                tx_fifo_data <= data_from_fifo_slice;
                if (byte_counter < BYTE_IN_FIFO-1) begin
                    byte_counter <= byte_counter + 1'b1;
                end               
                else begin //When the 4 byte of the fifo have been read change the selected fifo or, if it was the last fifo, write the status fifo
                    if (fifo_sel_counter == 2'b11) begin 
                        rdreq_all_fifos <= 1'b1;                      
                        tx_fifo_status <= {4*BYTE_IN_FIFO+1'b1, destination_ip, destination_mac};
                        tx_fifo_status_write <= 1'b1;
                        STATE <= WAIT;
                    end
                    else begin
                        fifo_sel_counter <= fifo_sel_counter + 1'b1;
                        byte_counter <= 0;
                    end
                end
            end            

            WAIT: begin //Wait state needed to get lockin_rdempty_x_fifo back to one after tx_fifo_status_write <= 1'b1;
                rdreq_all_fifos <= 1'b0;
                tx_fifo_data_write <= 1'b0;
                tx_fifo_status_write <= 1'b0;
                STATE <= IDLE;
            end
            
            default: begin
                fifo_sel_counter <= 2'b00;
                rdreq_all_fifos <= 1'b0;
                tx_fifo_data_write <= 1'b0;
                tx_fifo_status_write <= 1'b0;
                byte_counter <= 0;
                STATE <= IDLE;
            end

        endcase
    end
end


//Multiplexer to select the FIFO to read
reg [1:0] fifo_sel_counter; //register to select the fifo to read
reg [FIFO_LENGTH-1:0] fifo_sel_data;
always @* begin
    if (fifo_sel_counter == 2'b00) begin
        fifo_sel_data <= lockin_rddata_x_fifo;
    end
    else if (fifo_sel_counter == 2'b01) begin
        fifo_sel_data <= lockin_rddata_y_fifo;
    end
    else if (fifo_sel_counter == 2'b10) begin
        fifo_sel_data <= current_rddata_fifo;
    end
    else begin
        fifo_sel_data <= Z_rddata_fifo;
    end
end
//Logic to get the correct byte from the FIFO
wire [7:0] data_from_fifo_slice = fifo_sel_data[FIFO_LENGTH-1-8*byte_counter -: 8];

endmodule
