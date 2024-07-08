module sqrt_fixedPoint#(
	parameter inputWidth = 8,
	parameter inputDecWidth = 8,
	parameter outputWidth = inputWidth
)(
	input 								aclr,
	input 								clk,
	input [inputWidth-1:0]			radical,
	output [outputWidth-1:0]		q,
	output [outputWidth+1 -1:0]			remainder
);
	localparam outputDecWidth = outputWidth - (inputWidth-inputDecWidth+1)/2;

	wire [2*outputWidth-1:0] paddedRadical = {radical, {(2*outputWidth-inputWidth){1'b0}}};
//	wire [outputWidth-1:0] 
	
//code copied from a compiled IP code
altsqrt	 #(
    .pipeline (2),
    .q_port_width (outputWidth),
    .r_port_width (outputWidth+1),
    .width  (2*outputWidth)
)ALTSQRT_component(
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


endmodule