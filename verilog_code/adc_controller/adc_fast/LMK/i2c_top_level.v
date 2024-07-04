`include "i2c_master_byte_ctrl.v"

module i2c_top_level (

	input clk,
	input reset,

	input start_write,
	input start_read,
	input [6:0] address,
	input [15:0] data,

	output reg ready_n,


	// I2C signals
	// i2c clock line
	input  scl_pad_i,       // SCL-line input
	output scl_pad_o,       // SCL-line output (always 1'b0)
	output scl_padoen_o,    // SCL-line output enable (active low)
	// i2c data line
	input  sda_pad_i,       // SDA-line input
	output sda_pad_o,       // SDA-line output (always 1'b0)
	output sda_padoen_o    // SDA-line output enable (active low)

);



i2c_master_byte_ctrl i2c_master_byte_ctrl_0 (

	.clk(clk),
	.rst(reset),	//synchronous reset
	.nReset(1'b1), //asynchronous reset disabled
		// control signals
	.ena(1'b1),
		//clk prescaler = f_clk/(5*f_i2c) - 1; es: 100M/(5*100k) - 1 = 199
	.clk_cnt(16'd99),
	.start(ic_start),
	.stop(ic_stop),
	.read(ic_read),
	.write(ic_write),
	.ack_in(ic_ack_in),
	.din(i2c_data_reg),
		//output signals
	.cmd_ack(),
	.ack_out(),
	.dout(),
	.i2c_busy(),
	.i2c_al(),
	.mod_busy(busy),
		// i2c signals
	.scl_i(scl_pad_i),
	.scl_o(scl_pad_o),
	.scl_oen(scl_padoen_o),
	.sda_i(sda_pad_i),
	.sda_o(sda_pad_o),
	.sda_oen(sda_padoen_o)
	
	);

parameter 	IC_IDLE = 3'd0,
				IC_WRITE_ADDR = 3'd1,
				IC_WRITE_WAIT = 3'd2,
				IC_WRITE_DH = 3'd3,
				IC_WRITE_WAIT_2 = 3'd4,
				IC_WRITE_DL = 3'd5,
				IC_WRITE_WAIT_3 = 3'd6,
				IC_FINALIZE = 3'd7;

reg [2:0] IC_STATE;

reg ic_start;
reg ic_stop;
reg ic_read;
reg ic_write;
reg ic_ack_in;

wire busy;

reg [6:0] address_reg;
reg [7:0] data_reg_h;
reg [7:0] data_reg_l;
reg [7:0] i2c_data_reg;

always @ (posedge clk)
begin
	if(reset)
	begin
		ic_start <= 1'b0;
		ic_stop <= 1'b0;
		ic_read <= 1'b0;
		ic_write <= 1'b0;
		ic_ack_in <= 1'b0;
		ready_n <= 1'b0;
		IC_STATE <= IC_IDLE;
	end
	else
	begin
		case(IC_STATE)
		
			IC_IDLE: begin
				if(start_write || start_read) begin
					address_reg <= address;
					data_reg_h <= data[15:8];
					data_reg_l <= data[7:0];
					ready_n <= 1'b1;
					IC_STATE <= IC_WRITE_ADDR;
				end
			end

			IC_WRITE_ADDR: begin
				i2c_data_reg <= {address_reg,1'b0}; // r/w bit
				ic_start <= 1'b1;
				ic_write <= 1'b1;
				//ic_stop <= 1'b1;
				IC_STATE <= IC_WRITE_WAIT;
			end
			
			IC_WRITE_WAIT: begin
				if(busy)
				begin
					IC_STATE <= IC_WRITE_DH;
				end
			end
			
			IC_WRITE_DH: begin
				if(!busy) begin					
					if(ic_ack_in) begin
						//failure
						// err <= 1'b1;
						ic_start <= 1'b0;
						ic_write <= 1'b0;
						ic_stop <= 1'b0;
						IC_STATE <= IC_IDLE;
					end
					else begin
						ic_start <= 1'b0;
						ic_write <= 1'b1;
						i2c_data_reg <= data_reg_h;
						IC_STATE <= IC_WRITE_WAIT_2;
					end
				end			
			end
						
			IC_WRITE_WAIT_2: begin
				if(busy) begin
					IC_STATE <= IC_WRITE_DL;
				end			
			end
						
			IC_WRITE_DL: begin
				if(!busy) begin					
					if(ic_ack_in) begin
						//failure
						// err <= 1'b1;
						ic_start <= 1'b0;
						ic_write <= 1'b0;
						ic_stop <= 1'b0;
						IC_STATE <= IC_IDLE;
					end
					else begin
						ic_start <= 1'b0;
						ic_stop <= 1'b1;
						ic_write <= 1'b1;
						i2c_data_reg <= data_reg_l;
						IC_STATE <= IC_WRITE_WAIT_3;
					end
				end			
			end
						
			IC_WRITE_WAIT_3: begin
				if(busy) begin
					IC_STATE <= IC_FINALIZE;
				end
			end
			
			
			IC_FINALIZE: begin
				if(!busy) begin
					ic_write <= 1'b0;
					ic_stop <= 1'b0;
					ic_start <= 1'b0;
					ready_n <= 1'b0;
					IC_STATE <= IC_IDLE;
				end			
			end
			
		endcase
	end	
end
endmodule
