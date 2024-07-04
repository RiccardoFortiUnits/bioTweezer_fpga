`include "mac_config_LUT.v"

module 	mac_config 	(
	
		input				clock,
		input				reset,
		input				start,
		input [47:0]		mac_address,
		output reg			finish_mac,	
		
		input						avl_busy,
		input [31:0]			avl_readdata,
		output wire [7:0]		avl_address,
		output wire [31:0]	avl_writedata,
		output reg				avl_read_req,
		output reg				avl_write_req
		

);

parameter LENGTH = 8'd27;

reg [7:0] 	index 	= 8'd0;						// max i sarà 30

parameter 	IDLE 	= 3'd0,
				RD	= 3'd1,
				WR 	= 3'd2,
				STOP 	= 3'd3,
				START = 3'd4; 
				
reg [2:0] 	STATE_MAC = IDLE;

reg start_1, start_2;

always @(posedge clock ) begin
    start_2 <= start_1;
    start_1 <= start;
end
	

wire wr;

	mac_config_LUT mac_config_LUT_0 (
		.index(index),
		.data(avl_writedata),
		.address(avl_address),
		.mac_address(mac_address),
		.wr(wr)
	);
	
	always @(posedge clock)
	begin
		if(reset)
		begin
			avl_read_req <= 1'b0;
			avl_write_req <= 1'b0;
			index <= 8'd0;
			finish_mac <= 1'b0;
			STATE_MAC <= IDLE;
		end
		else
		begin
			case(STATE_MAC)
			
			IDLE:
			begin
				if(start_2)
				begin
					STATE_MAC <= START;
					index <= 8'd0;
				end
				else
				begin
					finish_mac <= 1'b0;
					STATE_MAC <= IDLE;
				end
			end
			
			START:
			begin
				if(wr)
				begin
					avl_write_req <= 1'b1;
					avl_read_req <= 1'b0;
					STATE_MAC <= WR;
				end
				else
				begin
					avl_read_req <= 1'b1;
					avl_write_req <= 1'b0;
					STATE_MAC <= RD;
				end
			end
			
			WR:
			begin
				if(!avl_busy)
				begin
					avl_write_req <= 1'b0;
					if(index == LENGTH - 1)
					begin
						STATE_MAC <= STOP;
					end
					else
					begin
						index <= index + 1'b1;
						STATE_MAC <= START;
					end
				end
			end
			
			RD:
            begin
                if(!avl_busy & (avl_writedata == avl_readdata))
                begin
                    avl_read_req <= 1'b0;
                    if(index == LENGTH - 1)
                    begin
                        STATE_MAC <= STOP;
                    end
                    else
                    begin
                        index <= index + 1'b1;
                        STATE_MAC <= START;
                    end
                end
            end
			
			STOP:
			begin
				finish_mac <= 1'b1;
			end
		
			default:
			begin
				avl_read_req 	<= 1'b0;
				avl_write_req 	<= 1'b0;
				index 		<= 8'd0;
				finish_mac 	<= 1'b0;
				STATE_MAC 	<= IDLE;
			end
			
			
			endcase
		end
		
	end
			
endmodule
