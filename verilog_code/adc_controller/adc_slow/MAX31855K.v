module MAX31855K (
    input           clk_50,
    input           reset,
    //Commands
    input           start_acq,
    output reg      data_valid,
    //Waveform data
    output reg [31:0] raw_data,    
    output reg [13:0] temperature_data,
    output reg [11:0] temperature_internal_data,
    output reg      SCV_fault,
    output reg      SCG_fault,
    output reg      OC_fault,
    //MAX31855
    output          MAX_SCLK,
    output reg      MAX_CSn,
    input           MAX_SDO,
    //controller status:
    output          busy
);

assign busy = (STATE != IDLE);
assign MAX_SCLK = clk_5;

localparam  IDLE = 0,
            READ = 1,
            STOP = 2,
            WAIT_CS1 = 3;

reg [3:0] STATE = IDLE;
reg [4:0] byte_counter = 5'd0;

always @(posedge clk_50) begin
    if (reset) begin
        byte_counter <= 5'd0;  
        sclk_and_counter_enable <= 1'b0;
        MAX_CSn <= 1'b1;
        data_valid <= 1'b0;
        STATE <= IDLE;
    end
    else begin
        case (STATE)
            IDLE: begin    
                sclk_and_counter_enable <= 1'b0;
                MAX_CSn <= 1'b1;
                byte_counter <= 5'd0;  
                if (start_acq) begin
                    data_valid <= 1'b0;
                    MAX_CSn <= 1'b0;
                    sclk_and_counter_enable <= 1'b1;
                    STATE <= READ;
                end
            end

            READ: begin
				if(bit_counter == (bit_length - 1)) begin
                    raw_data[31:1] <= raw_data[30:0];
                    raw_data[0] <= MAX_SDO;
                    if (byte_counter == 5'd31) begin
                        byte_counter <= 5'd0;
                        STATE <= STOP;
                    end
                    else byte_counter <= byte_counter + 1'b1;
				end                   
            end

            STOP: begin
                if(bit_counter == (bit_length - 1)) begin
				    sclk_and_counter_enable <= 1'b0;
                    MAX_CSn <= 1'b1;
                    temperature_data <= raw_data[31:18];
                    temperature_internal_data <= raw_data[15:4];
                    SCV_fault <= raw_data[2];
                    SCG_fault <= raw_data[1];
                    OC_fault <= raw_data[0];
                    STATE <= WAIT_CS1;
			    end
            end
            WAIT_CS1: begin
                STATE <= IDLE;                
                data_valid <= 1'b1;
            end

            default: begin
                sclk_and_counter_enable <= 1'b0;
                MAX_CSn <= 1'b1;
                STATE <= IDLE;
            end
        endcase
    end
end

reg clk_5 = 1'b0;
reg [4:0] bit_counter = 5'd0;	//conta fino a 10 (genera l'SCLK)
reg sclk_and_counter_enable = 1'b0;

localparam	bit_length = 10,
 			half_bit = 5;

//contatori
always @(posedge clk_50)
begin
	if(reset) begin
		bit_counter <= 5'd0;
	end
	else begin
		if(sclk_and_counter_enable) begin
			if(bit_counter == (bit_length - 1)) begin
				bit_counter <= 5'd0;
			end
			else begin
				bit_counter <= bit_counter + 5'd1;
			end
		end
		else begin
			bit_counter <= 5'd0;
		end
	end
end

//sclk
always @(posedge clk_50)
begin
    if(reset) begin
        clk_5 <= 1'b0;
	end
    else begin
        if(sclk_and_counter_enable) begin
            if(bit_counter == (half_bit - 1) | bit_counter == (bit_length - 1)) begin
                clk_5 <= !clk_5;
            end
        end
        else begin
            clk_5 <= 1'b0;
        end
    end
end
    
endmodule