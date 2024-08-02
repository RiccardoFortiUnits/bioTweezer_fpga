module pi_controller#(
  parameter inputBitSize = 27,
  parameter inputFracSize = 25,
  parameter outputBitSize = 16,
  parameter outputFracSize = 15,
  parameter coeffBitSize = 27,
  parameter coeffFracSize = 26,
  parameter productFracSize = 27
)(
    input clk,
    input reset,

    input reset_pi,
    input enable_pi,

    input pi_limiting,

    input signed [inputBitSize-1:0] pi_setpoint,    // Q2.25
    input signed [inputBitSize-1:0] pi_input, // Q2.25
    input                       pi_input_valid,

    input signed [coeffBitSize-1:0] pi_kp_coefficient, // Q1.26
    input signed [coeffBitSize-1:0] pi_ti_coefficient, // Q1.26 

    output [outputBitSize-1:0] pi_output,
    output reg    pi_output_valid
);

localparam  inputWholeSize = inputBitSize - inputFracSize,
            outputWholeSize = outputBitSize - outputFracSize,
            coeffWholeSize = coeffBitSize - coeffFracSize,
            errorBitSize = inputBitSize + 1,
            errorWholeSize = inputWholeSize + 1,
            errorFracSize = inputFracSize,
            productWholeSize = errorWholeSize + coeffWholeSize,
            productBitSize = productWholeSize + productFracSize,
            saturationStuffingBits = 2,// +1 would be enough...
            saturationWholeSize = (outputWholeSize > productWholeSize ? outputWholeSize : productWholeSize)+ saturationStuffingBits,
            saturationFracSize = productFracSize,
            saturationBitSize = productFracSize + saturationFracSize,
            saturatedWholeSize = saturationWholeSize - saturationStuffingBits,
            saturatedFracSize = saturationFracSize,
            saturatedBitSize = saturatedFracSize + saturatedWholeSize;

//delay clocks for each segment of the pipeline
localparam ERROR_COMPUTATION_DELAY          = 1,
           MULTIPLICATION_ERROR_KP_DELAY    = 2,
           MULTIPLICATION_ERROR_KP_TI_DELAY = 2,
           INTEGRAL_ADDITION_DELAY          = 1,
           PI_OUTPUT_ADDITION_DELAY         = 1,
           INTEGRAL_COMPONENT_DELAY         = ERROR_COMPUTATION_DELAY + MULTIPLICATION_ERROR_KP_DELAY + MULTIPLICATION_ERROR_KP_TI_DELAY + INTEGRAL_ADDITION_DELAY,
           PI_OUTPUT_DELAY                  = PI_OUTPUT_ADDITION_DELAY + INTEGRAL_COMPONENT_DELAY;

localparam IDLE = 0,
           RUNNING = 1;

reg [2:0] STATE;
reg [3:0] counter;//counts how many cycles have passed since the last reset, used to indicate when the output is valid after the reset
reg save_integral_component_pi;

//----------------------------------------------------------------
// reset and output validation

always @(posedge clk) 
begin
    if (reset || reset_pi)
    begin
        pi_output_valid <= 1'b0;
        save_integral_component_pi <= 1'b0;
        counter <= 4'd0;
        STATE <= IDLE;
    end
    else
    begin
        case (STATE)
            IDLE:
            begin
                save_integral_component_pi <= 1'b0;
                pi_output_valid <= 1'b0;
                if (pi_input_valid && enable_pi)
                begin
                    counter <= 4'd0;
                    STATE <= RUNNING;
                end
            end

            RUNNING:
            begin
           //avoid counter overflow
                if(~(&counter))
                begin
                    counter <= counter + 1'd1;
                end

                if (counter >= PI_OUTPUT_DELAY - 1) 
                begin
                    pi_output_valid <= enable_pi; 
                end
                if (counter >= INTEGRAL_COMPONENT_DELAY - 1) 
                begin
                    save_integral_component_pi <= 1'b1; 
                end

                if(!enable_pi || !pi_input_valid)
                begin
                    STATE <= IDLE;
                end
            end

        endcase
    end
end

//----------------------------------------------------------------

//----------------------------------------------------------------
// pi ERROR COMPUTATION
wire signed [errorBitSize-1:0] setpoint_extended;
wire signed [errorBitSize-1:0] input_extended;
fixedPointShifter#(inputBitSize, inputFracSize, errorBitSize, errorFracSize) extendSetpoint
    (pi_setpoint, setpoint_extended);
fixedPointShifter#(inputBitSize, inputFracSize, errorBitSize, errorFracSize) extendInput
    (pi_input, input_extended);

wire signed [errorBitSize-1:0] error;       // Q3.25

// assign error = setpoint_extended - input_extended
adder#(
  .WIDTH      (errorBitSize),
  .isSubtraction  (1)
)errorSubtracter(
  .clk    (clk),
  .reset    (reset || reset_pi),
  .a      (setpoint_extended),
  .b      (input_extended),
  .result   (error)
);
  
//----------------------------------------------------------------

//----------------------------------------------------------------
// pi P COMPONENT COMPUTATION
wire signed [productBitSize-1:0] kpXerror;

// assign kpXerror = error * pi_kp_coefficient;
clocked_FractionalMultiplier#(
  .A_WIDTH          (errorBitSize),
  .B_WIDTH          (coeffBitSize),
  .OUTPUT_WIDTH     (productBitSize),
  .FRAC_BITS_A      (errorFracSize),
  .FRAC_BITS_B      (coeffFracSize),
  .FRAC_BITS_OUT      (productFracSize)
) error_kp_pi_mult_0_am (
  .clk(clk),    
  .reset(reset || reset_pi),
  .a(error),
  .b(pi_kp_coefficient),
  .result(kpXerror)
);

//----------------------------------------------------------------

//----------------------------------------------------------------
// pi I PRODUCT COMPUTATION
wire signed [productBitSize-1:0] kiXkpXerror;
wire signed [saturationBitSize-1:0] kiXkpXerror_extended; // Q14.51

//assign kiXkpXerror = kpXerror * pi_ti_coefficient;
clocked_FractionalMultiplier#(
  .A_WIDTH          (productBitSize),
  .B_WIDTH          (coeffBitSize),
  .OUTPUT_WIDTH     (productBitSize),
  .FRAC_BITS_A      (productFracSize),
  .FRAC_BITS_B      (coeffFracSize),
  .FRAC_BITS_OUT      (productFracSize)
) error_ti_pi_mult_0_am (
  .clk(clk),    
  .reset(reset || reset_pi),
  .a(kpXerror),
  .b(pi_ti_coefficient),
  .result(kiXkpXerror)
);

fixedPointShifter#(productBitSize, productFracSize, saturationBitSize, saturationFracSize) extendkiXkpXerror
    (kiXkpXerror, kiXkpXerror_extended);

//----------------------------------------------------------------

//----------------------------------------------------------------
// pi I COMPONENT DELAY
wire signed [saturationBitSize-1:0] integralSum_cleaned;
reg signed [saturationBitSize-1:0] integralSum_delayed;

always @(posedge clk) 
begin
    if (reset || reset_pi)
    begin
        integralSum_delayed <= 0;
    end
    else
    begin
        integralSum_delayed <= integralSum_cleaned;
    end
end
//----------------------------------------------------------------

//----------------------------------------------------------------
// pi I COMPONENT COMPUTATION

wire signed [saturationBitSize-1:0] integralSum;

adder#(
  .WIDTH      (saturationBitSize),
  .isSubtraction  (0)
)integralAdder(
  .clk    (clk),
  .reset    (reset || reset_pi),
  .a      (kiXkpXerror_extended),
  .b      (integralSum_cleaned),
  .result   (integralSum)
);

assign integralSum_cleaned = save_integral_component_pi && (pi_limiting || reset || reset_pi) ?
                                integralSum_delayed :
                                integralSum;

wire signed [saturationBitSize-1:0] integralPart;

saturator #(
  .inputWidth     (saturationBitSize),
  .outputMaxWidth (saturatedBitSize)
)integralSaturation(
  .input_data         (integralSum_cleaned),
  .saturated_output   (integralPart),
  .is_saturated       ()
);
//----------------------------------------------------------------

//----------------------------------------------------------------
// pi I OUTPUT COMPUTATION
wire signed [saturationBitSize-1:0] pi_output_sum; // Q5.50
wire signed [saturationBitSize-1:0] proportionalPart;

fixedPointShifter#(productBitSize, productFracSize, saturationBitSize, saturationFracSize) extendkpXerror
    (kpXerror, proportionalPart);

// assign pi_output_sum = proportionalPart + integralPart
adder#(
  .WIDTH      (saturationBitSize),
  .isSubtraction  (0)
)outputSum(
  .clk    (clk),
  .reset    (reset || reset_pi),
  .a      (proportionalPart),
  .b      (integralPart),
  .result   (pi_output_sum)
);


fixedPointShifter#(saturationBitSize, saturationFracSize, outputBitSize, outputFracSize) saturateOutput
    (pi_output_sum, pi_output);

//----------------------------------------------------------------

endmodule