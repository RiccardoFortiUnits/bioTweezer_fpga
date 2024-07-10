module sqrt_fixedPoint#(
	parameter inputWidth = 8,
	parameter inputDecWidth = 8,
	parameter outputWidth = inputWidth
)(
	input 								aclr,
	input 								clk,
	input [inputWidth-1:0]			radical,
	output [outputWidth-1:0]		q,
	output [outputWidth+1 -1:0]	remainder,
	output outData_valid
);
	localparam outputDecWidth = outputWidth - (inputWidth-inputDecWidth+1)/2;
	localparam inputWholeWidth = inputWidth - inputDecWidth;
	localparam isWholePartOdd = inputWholeWidth & 1;

	wire [2*outputWidth-1:0] paddedRadical = {
		{isWholePartOdd{1'b0}},
		radical,
		{(2*outputWidth-inputWidth-isWholePartOdd){1'b0}}
	};
//	assign paddedRadical[2*outputWidth-isWholePartOdd -1-:inputWidth]	= radical;
//	wire [outputWidth-1:0] 
	
//code copied from a compiled IP code
localparam sqrtPipelineDelay = 2;
altsqrt	 #(
	.pipeline (sqrtPipelineDelay),
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
dataValidGenerator#(sqrtPipelineDelay)dvg(
	clk, aclr, 1'b1, outData_valid
);

endmodule