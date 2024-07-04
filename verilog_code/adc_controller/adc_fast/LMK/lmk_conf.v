`include "i2c_top_level.v"
`include "lmk_lut.v"

module lmk_conf (

	input clk,
	input reset,

	input start,
	output reg done,

	inout i2c_sda, 	//connect directly to the pins
	inout i2c_scl   //connect directly to the pins


);

reg lmk_write = 1'b0;

wire ready_n;

wire sda_padoen_oe;
wire scl_padoen_oe;
wire sda_pad_i = i2c_sda;
wire scl_pad_i = i2c_scl;
wire sda_pad_o;
wire scl_pad_o;

assign i2c_sda = (sda_padoen_oe) ? 1'bz : sda_pad_o;
assign i2c_scl = (scl_padoen_oe) ? 1'bz : scl_pad_o;



wire [6:0]  device_address;
assign device_address = 7'b1011000;

i2c_top_level i2c_top_level_0 (

	.clk(clk),
	.reset(reset),

	.start_write(lmk_write),
	.start_read(),
	.address(device_address),		
	
	.data({address,data}),
	.ready_n(ready_n),

	// I2C signals
	// i2c clock line
	.scl_pad_i(scl_pad_i),       // SCL-line input
	.scl_pad_o(scl_pad_o),       // SCL-line output 
	.scl_padoen_o(scl_padoen_oe),    // SCL-line output enable (active low)
	// i2c data line
	.sda_pad_i(sda_pad_i),       // SDA-line input
	.sda_pad_o(sda_pad_o),       // SDA-line output 
	.sda_padoen_o(sda_padoen_oe)    // SDA-line output enable (active low)

); 

wire [7:0] address;
wire [7:0] data;

lmk_lut lmk_lut (
				.index(index),
				.address(address),
				.data(data)
					
);


reg [2:0] state;
localparam 	IDLE = 3'd0,
			START = 3'd1,
			WAIT_1 = 3'd2,
			WAIT = 3'd4,
			WAIT_2 = 3'd5,
			INC = 3'd3,
			CONFIGURED = 3'd6;

reg [3:0] index;
localparam 		STOP_INDEX = 4'd2;


always @ (posedge clk)
begin
	if(reset)
	begin
		index <= 4'd0;
		lmk_write <= 1'b0;
		done <= 1'b0;
		state <= IDLE;
	end
	else
	begin
		case(state)
			
			IDLE:
			begin
				if(start)
				begin
					index <= 4'd1;
					state <= WAIT_2;
				end
			
			end
	
			WAIT_2:
			begin
				lmk_write <= 1'b1;
				state <= WAIT_1;
			end
	
			WAIT_1:
			begin
				lmk_write <= 1'b0;
				if(ready_n)
				begin
					state <= WAIT;
				end
			end
	
			WAIT:
			begin
				if(!ready_n)
				begin
					if(index == STOP_INDEX)
					begin
						index <= 4'd0;
						state <= CONFIGURED;
						done <= 1'b1;
					end
					else
					begin
						index <= index + 1'b1;
						state <= INC;
					end
				end
			end
			
			INC:
			begin
				lmk_write <= 1'b1;
				state <= WAIT_1;
			end

			CONFIGURED:
			begin
				state <= CONFIGURED;
				//done <= 1'b0;
			end
	
			default:
			begin
				index <= 4'd0;
				lmk_write <= 1'b0;
				state <= IDLE;
			end
	
		endcase
	end

end


endmodule
