

module FractionalMultiplier #(parameter A_WIDTH = 16,
                              parameter B_WIDTH = 16,
                              parameter OUTPUT_WIDTH = 16,
                              parameter FRAC_BITS_A = 4,
                              parameter FRAC_BITS_B = 4,
                              parameter FRAC_BITS_OUT = 8) (
  input wire signed [A_WIDTH-1:0] a,
  input wire signed [B_WIDTH-1:0] b,
  output wire signed [OUTPUT_WIDTH-1:0] result
);
  wire signed [A_WIDTH + B_WIDTH - 1:0] full_aByb;
 
  assign full_aByb = $signed(a) * $signed(b);
  
  assign result = full_aByb[OUTPUT_WIDTH - 1 + FRAC_BITS_A + FRAC_BITS_B - FRAC_BITS_OUT: 
                                               FRAC_BITS_A + FRAC_BITS_B - FRAC_BITS_OUT];

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
reg signed [A_WIDTH + B_WIDTH - 1:0] full_aByb;

//generate
//    if(areSignalsSigned)begin
//        always @(posedge clk)
//            full_aByb <= $signed(a) * $signed(b);
//    end else begin
//        always @(posedge clk)
//            full_aByb <= $unsigned(a) * $unsigned(b);
//        
//    end
//endgenerate

assign result = full_aByb[OUTPUT_WIDTH - 1 + FRAC_BITS_A + FRAC_BITS_B - FRAC_BITS_OUT: 
                                               FRAC_BITS_A + FRAC_BITS_B - FRAC_BITS_OUT];

generate
    if(areSignalsSigned)begin
		lpm_mult	lpm_mult_component (
					.aclr (reset),
					.clock (clk),
					.dataa (a),
					.datab (b),
					.result (full_aByb),
					.clken (1'b1),
					.sclr (1'b0),
					.sum (1'b0));
		defparam
			lpm_mult_component.lpm_hint = "MAXIMIZE_SPEED=5",
			lpm_mult_component.lpm_pipeline = 1,
			lpm_mult_component.lpm_representation = "SIGNED",//only difference between the 2 modules
			lpm_mult_component.lpm_type = "LPM_MULT",
			lpm_mult_component.lpm_widtha = A_WIDTH,
			lpm_mult_component.lpm_widthb = B_WIDTH,
			lpm_mult_component.lpm_widthp = A_WIDTH + B_WIDTH;
    end else begin
		lpm_mult	lpm_mult_component (
					.aclr (reset),
					.clock (clk),
					.dataa (a),
					.datab (b),
					.result (full_aByb),
					.clken (1'b1),
					.sclr (1'b0),
					.sum (1'b0));
		defparam
			lpm_mult_component.lpm_hint = "MAXIMIZE_SPEED=5",
			lpm_mult_component.lpm_pipeline = 1,
			lpm_mult_component.lpm_representation = "UNSIGNED",//only difference between the 2 modules
			lpm_mult_component.lpm_type = "LPM_MULT",
			lpm_mult_component.lpm_widtha = A_WIDTH,
			lpm_mult_component.lpm_widthb = B_WIDTH,
			lpm_mult_component.lpm_widthp = A_WIDTH + B_WIDTH;	 
	 end
endgenerate
endmodule
