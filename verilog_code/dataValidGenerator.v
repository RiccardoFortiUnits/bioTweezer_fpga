module dataValidGenerator#(
	parameter moduleDelay = 2
)(
	input clk,
	input reset,
	input previousDataValid,//keep at 1 if there's no previous module to wait for
	output reg dataValid
);

reg [$clog2(moduleDelay) -1:0] counter;

always @(negedge clk)begin
	if(reset || !previousDataValid)begin
		dataValid <= 0;
		counter <= moduleDelay - 1;
	end else begin
		if(|counter)begin
			dataValid <= 0;
			counter <= counter - 1;
		end else begin
			dataValid <= 1;
		end
	end
end

endmodule
