module timedSwitch #(
	parameter maxTime = 32'h10000,
	parameter nOfDifferentOutputs = 2
) (
	input clk,
	input reset,
	input enable,
	input [$clog2(maxTime+1) -1:0] cyclesBeforeSwitching,
	output reg [$clog2(nOfDifferentOutputs) -1:0] out
);
localparam s_idle = 0,
			s_running = 1;
reg state;
reg [$clog2(maxTime+1) -1:0] counter;
always @(posedge clk) begin
	if(reset) begin
		counter <= 0;
		out <= 0;
		state <= s_idle;
	end else begin
		if(enable)begin
			if(state == s_idle)begin
				state <= s_running;
				counter <= cyclesBeforeSwitching - 1;
				out <= 0;
			end else if(state == s_running)begin
				if(counter)begin
					counter <= counter - 1;
				end else begin
					if(out == nOfDifferentOutputs - 1)begin
						out <= 0;
					end else begin
						out <= out + 1;
					end
					counter <= cyclesBeforeSwitching - 1;
				end
			end
		end else begin
			state <= s_idle;
		end
	end
end


endmodule