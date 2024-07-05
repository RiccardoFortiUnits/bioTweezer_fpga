module calcRay#
(
	parameter inputWidth = 8,
	parameter inputFracWidth = 7,
	parameter outputWidth = 8,
	parameter outputFracWidth = 7
)(
	input clk,
	input reset,
	
	input signed [7:0] x,
	input signed [7:0] y,
	output unsigned [7:0] r
);
localparam inputWholeWidth = inputWidth - inputFracWidth;
localparam outputWholeWidth = outputWidth - outputFracWidth;

localparam nOfInputs = 2;
wire [inputWidth-1:0] inputs [nOfInputs-1:0];
assign inputs[0] = x;
assign inputs[1] = y;
wire [inputWidth*2-1:0] inputs_squared[nOfInputs-1:0];

wire [inputWidth*2 +nOfInputs-1 -1:0] squareSum = inputs_squared[0]+inputs_squared[1];//+inputs_squared[2];

/*
generate
genvar gi;
	for(gi=0;gi<nOfInputs;gi=gi+1)begin
		FractionalMultiplier #(
			.A_WIDTH			(inputWidth),
			.B_WIDTH			(inputWidth),
			.OUTPUT_WIDTH	(inputWidth*2),
			.FRAC_BITS_A	(inputFracWidth),
			.FRAC_BITS_B	(inputFracWidth),
			.FRAC_BITS_OUT	(inputFracWidth*2)
		)fm(
		  .a				(inputs[gi]),
		  .b				(inputs[gi]),
		  .result		(inputs_squared[gi])
		);
	end	
endgenerate
*/

FractionalMultiplier #(
	.A_WIDTH			(inputWidth),
	.B_WIDTH			(inputWidth),
	.OUTPUT_WIDTH	(inputWidth*2),
	.FRAC_BITS_A	(inputFracWidth),
	.FRAC_BITS_B	(inputFracWidth),
	.FRAC_BITS_OUT	(inputFracWidth*2)
)fm0(
  .a				(inputs[0]),
  .b				(inputs[0]),
  .result		(inputs_squared[0])
);

FractionalMultiplier #(
	.A_WIDTH			(inputWidth),
	.B_WIDTH			(inputWidth),
	.OUTPUT_WIDTH	(inputWidth*2),
	.FRAC_BITS_A	(inputFracWidth),
	.FRAC_BITS_B	(inputFracWidth),
	.FRAC_BITS_OUT	(inputFracWidth*2)
)fm1(
  .a				(inputs[1]),
  .b				(inputs[1]),
  .result		(inputs_squared[1])
);
//
sqrt_fixedPoint#(
	.inputWidth			(inputWidth*2 +nOfInputs-1),
	.outputWidth		(outputWidth)
)sqrtFp(
	.aclr(reset),
	.clk(clk),
	.radical(squareSum),
	.q(r),
	.remainder()
);
endmodule