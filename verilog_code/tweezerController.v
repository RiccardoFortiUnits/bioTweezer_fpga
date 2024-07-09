module tweezerController#(
	parameter inputBitSize = 16,
	parameter inputFracSize = 15,
	parameter outputBitSize = 16,
	parameter outputFracSize = 15,
	parameter coeffBitSize = 10,
	parameter coeffFracSize = 9,
	parameter workingBitSize = 24,//I'm too lazy to follow all the bit size conversions... let's just use a bigger register size for all the internal processes
	//todo usa meglio workingBitSize
	parameter workingFracSize = 20
)(
	input clk,
	input reset,	
	
	input [inputBitSize -1:0] XDIFF,
	input [inputBitSize -1:0] YDIFF,
	input [inputBitSize -1:0] SUM,
	output [outputBitSize -1:0] retroactionController,
	output retroactionController_valid,
	
	input PI_reset,
	input PI_enable,
	input PI_freeze,
	input [coeffBitSize -1:0] PI_kp,
	input [coeffBitSize -1:0] PI_ki
	
	//debug wires
	, output [outputBitSize -1:0] ray
);

//get x, y and z of the bead
wire [workingBitSize -1:0] x,y;

//for now, x=XDIFF, y=YDIFF
fixedPointShifter#(inputBitSize, inputFracSize, workingBitSize, workingFracSize) 
	XDIFF_to_x(XDIFF, x);
fixedPointShifter#(inputBitSize, inputFracSize, workingBitSize, workingFracSize) 
	YDIFF_to_y(YDIFF, y);
	
//get distance of the bead
wire [workingBitSize -1:0] r;
calcRay#
(
  .inputWidth        (workingBitSize),
  .inputFracWidth    (workingFracSize),
  .outputWidth       (workingBitSize),
  .outputFracWidth   (workingFracSize)
)get_r(
  .clk		(clk),
  .reset	(reset),
  .x			(x),
  .y			(y),
  .r			(r)	
);

//PI controller on the distance
wire [workingBitSize -1:0] pi_out;
pi_controller#(
	.inputBitSize			(workingBitSize),
	.inputFracSize		(workingFracSize),
	.outputBitSize		(workingBitSize),
	.outputFracSize		(workingFracSize),
	.coeffBitSize			(coeffBitSize),
	.coeffFracSize		(coeffFracSize),
	.productsFracSize	(workingBitSize)
)PI(
	.clk							(clk),
	.reset						(reset),
	.reset_pi					(PI_reset),
	.enable_pi				(PI_enable),
	.pi_limiting			(PI_freeze),
	.pi_setpoint			(0),
	.pi_input					(r),
	.pi_input_valid		(!reset),
	.pi_kp_coefficient(PI_kp),
	.pi_ti_coefficient(PI_ki),
	.pi_output				(pi_out),
	.pi_output_valid	(retroactionController_valid)
);

fixedPointShifter#(workingBitSize, workingFracSize, outputBitSize, outputFracSize) 
	pi_out_to_retroactionController(pi_out, retroactionController);
	
	
//debug wires

fixedPointShifter#(workingBitSize, workingFracSize, outputBitSize, outputFracSize) 
	r_to_ray(r, ray);

endmodule