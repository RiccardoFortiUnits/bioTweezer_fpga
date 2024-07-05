module sqrt_fixedPoint#(
	parameter inputWidth = 8,
	parameter inputDecWidth = 8,
	parameter outputWidth = inputWidth
)(
	input 								aclr,
	input 								clk,
	input [inputWidth-1:0]			radical,
	output [outputWidth-1:0]		q,
	output [inputWidth-1:0]			remainder
);
	localparam outputDecWidth = outputWidth - (inputWidth-inputDecWidth+1)/2;

	wire [2*outputWidth-1:0] paddedRadical = {radical, {(2*outputWidth-inputWidth){1'b0}}};
//	wire [outputWidth-1:0] 
	
//code copied from a compiled IP code
	altsqrt	ALTSQRT_component (
				.aclr (aclr),
				.clk (clk),
				.radical (paddedRadical),
				.q (q),
				.remainder (remainder)
				// synopsys translate_off
				,
				.ena ()
				// synopsys translate_on
				);
	defparam
		ALTSQRT_component.pipeline = 2,
		ALTSQRT_component.q_port_width = outputWidth,
		ALTSQRT_component.r_port_width = inputWidth,
		ALTSQRT_component.width = 2*outputWidth;


endmodule