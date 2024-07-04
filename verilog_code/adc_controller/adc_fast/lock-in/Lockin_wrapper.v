// LEGACY MODE SCHEME
// ┌─────────┐  ┌─────────┐
// │ MIXER X │  │ MIXER Y │
// └────┬────┘  └────┬────┘
//      │            │
//  ┌───▼────────────▼───┐
//  │     AVERAGERs      │
//  └───┬────────────┬───┘
//      │            │
//  ┌───▼────────────▼───┐
//  │     CIC_WRAPPER    │
//  └───┬────────────┬───┘
//      │            │
//  ┌───▼────────────▼───┐
//  │      MA_WRAPPER    │
//  └───┬────────────┬───┘
//      │            │
//  ┌───▼────────────▼───┐
//  │     AVERAGERs      │
//  └───┬────────────┬───┘
//      │            │
// ┌────▼────┐  ┌────▼────┐
// │   FIFO  │  │   FIFO  │
// └─────────┘  └─────────┘
// IN CIRCLE BY CIRCLE MODE THE OUTPUTS OF THE MIXERS GO DIRECTLY TO THE LAST AVERAGERs

`include "CIC/CIC_wrapper.v"
`include "Moving_average/moving_average_wrapper.v"
`include "dual_averager_wrapper.v"

module Lockin_wrapper (
    input   clock,
    input   reset,

    input               ADC_acquire, //to start the lockin acquisition
    input signed [15:0] current_data, //current data for the lockin calculation
    
    // reference signals for the lockin demodulation
    input [15:0]    sin_ref_data,
    input [15:0]    cos_ref_data,

    // Legacy or circle by circle mode flag and parameters:
	input	        atommode_circle_nlegacy,
	input [15:0]    points_per_period, 
    input           points_per_period_update_cmd,
    input [7:0]     number_of_rotations,
    input           number_of_rotations_update_cmd,

    input [15:0]    CIC_decimation_rate,
    input           CIC_decimation_rate_update_cmd,
    input [15:0]    MA_length,
    input           MA_length_update_cmd,
    input [15:0]    MA_stages,
    input [31:0]    lockin_sum_points,
    input           lockin_sum_points_update_cmd,

    output          start_z_current_averaging, //signal to start the averaging of the current and the z
    output          reset_z_current_averaging, //signal to stop the averaging of the current and the z
    output [31:0]   integration_points, //integration points for the averaging of the current and Z (more or less equal to 50e6*control timestep, so 32 bit is more then enough)

    input           pi_enable, //flag if the pi is enabled (used for the latency calculation and to synchronize the parameter updated)
    output reg      wait_pi_coefficients, //flag to the PI_WRAPPER if it has to wait for the coefficient before considering the errors
    // FP errors
    output [63:0]   fp_error_x,
    output [63:0]   fp_error_y,
    output          fp_error_valid
);

// Latencies for the FP operations
localparam  FP_CONVERSION_LATENCY = 3,
            ADDITION_DELAY = 4,
            MULTIPLICATION_DELAY = 3,
            PI_CALCULATION_DELAY = 3*ADDITION_DELAY + 2*MULTIPLICATION_DELAY; //2 addition and 2 product in PI.v and one addition in DAC_offset.v

// delay for the cmds to update the parameters
reg number_of_rotations_update_cmd_reg, points_per_period_update_cmd_reg, MA_length_update_cmd_reg, lockin_sum_points_update_cmd_reg, CIC_decimation_rate_update_cmd_reg;
always @(posedge clock ) begin
    number_of_rotations_update_cmd_reg <= number_of_rotations_update_cmd;
    points_per_period_update_cmd_reg <= points_per_period_update_cmd;
    MA_length_update_cmd_reg <= MA_length_update_cmd;
    lockin_sum_points_update_cmd_reg <= lockin_sum_points_update_cmd;
    CIC_decimation_rate_update_cmd_reg <= CIC_decimation_rate_update_cmd;
end

/////////// FSM CONTROLLING THE LOCKIN ///////////////////
localparam  IDLE = 0,
            ACQUISITION = 1,
            PARAMETER_CHANGE = 2,
            WAIT_RESET = 3,
            ACQUISIION_END = 4;

reg [2:0] STATE;

wire parameter_change = number_of_rotations_update_cmd || points_per_period_update_cmd || MA_length_update_cmd || lockin_sum_points_update_cmd || CIC_decimation_rate_update_cmd;
reg lockin_acquire, reset_acquisition;

reg [7:0] number_of_rotations_reg;
reg [15:0] MA_length_reg, CIC_decimation_rate_reg;
reg [21:0] samples_per_rotation;
reg [31:0] lockin_sum_points_reg;
reg [50:0] integration_points_reg;

always @(posedge clock ) begin
    if (reset) begin
        STATE <= IDLE;
        lockin_acquire <= 1'b0;
        wait_pi_coefficients <= 1'b0;
        reset_acquisition <= 1'b0;
    end
    else begin
        case (STATE)
            IDLE: begin
                lockin_acquire <= 1'b0;
                if (parameter_change) begin //if there is a parameter change
                    STATE <= PARAMETER_CHANGE;
                end
                else if (ADC_acquire && MA_ready) begin //can start only if the MA is ready, otherwise it waits until the MA is ready
                    lockin_acquire <= 1'b1;
                    STATE <= ACQUISITION;
                end                
            end
            ACQUISITION: begin
                if (parameter_change) begin //if while acquiring the parameter changes stop the acquisition and change the parameter
                    lockin_acquire <= 1'b0;
                    STATE <= PARAMETER_CHANGE;
                end
                else if (!ADC_acquire) begin //if the ADC_acquire goes low stop the acquisition and reset it
                    lockin_acquire <= 1'b0;
                    reset_acquisition <= 1'b1;           
                    STATE <= WAIT_RESET;
                end
            end
            PARAMETER_CHANGE: begin //when a parameter changes reset all the blocks and update only the changed parameter
                reset_acquisition <= 1'b1; 
                wait_pi_coefficients <= ADC_acquire && pi_enable; //if the pi is enabled and there is an acquisition in progress disable the PI until the coefficient are received
                //for circle by circle mode
                if (number_of_rotations_update_cmd_reg)number_of_rotations_reg <= number_of_rotations;
                if (points_per_period_update_cmd_reg)samples_per_rotation <= 6'd36 * points_per_period;
                //for legacy mode
                if (lockin_sum_points_update_cmd_reg)lockin_sum_points_reg <= lockin_sum_points;
                if (MA_length_update_cmd_reg)MA_length_reg <= MA_length;
                if (CIC_decimation_rate_update_cmd_reg)CIC_decimation_rate_reg <= CIC_decimation_rate;
                if (lockin_sum_points_update_cmd_reg || CIC_decimation_rate_update_cmd_reg)integration_points_reg <= (lockin_sum_points*CIC_decimation_rate)<<3; //the factor 8 is for the initial averaging
                if (!parameter_change) begin //if there are two consecutive parameter changes stay in this state
                    STATE <= WAIT_RESET;
                end                
            end
            WAIT_RESET: begin
                reset_acquisition <= 1'b0;
                wait_pi_coefficients <= 1'b0;
                if (parameter_change) begin //if another parameter change occours while waiting there is another reset
                    STATE <= PARAMETER_CHANGE;
                end
                else begin
                    if (!ADC_acquire) begin //if there is no acquisition occuring return to idle
                        STATE <= IDLE;
                    end
                    if (ADC_acquire && MA_ready) begin  //otherwise wait for the reset (the slower is the MA) to be completed before starting the acquisition again
                        lockin_acquire <= 1'b1;
                        STATE <= ACQUISITION;
                    end
                end
            end
            default: begin
                lockin_acquire <= 1'b0;
                reset_acquisition <= 1'b1;
                wait_pi_coefficients <= 1'b0;            
                STATE <= WAIT_RESET;
            end
        endcase
    end
end

// Register the current because is coming from a different clock domain and so do with sin and current to keep latency coherent
reg signed [15:0] current_data_reg0, current_data_reg1;
reg signed [15:0] sin_ref_data_reg0, sin_ref_data_reg1;
reg signed [15:0] cos_ref_data_reg0, cos_ref_data_reg1;

always @(posedge clock ) begin
	current_data_reg0 <= current_data;
	current_data_reg1 <= current_data_reg0;
    sin_ref_data_reg0 <= sin_ref_data;
	sin_ref_data_reg1 <= sin_ref_data_reg0;
    cos_ref_data_reg0 <= cos_ref_data;
	cos_ref_data_reg1 <= cos_ref_data_reg0;
end

///////////// LOCK-IN //////////////

// Initial mixing
reg signed [31:0] channel_x_mixed, channel_y_mixed;
reg mixed_data_valid;

always @(posedge clock) begin
    channel_x_mixed <= current_data_reg1 * sin_ref_data_reg1;
    channel_y_mixed <= current_data_reg1 * cos_ref_data_reg1;
end

wire [31:0] averaged_x, averaged_y;
wire average_valid;

// Initial averaging by a fixed factor of 8 with shift (so data lenght is the same)
dual_averager_wrapper #(
    .INPUT_DATA_BITS(32),
    .AVERAGING_POINTS_BITS(8),
    .SIGNED(1)
) average_initial (
	.clock(clock),
	.reset(reset || reset_acquisition),
	.shift(1'b1),
	.averaging_points(8),  //Value fixed to 8 from previous software
    
	.data_in_1(channel_x_mixed),
    .data_in_2(channel_y_mixed),
	.run_averaging(lockin_acquire),

	.data_out_1(averaged_x),
    .data_out_2(averaged_y),
	.data_valid(average_valid)
);

wire [31:0] CIC_output_x, CIC_output_y;
wire CIC_output_valid;

// CIC
CIC_wrapper CIC_wrapper_0 ( //The wrapper compensate the processing gain so the number of bits stays the same
    .clock(clock),
    .reset(reset || reset_acquisition),
    .CIC_decimation_rate(CIC_decimation_rate_reg),

    .averaged_x(averaged_x),
    .averaged_y(averaged_y),
    .average_valid(average_valid),

    .CIC_output_x(CIC_output_x),
    .CIC_output_y(CIC_output_y),
    .CIC_output_valid(CIC_output_valid)
) ;

/////// Moving average ////////////
wire MA_ready;
wire [73:0] moving_average_x_out, moving_average_y_out;
wire moving_average_dataout_valid;
//Multiplexers
wire [9:0] moving_average_length = atommode_circle_nlegacy? {2'b00 , number_of_rotations_reg} : MA_length_reg[9:0];
wire [63:0] moving_average_x_in = atommode_circle_nlegacy? final_average_x_out[63:0] : {{32{CIC_output_x[31]}},CIC_output_x};
wire [63:0] moving_average_y_in = atommode_circle_nlegacy? final_average_y_out[63:0] : {{32{CIC_output_y[31]}},CIC_output_y};
wire moving_average_datain_valid = atommode_circle_nlegacy? final_average_dataout_valid : CIC_output_valid;
//Moving average
moving_average_wrapper #( //the output bit has to be greater than INPUT_DATA_BITS+log2(MAX_DECIMATION)*MAX_CASCADED_MAs
    .MAX_DECIMATION(1024),
    .INPUT_DATA_BITS(64),
    .OUTPUT_DATA_BITS(74),
    .MAX_CASCADED_MAs(1),
    .SIGNED(1)
)moving_average (
    .clock(clock),
    .reset(reset || reset_acquisition),
    .ready (MA_ready), //the shift register implement a smart reset, which avoids to reset the ram if it was not used since the last reset

    .length_moving_average(moving_average_length),
    .order_rolloff(MA_stages),  //single stage moving average (deprecated multiple stages implementation)

    .data_in_x(moving_average_x_in),
    .data_in_y(moving_average_y_in),
    .data_in_valid(moving_average_datain_valid),
    
    .data_out_x(moving_average_x_out),
    .data_out_y(moving_average_y_out),
    .data_out_valid(moving_average_dataout_valid)
);

/////// Final averaging ////////////
wire [73:0] final_average_x_out, final_average_y_out;
wire final_average_dataout_valid;
//Multiplexers
wire [31:0] final_average_points = atommode_circle_nlegacy? samples_per_rotation : lockin_sum_points_reg;
wire [63:0] final_average_x_in = atommode_circle_nlegacy? {{32{channel_x_mixed[31]}},channel_x_mixed} : moving_average_x_out[63:0];
wire [63:0] final_average_y_in = atommode_circle_nlegacy? {{32{channel_y_mixed[31]}},channel_y_mixed} : moving_average_y_out[63:0];
wire final_average_datain_valid = atommode_circle_nlegacy? lockin_acquire : moving_average_dataout_valid;
//Averager
dual_averager_wrapper #(
    .INPUT_DATA_BITS(42),
    .AVERAGING_POINTS_BITS(32),
    .SIGNED(1)
) average_final (
	.clock(clock),
	.reset(reset || reset_acquisition),
	.shift(0),
	.averaging_points(final_average_points),
    
	.data_in_1(final_average_x_in),
    .data_in_2(final_average_y_in),
	.run_averaging(final_average_datain_valid),

	.data_out_1(final_average_x_out),
    .data_out_2(final_average_y_out),
	.data_valid(final_average_dataout_valid)
);

/////// Floating point conversion  ////////////
wire [73:0] fp_conversion_x_in = atommode_circle_nlegacy? moving_average_x_out : final_average_x_out;
wire [73:0] fp_conversion_y_in = atommode_circle_nlegacy? moving_average_y_out : final_average_y_out;
wire fp_conversion_datain_valid = atommode_circle_nlegacy? moving_average_dataout_valid : (final_average_dataout_valid && fp_conversion_en);
FP_fixed74_to_double fp_conversion_1 (
    .clk    (clock),    //    clk.clk
    .areset (reset), // areset.reset
    .a      (fp_conversion_x_in),      //      a.a
    .q      (fp_error_x)       //      q.q
);
FP_fixed74_to_double fp_conversion_2 (
    .clk    (clock),    //    clk.clk
    .areset (reset), // areset.reset
    .a      (fp_conversion_y_in),      //      a.a
    .q      (fp_error_y)       //      q.q
);
wire fp_conversion_valid;
shift_register_delayer #(
    .MAX_LENGTH(4)
) shift_register_fp_conversion (
    .clock (clock),
    .reset (reset || reset_acquisition),
    .enable (1'b1),
    .length (FP_CONVERSION_LATENCY),
    .data_in(fp_conversion_datain_valid),
    .data_out(fp_conversion_valid)
);
 
assign fp_error_valid = fp_conversion_valid;

//FIFO_WR enable logic and SYNC with the ADC_data_adder
//In legacy mode discard the first 5 errors (due to CIC initialization) and extra logic to synchronize the start of the z and current averaging, so the fifo are written togheter
reg fp_conversion_en; //flag to enable the write in the fifo
reg [4:0] fp_conversion_en_counter; 
reg start_z_current_averaging_legacy_reg, enable_z_current_averaging_reg; //register to synchronize the start of the z and current averaging, both are kept high during acquisition
wire start_z_current_averaging_legacy = (final_average_dataout_valid || start_z_current_averaging_legacy_reg) && enable_z_current_averaging_reg;

always @(posedge clock ) begin
    if (reset || reset_acquisition) begin
        fp_conversion_en <= 1'b0;
        fp_conversion_en_counter <= 0;
        enable_z_current_averaging_reg <= 1'b0;
        start_z_current_averaging_legacy_reg <= 1'b0;
    end
    else begin
        if (final_average_dataout_valid && fp_conversion_en_counter < 4) begin
            fp_conversion_en_counter <= fp_conversion_en_counter + 1'b1;
        end
        if (fp_conversion_en_counter == 4) begin
            enable_z_current_averaging_reg <= 1'b1; //this is needed to bring start_z_current_averaging high when final_average_dataout_valid goes high
        end
        if (final_average_dataout_valid && fp_conversion_en_counter == 4) begin
            fp_conversion_en <= 1'b1;
            start_z_current_averaging_legacy_reg <= 1'b1;       
        end
    end
end
//in circle by circle mode the synchronization is easily achieved using the same "run_averaging" in the lockin and in ADC_data_adder

//////////// MULTIPLEXING Z and current averaging parameters //////////////
// integration points
assign integration_points = atommode_circle_nlegacy? {{10{1'b0}},samples_per_rotation} : integration_points_reg[31:0]; //(in legacy mode more or less equal to 50e6*control timestep, so 32 bit is more then enough)

//start signal
reg start_z_current_averaging_circle; //to account for the moving average delay added when in circle by circle mode
always @(posedge clock) begin
    start_z_current_averaging_circle <= lockin_acquire;
end

wire start_z_current_averaging_with_error = atommode_circle_nlegacy? start_z_current_averaging_circle : start_z_current_averaging_legacy;
wire start_z_current_averaging_with_offset;

shift_register_delayer #( //delayer to use if the FPGA PI is enabled
    .MAX_LENGTH(32)
) shift_register_start_signal (
    .clock (clock),
    .reset (reset || reset_acquisition),
    .enable (1'b1),
    .length (PI_CALCULATION_DELAY),
    .data_in(start_z_current_averaging_with_error),
    .data_out(start_z_current_averaging_with_offset)
);

assign start_z_current_averaging = pi_enable? start_z_current_averaging_with_offset : start_z_current_averaging_with_error;

//reset signals, used especially for parameter changes
assign reset_z_current_averaging = reset_acquisition;

endmodule