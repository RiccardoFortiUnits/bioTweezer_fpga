module calcRay#
(
	parameter inputWidth = 8,
	parameter inputFracWidth = 7,
	parameter outputWidth = 8,
	parameter outputFracWidth = 7
)(
	input clk,
	input reset,
	
	input signed [inputWidth -1:0] x,
	input signed [inputWidth -1:0] y,
	input signed [inputWidth -1:0] z,
	output [outputWidth -1:0] xSquare,
	output [outputWidth -1:0] ySquare,
	output [outputWidth -1:0] zSquare,
	output [outputWidth -1:0] r,
	output outData_valid
);
localparam nOfInputs = 3;

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
assign inputs[2] = z;
wire [squareBitWidth-1:0] inputs_square[nOfInputs-1:0];



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
		  .result		(inputs_square[gi])
		);
	end	
endgenerate

wire [squareSumBitWidth -1:0] squareSum = inputs_square[0]+inputs_square[1]+inputs_square[2];
wire [sqrtBitWidth -1:0] sqrtOfSum;
sqrt_fixedPoint#(
	.inputWidth			(squareSumBitWidth),
	.outputWidth		(sqrtBitWidth)
)sqrtFp(
	.aclr(reset),
	.clk(clk),
	.radical(squareSum),
	.q(sqrtOfSum),
	.remainder(),
	.outData_valid(outData_valid)
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
fixedPointShifter#(
	.inputBitSize	(squareBitWidth),
	.inputFracSize	(squareFracWidth),
	.outputBitSize	(outputWidth),
	.outputFracSize(outputFracWidth),
	.isSigned		(0)
)shiftXsquare(
	.in		(inputs_square[0]),
	.out	(xSquare)
);
fixedPointShifter#(
	.inputBitSize	(squareBitWidth),
	.inputFracSize	(squareFracWidth),
	.outputBitSize	(outputWidth),
	.outputFracSize(outputFracWidth),
	.isSigned		(0)
)shiftYsquare(
	.in		(inputs_square[1]),
	.out	(ySquare)
);
fixedPointShifter#(
	.inputBitSize	(squareBitWidth),
	.inputFracSize	(squareFracWidth),
	.outputBitSize	(outputWidth),
	.outputFracSize(outputFracWidth),
	.isSigned		(0)
)shiftZsquare(
	.in		(inputs_square[2]),
	.out	(zSquare)
);
endmodule

