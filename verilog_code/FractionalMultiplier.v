

module FractionalMultiplier #(
	parameter A_WIDTH = 16,
	parameter B_WIDTH = 16,
	parameter OUTPUT_WIDTH = 16,
	parameter FRAC_BITS_A = 4,
	parameter FRAC_BITS_B = 4,
	parameter FRAC_BITS_OUT = 8,
	parameter areSignalsSigned = 1
 ) (
  input wire signed [A_WIDTH-1:0] a,
  input wire signed [B_WIDTH-1:0] b,
  output wire signed [OUTPUT_WIDTH-1:0] result
);
  wire signed [A_WIDTH + B_WIDTH - 1:0] full_aByb;
 
  assign full_aByb = $signed(a) * $signed(b);
  
//  assign result = full_aByb[OUTPUT_WIDTH - 1 + FRAC_BITS_A + FRAC_BITS_B - FRAC_BITS_OUT: 
//                                               FRAC_BITS_A + FRAC_BITS_B - FRAC_BITS_OUT];

	fixedPointShifter#(
		.inputBitSize	(A_WIDTH + B_WIDTH),
		.inputFracSize	(FRAC_BITS_A + FRAC_BITS_B),
		.outputBitSize	(OUTPUT_WIDTH),
		.outputFracSize	(FRAC_BITS_OUT),
		.isSigned		(areSignalsSigned)
	)outShifter(
		.in				(full_aByb),
		.out			(result)
	);
															  
endmodule

module clocked_FractionalMultiplier #(
          parameter A_WIDTH = 16,
          parameter B_WIDTH = 16,
          parameter OUTPUT_WIDTH = 16,
          parameter FRAC_BITS_A = 4,
          parameter FRAC_BITS_B = 4,
          parameter FRAC_BITS_OUT = 8,
          parameter areSignalsSigned = 1) (
  input wire clk,
  input wire reset,
  input wire signed [A_WIDTH-1:0] a,
  input wire signed [B_WIDTH-1:0] b,
  output wire signed [OUTPUT_WIDTH-1:0] result
);
wire signed [A_WIDTH + B_WIDTH - 1:0] full_aByb;




//assign result = full_aByb[OUTPUT_WIDTH - 1 + FRAC_BITS_A + FRAC_BITS_B - FRAC_BITS_OUT: 
//                                               FRAC_BITS_A + FRAC_BITS_B - FRAC_BITS_OUT];
	fixedPointShifter#(
		.inputBitSize	(A_WIDTH + B_WIDTH),
		.inputFracSize	(FRAC_BITS_A + FRAC_BITS_B),
		.outputBitSize	(OUTPUT_WIDTH),
		.outputFracSize	(FRAC_BITS_OUT),
		.isSigned		(areSignalsSigned)
	)outShifter(
		.in				(full_aByb),
		.out			(result)
	);

generate
    if(areSignalsSigned)begin
		lpm_mult#(
			.lpm_hint		("MAXIMIZE_SPEED=5"),
			.lpm_pipeline		(1),
			.lpm_representation		("SIGNED"),//only difference between the 2 modules
			.lpm_type		("LPM_MULT"),
			.lpm_widtha		(A_WIDTH),
			.lpm_widthb		(B_WIDTH),
			.lpm_widthp		(A_WIDTH + B_WIDTH)
		)	lpm_mult_component (
					.aclr (reset),
					.clock (clk),
					.dataa (a),
					.datab (b),
					.result (full_aByb),
					.clken (1'b1),
					.sclr (1'b0),
					.sum (1'b0));
    end else begin
		lpm_mult#(
			.lpm_hint("MAXIMIZE_SPEED=5"),
			.lpm_pipeline(1),
			.lpm_representation("UNSIGNED"),//only difference between the 2 modules
			.lpm_type("LPM_MULT"),
			.lpm_widtha(A_WIDTH),
			.lpm_widthb(B_WIDTH),
			.lpm_widthp(A_WIDTH + B_WIDTH)
		)	lpm_mult_component (
					.aclr (reset),
					.clock (clk),
					.dataa (a),
					.datab (b),
					.result (full_aByb),
					.clken (1'b1),
					.sclr (1'b0),
					.sum (1'b0));
	 end
endgenerate
endmodule
