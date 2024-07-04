// When reset_n is deasserted keeps the "delay_reset_n" low for a specified delay time, then deassert it and pulse the start config

module initial_reset # (parameter REG_SIZE = 32)
(
	input 					clk,  		// system   clock 50MHz 
	input 					reset_n, 		// system reset 
	input [REG_SIZE-1:0]	delay,
	output reg 				delay_reset_n = 1'b0, /*synthesis noprune*/
	output reg 				start_config = 1'b0
);

reg [REG_SIZE-1:0] counter = 0;

reg [1:0] STATE = 1'b0;

always@(posedge clk or negedge reset_n)
begin
	if (~reset_n)
	begin 
		counter <= 0;
		delay_reset_n <= 1'b0;
		STATE <= 2'd0;
		start_config <= 1'b0;
	end
	else
		case (STATE)
			2'd0: 
			begin
				delay_reset_n <= 1'b0;
				counter <= counter + 1'b1;
				if (counter == delay) 
				begin
					delay_reset_n <= 1'b1;
					STATE <= 2'd1;
				end
			end

			2'd1:
			begin
				start_config <= 1'b1;
				STATE <= 2'd2;
			end

			2'd2:
			begin
				start_config <= 1'b0;
			end

			default: 
			begin
				counter <= 0;
				delay_reset_n <= 1'b0;
				start_config <= 1'b0;
				STATE <= 1'b0;
			end
		endcase
end
	



endmodule




