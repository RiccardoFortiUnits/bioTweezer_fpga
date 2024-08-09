module functionsOnSUM#(
    parameter inputBitSize = 16,
    parameter inputFracSize = 15,
    parameter coeffBitSize = 10,
    parameter coeffFracSize = 9,
	 parameter largeCoeffBitSize = coeffBitSize,
	 parameter largeCoeffFracSize = coeffFracSize - 2,
    parameter workingBitSize = 24,
    parameter workingFracSize = 20
)(
    input clk,
    input reset,
	 
	 input [inputBitSize -1:0] SUM,
	 output [workingBitSize -1:0] sumForDivision,
	 output [workingBitSize -1:0] z,
	 
	 input [inputBitSize -1:0] div_offset,
    input [largeCoeffBitSize -1:0] div_multiplier,
	 input [inputBitSize -1:0] z_offset,
	 input [largeCoeffBitSize -1:0] z_multiplier
);


wire [2*inputBitSize+2 -1:0] SUM_withOffset;
wire [2*inputBitSize -1:0] offsets;
assign offsets = {z_offset, div_offset};

adder#(
  .WIDTH      	(inputBitSize),
  .addStuffingBit	(1),
  .isSubtraction  (0)
)addOffset [1:0](
  .clk    (clk),
  .reset    (reset),
  .a      (SUM),
  .b      (offsets),
  .result   (SUM_withOffset)
);


wire [2*largeCoeffBitSize -1:0] multipliers;
assign multipliers = {z_multiplier, div_multiplier};
wire [2*workingBitSize -1:0] outs;

clocked_FractionalMultiplier #(
    .A_WIDTH            (inputBitSize+1),
    .B_WIDTH            (largeCoeffBitSize),
    .OUTPUT_WIDTH   (workingBitSize),
    .FRAC_BITS_A    (inputFracSize),
    .FRAC_BITS_B    (largeCoeffFracSize),
    .FRAC_BITS_OUT  (workingFracSize)
)multiplyAll [1:0](
  .clk(clk),
  .reset(reset),
  .a                (SUM_withOffset),
  .b                (multipliers),
  .result       (outs)
);

assign {z, sumForDivision} = outs;


endmodule