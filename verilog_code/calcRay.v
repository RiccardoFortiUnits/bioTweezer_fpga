module calcRay#
(
	parameter inputWidth = 8,
	parameter inputFracWidth = 4,
	parameter outputWidth = 8,
	parameter outputFracWidth = 4
)(
	input clk,
	input reset,
	
	input signed [inputWidth -1:0] x,
	input signed [inputWidth -1:0] y,
	output [outputWidth -1:0] r
);
localparam nOfInputs = 2;//3;

localparam 	inputWholeWidth = inputWidth - inputFracWidth,
				outputWholeWidth = outputWidth - outputFracWidth,
				squareBitWidth = inputWidth * 2,//with the sqrt we'll lose half of the bits, so there's no reason to be stingy with the multiplication size
				squareFracWidth = inputFracWidth * 2,
				squareSumBitWidth = squareBitWidth + 1,//sum of 2 or 3 numbers => we require one bit more
				squareSumFracWidth = squareFracWidth,
				sqrtBitWidth = (squareSumBitWidth+1)/2,
				sqrtFracWidth = squareSumFracWidth/2;

wire [inputWidth-1:0] inputs [nOfInputs-1:0];
assign inputs[0] = x;
assign inputs[1] = y;
wire [squareBitWidth-1:0] inputs_squared[nOfInputs-1:0];



generate
genvar gi;
	for(gi=0;gi<nOfInputs;gi=gi+1)begin:forCycle
		clocked_FractionalMultiplier #(
			.A_WIDTH			(inputWidth),
			.B_WIDTH			(inputWidth),
			.OUTPUT_WIDTH	(squareBitWidth),
			.FRAC_BITS_A	(inputFracWidth),
			.FRAC_BITS_B	(inputFracWidth),
			.FRAC_BITS_OUT	(squareFracWidth)
		)fm(
		  .clk(clk),
		  .reset(reset),
		  .a				(inputs[gi]),
		  .b				(inputs[gi]),
		  .result		(inputs_squared[gi])
		);
	end	
endgenerate

wire [squareSumBitWidth -1:0] squareSum = inputs_squared[0]+inputs_squared[1];//+inputs_squared[2];
wire [sqrtBitWidth -1:0] sqrtOfSum;
sqrt_fixedPoint#(
	.inputWidth			(squareSumBitWidth),
	.outputWidth		(sqrtBitWidth)
)sqrtFp(
	.aclr(reset),
	.clk(clk),
	.radical(squareSum),
	.q(sqrtOfSum),
	.remainder()
);

fixedPointShifter#(
	.inputBitSize	(sqrtBitWidth),
	.inputFracSize	(sqrtFracWidth),
	.outputBitSize	(outputWidth),
	.outputFracSize	(outputFracWidth),
	.isSigned		(0)
)shifOutput(
	.in		(sqrtOfSum),
	.out	(r)
);
endmodule

