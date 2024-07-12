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
	input [coeffBitSize -1:0] PI_ki,
	input PI_kp_update,
	input PI_ki_update
	//debug wires
	, output [outputBitSize -1:0] ray
);

//get x, y and z of the bead
wire [workingBitSize -1:0] x,y;

//for now, x=XDIFF, y=YDIFF
fixedPointShifter#(inputBitSize, inputFracSize, workingBitSize, workingFracSize, 1) 
	XDIFF_to_x(XDIFF, x);
fixedPointShifter#(inputBitSize, inputFracSize, workingBitSize, workingFracSize, 1) 
	YDIFF_to_y(YDIFF, y);
	
//get distance of the bead
wire [workingBitSize -1:0] r;
wire r_valid;
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
	.r			(r),
	.outData_valid(r_valid)	
);

reg [coeffBitSize -1:0] PI_kp_reg, PI_ki_reg;
reg singlePiReset;// used to reset the integral part of the PI when we change the parameter ki

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
	.clk						(clk),
	.reset					(reset),
	.reset_pi				(PI_reset | singlePiReset),
	.enable_pi				(PI_enable),
	.pi_limiting			(PI_freeze),
	.pi_setpoint			({workingBitSize{1'b0}}),
	.pi_input				(r),
	.pi_input_valid		(r_valid),
	.pi_kp_coefficient	(PI_kp_reg),
	.pi_ti_coefficient	(PI_ki_reg),
	.pi_output				(pi_out),
	.pi_output_valid		(retroactionController_valid)
);

fixedPointShifter#(workingBitSize, workingFracSize, outputBitSize, outputFracSize, 1) 
	pi_out_to_retroactionController(pi_out, retroactionController);
	
//parameter updates
reg PI_kp_updateReceived;
always @(posedge clk)begin
	if(reset)begin
		PI_kp_reg <= 0;
		PI_ki_reg <= 0;
			PI_kp_updateReceived <= 0;
	end else begin
		if(PI_kp_update)begin
			PI_kp_reg <= PI_kp;
			PI_kp_updateReceived <= 1;
		end
		if(PI_ki_update)begin
			PI_ki_reg <= PI_ki;
			singlePiReset <= 1;
		end else begin
			singlePiReset <= 0;
		end
	end
end
	
	
	
//debug wires

fixedPointShifter#(workingBitSize, workingFracSize, outputBitSize, outputFracSize, 1) 
	r_to_ray(r, ray);
	
endmodule