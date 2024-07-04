module dec_comm8_port3 #(parameter AVL_SIZE = 8,
                    BYTE_SIZE = 8,
                    IP_SIZE = 32,
                    TX_WORDS = 8,
                    MAC_SIZE = 48,
                    BYTES_IN_FIFO = 8) //Bytes composing the FIFO
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
    
    // FIFO interface
    output reg      temp_voltage_clr_fifo,
    output reg      temp_voltage_rdreq_fifo,
    input           temp_voltage_rdempty_fifo,
    input [63:0]    temp_voltage_rddata_fifo
);

// TX STATE MACHINE

localparam  IDLE = 0,
            SEND = 1;

reg [2:0] TX_STATE = IDLE;
reg [$clog2(BYTES_IN_FIFO):0] byte_counter = BYTES_IN_FIFO;

always @(posedge clk ) begin
    if(reset) begin
		tx_fifo_data_write <= 1'b0;
        temp_voltage_rdreq_fifo <= 1'b0;
        temp_voltage_clr_fifo <= 1'b1;
		TX_STATE <= IDLE;
	end
    else begin
        case (TX_STATE)

            IDLE: begin
                temp_voltage_rdreq_fifo <= 1'b0; 
                temp_voltage_clr_fifo <= 1'b0;
                tx_fifo_data_write <= 1'b0;
                tx_fifo_status_write <= 1'b0; 
                if (~temp_voltage_rdempty_fifo) begin   
                    byte_counter <= BYTES_IN_FIFO; 
                    TX_STATE <= SEND;  
                end
            end

            SEND: begin
                temp_voltage_rdreq_fifo <= 1'b0;
                tx_fifo_data_write <= 1'b1;
                tx_fifo_data <= temp_voltage_rddata_fifo[byte_counter*8-1 -: 8];
                if (byte_counter == 2) begin                 
                    temp_voltage_rdreq_fifo <= 1'b1;                    
                end
                else begin
                    temp_voltage_rdreq_fifo <= 1'b0;   
                end
                if (byte_counter == 1) begin
                    tx_fifo_status <= {BYTES_IN_FIFO[15:0], destination_ip, destination_mac};
                    tx_fifo_status_write <= 1'b1;
                    TX_STATE <= IDLE;
                end
                else begin 
                    byte_counter =  byte_counter - 1'b1;                   
                end
            end
            
            default: begin
                tx_fifo_data_write <= 1'b0;
                tx_fifo_status_write <= 1'b0;
                temp_voltage_rdreq_fifo <= 1'b0;
                TX_STATE <= IDLE;
            end

        endcase
    end
end

endmodule
