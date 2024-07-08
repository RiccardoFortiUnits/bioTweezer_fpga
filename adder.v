module adder#(
	parameter WIDTH = 16,
	parameter isSubtraction = 0
)(
	input wire clk,
	input wire reset,
	input wire signed [WIDTH-1:0] a,
	input wire signed [WIDTH-1:0] b,
	output wire signed [WIDTH-1:0] result
);
generate
if(isSubtraction)begin
	lpm_add_sub#(
		.lpm_direction("SUB"),//only difference between the 2 modules
		.lpm_hint("ONE_INPUT_IS_CONSTANT=NO,CIN_USED=NO"),
		.lpm_pipeline(1),
		.lpm_representation("SIGNED"),
		.lpm_type("LPM_ADD_SUB"),
		.lpm_width(WIDTH)
	)	LPM_ADD_SUB_component (
				.aclr (reset),
				.clock (clk),
				.dataa (a),
				.datab (b),
				.result (result)
				// synopsys translate_off
				,
				.add_sub (),
				.cin (),
				.clken (),
				.cout (),
				.overflow ()
				// synopsys translate_on
	);
end else begin
	lpm_add_sub#(
		.lpm_direction("ADD"),//only difference between the 2 modules
		.lpm_hint("ONE_INPUT_IS_CONSTANT=NO,CIN_USED=NO"),
		.lpm_pipeline(1),
		.lpm_representation("SIGNED"),
		.lpm_type("LPM_ADD_SUB"),
		.lpm_width(WIDTH)
	)	LPM_ADD_SUB_component (
				.aclr (reset),
				.clock (clk),
				.dataa (a),
				.datab (b),
				.result (result)
				// synopsys translate_off
				,
				.add_sub (),
				.cin (),
				.clken (),
				.cout (),
				.overflow ()
				// synopsys translate_on
	);
end
endgenerate

endmodule