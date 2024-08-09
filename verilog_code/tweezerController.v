module tweezerController#(
    parameter inputBitSize = 16,
    parameter inputFracSize = 15,
    parameter outputBitSize = 16,
    parameter outputFracSize = 15,
    parameter coeffBitSize = 10,
    parameter coeffFracSize = 9,
	 parameter largeCoeffBitSize = coeffBitSize,
	 parameter largeCoeffFracSize = coeffFracSize - 2,
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
    input PI_ki_update,
    input [outputBitSize -1:0] output_when_pi_disabled,
    input [inputBitSize -1:0] PI_setpoint,
     input [outputBitSize -1:0] pi_limit_LO,
     input [outputBitSize -1:0] pi_limit_HI,
     input [inputBitSize -1:0] sumForDivision_offset,
     input [largeCoeffBitSize -1:0] sumForDivision_multiplier,
     input [inputBitSize -1:0] z_offset,
     input [largeCoeffBitSize -1:0] z_multiplier,
     
    output [outputBitSize -1:0] ray,
    output [outputBitSize -1:0] x,
    output [outputBitSize -1:0] y,
    output [outputBitSize -1:0] z,
    output [outputBitSize -1:0] xSquare,
    output [outputBitSize -1:0] ySquare,
    output [outputBitSize -1:0] zSquare,
    
    //debug wires
    input addFeedback,
    input useSUM,
    output [3:0] leds
);

wire [inputBitSize -1:0] XDIFF_withFeedback = addFeedback & retroactionController_valid ? XDIFF + retroactionController: XDIFF;

//in case useSUM is set to 0
wire [workingBitSize -1:0] x_direct, y_direct;
fixedPointShifter#(inputBitSize, inputFracSize, workingBitSize, workingFracSize, 1) 
    XDIFF_directTo_x(XDIFF_withFeedback, x_direct);
fixedPointShifter#(inputBitSize, inputFracSize, workingBitSize, workingFracSize, 1) 
    YDIFF_directTo_y(YDIFF, y_direct);
	 

wire [workingBitSize -1:0] x_untrimmed, y_untrimmed, z_untrimmed, x_normalized, y_normalized;

wire [workingBitSize -1:0] sumForDivision;
	 
functionsOnSUM#(
    .inputBitSize       (inputBitSize),
    .inputFracSize      (inputFracSize),
    .largeCoeffBitSize  (largeCoeffBitSize),
    .largeCoeffFracSize (largeCoeffFracSize),
    .workingBitSize     (workingBitSize),
    .workingFracSize    (workingFracSize)
)fos(
    .clk                (clk),
    .reset              (reset),
    .SUM                (SUM),
    .sumForDivision     (sumForDivision),
    .z                  (z_untrimmed),
    .div_offset         (sumForDivision_offset),
    .div_multiplier     (sumForDivision_multiplier),
    .z_offset           (z_offset),
    .z_multiplier       (z_multiplier)
);

//divide HOR/VER_DIFF by SUM, to get the x and y signals
divider#(
    .A_WIDTH            (inputBitSize),
    .B_WIDTH            (workingBitSize),
    .OUTPUT_WIDTH       (workingBitSize),
    .FRAC_BITS_A        (inputFracSize),
    .FRAC_BITS_B        (workingFracSize),
    .FRAC_BITS_OUT      (workingFracSize),
    .areSignalsSigned   (1)
)xdiff_dividedBy_sumTuned [1:0](
    .clk                (clk),
    .reset              (reset),
    .a                  ({YDIFF, XDIFF_withFeedback}),
    .b                  (sumForDivision),
    .result             ({y_normalized, x_normalized}),
    .remain             ()
);

 assign x_untrimmed = useSUM ? x_normalized : x_direct;
 assign y_untrimmed = useSUM ? y_normalized : y_direct;

fixedPointShifter#(workingBitSize, workingFracSize, outputBitSize, outputFracSize, 1) 
    shift_x(x_untrimmed, x);
fixedPointShifter#(workingBitSize, workingFracSize, outputBitSize, outputFracSize, 1) 
    shift_y(y_untrimmed, y);
     
fixedPointShifter#(workingBitSize, workingFracSize, outputBitSize, outputFracSize, 1) 
    shift_z(z_untrimmed, z);

//get distance of the bead
wire [workingBitSize -1:0] r;
wire r_valid;
wire [workingBitSize -1:0] xSquare_untrimmed, ySquare_untrimmed, zSquare_untrimmed;
calcRay#
(
    .inputWidth        (workingBitSize),
    .inputFracWidth    (workingFracSize),
    .outputWidth       (workingBitSize),
    .outputFracWidth   (workingFracSize)
)get_r(
    .clk        (clk),
    .reset  (reset),
    .x          (x_untrimmed),
    .y          (y_untrimmed),
     .z         (z_untrimmed),
     
     .xSquare  (xSquare_untrimmed),
     .ySquare  (ySquare_untrimmed),
     .zSquare  (zSquare_untrimmed),
     
    .r          (r),
    .outData_valid(r_valid) 
);

reg [coeffBitSize -1:0] PI_kp_reg, PI_ki_reg;
reg singlePiReset;// used to reset the integral part of the PI when we change the parameter ki

wire [workingBitSize -1:0] setpoint_shifted;
fixedPointShifter#(inputBitSize, inputFracSize, workingBitSize, workingFracSize, 1) 
    shiftSetpoint(PI_setpoint, setpoint_shifted);
    
//PI controller on the distance
wire [workingBitSize -1:0] pi_out;
pi_controller#(
    .inputBitSize           (workingBitSize),
    .inputFracSize      (workingFracSize),
    .outputBitSize      (workingBitSize),
    .outputFracSize     (workingFracSize),
    .coeffBitSize           (coeffBitSize),
    .coeffFracSize      (coeffFracSize),
    .productFracSize    (workingBitSize-2)
)PI(
    .clk                        (clk),
    .reset                  (reset),
    .reset_pi               (PI_reset | singlePiReset),
    .enable_pi              (PI_enable),
    .pi_limiting            (PI_freeze),
    .pi_setpoint            (setpoint_shifted),
    .pi_input               (r),
    .pi_input_valid     (r_valid),
    .pi_kp_coefficient  (PI_kp_reg),
    .pi_ti_coefficient  (PI_ki_reg),
    .pi_output              (pi_out),
    .pi_output_valid        (retroactionController_valid)
);
wire [outputBitSize -1:0] unlimitedOut;
fixedPointShifter#(workingBitSize, workingFracSize, outputBitSize, outputFracSize, 1) 
    pi_out_to_unlimitedOut(pi_out, unlimitedOut);
     
     
assign retroactionController =  reset || PI_reset ? (
                                    0
                                ) : (
                                    PI_enable ? (
                                        $signed(unlimitedOut) > $signed(pi_limit_HI) ?
                                            pi_limit_HI :
                                            $signed(unlimitedOut) < $signed(pi_limit_LO) ?
                                                pi_limit_LO :
                                                unlimitedOut
                                    ) : (
                                        output_when_pi_disabled
												)
                                );
//parameter updates
always @(posedge clk)begin
    if(reset)begin
        PI_kp_reg <= 0;
        PI_ki_reg <= 0;
        singlePiReset <= 0;
    end else begin
        if(PI_kp_update)begin
            PI_kp_reg <= PI_kp;
        end
        if(PI_ki_update)begin
            PI_ki_reg <= PI_ki;
            singlePiReset <= !singlePiReset;
        end else begin
            singlePiReset <= 0;
        end
    end
end
    

    

fixedPointShifter#(workingBitSize, workingFracSize, outputBitSize, outputFracSize, 1) 
    r_to_ray(r, ray);

     
fixedPointShifter#(workingBitSize, workingFracSize, outputBitSize, outputFracSize, 0) 
    shift_xSquare(xSquare_untrimmed, xSquare);
fixedPointShifter#(workingBitSize, workingFracSize, outputBitSize, outputFracSize, 0) 
    shift_ySquare(ySquare_untrimmed, ySquare);
fixedPointShifter#(workingBitSize, workingFracSize, outputBitSize, outputFracSize, 0) 
    shift_zSquare(zSquare_untrimmed, zSquare);

    
//debug wires
    
assign leds[0] = retroactionController_valid;
assign leds[1] = PI_reset;
assign leds[2] = singlePiReset;
assign leds[3] = PI_enable;
endmodule