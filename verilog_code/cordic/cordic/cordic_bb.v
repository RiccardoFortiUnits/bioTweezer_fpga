
module cordic (
	clk,
	areset,
	x,
	y,
	q,
	r,
	en);	

	input		clk;
	input		areset;
	input	[31:0]	x;
	input	[31:0]	y;
	output	[26:0]	q;
	output	[26:0]	r;
	input	[0:0]	en;
endmodule
