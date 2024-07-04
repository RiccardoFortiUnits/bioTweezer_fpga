module meta_decoder#(parameter DEFAULT_UDP_PAYLOAD = 16'd3958) //(4000-42)
(
    input	clk,
    input   reset,
    input   DAC_stopped,

    // ATOM/FAST MODE SELECTION //
    input   atom_nFast,
    input   atommode_circle_nlegacy,
    output  meta_FastSTM_written,    
    output  meta_Atom_written,
    output  meta_PI_coefficient_written,

    // DATA from/to THE DECODER //
    input [31:0]    received_data,
    input           received_data_valid,
    input           wipe_settings,
    output reg      ack,
    output reg      nak,
    output reg      err,

    // FASTSTM DATA //
    output reg [15:0]   points_per_period,
    output reg          points_per_period_update_cmd,
    //output reg [15:0]   Byte_UDP_packet,

    output reg [31:0]   Y_increment_step,
    output reg          Y_update_increment_step_cmd,
    output reg [15:0]   SIN_increment_step,
    output reg          SIN_update_increment_step_cmd,
    output reg          X_update_phase_cmd,
    output reg [15:0]   X_phase,
    output reg [15:0]   X_ampl,
    output reg          Z_update_phase_cmd,
    output reg [15:0]   Z_phase,
    output reg [15:0]   rotation_sin,
    output reg [15:0]   rotation_cos,
    output reg          rotation_update_cmd,
    output reg          Z_update_scale_factor_cmd,
    output reg [15:0]   Z_scale_factor,
    output reg [15:0]   X_pixel,
    output reg [15:0]   Y_pixel,
    output reg [15:0]   X_ampl_scaling,
    output reg          X_update_ampl_scaling_cmd,

    // ATOM TRACKING DATA //
    output reg [15:0]   Y_ampl_scaling,    
    output reg          Y_update_ampl_scaling_cmd,
    output reg          Y_update_phase_cmd,
    output reg [15:0]   Y_phase,
    output reg [15:0]   Y_ampl,

    output reg          lockin_update_phase_cmd,
    output reg [15:0]   lockin_phase,
    output reg          lockin_update_CIC_decimation_rate_cmd,   
    output reg [15:0]   lockin_CIC_decimation_rate,   
    output reg [15:0]   lockin_MA_length,
    output reg          lockin_MA_length_update_cmd,
    output reg [15:0]   lockin_MA_stages,
    output reg [31:0]   lockin_sum_points,
    output reg          lockin_sum_points_update_cmd,
    output reg [7:0]    number_of_rotations,
    output reg          number_of_rotations_update_cmd,

    // COEFFICIENT for PI
    output reg [63:0]   PI_coefficient_1,
    output reg          PI_coefficient_1_update_cmd,
    output reg [63:0]   PI_coefficient_2,
    output reg          PI_coefficient_2_update_cmd,

    // OFFSET in double
    output reg [63:0]   offset_X_double,
    output reg          offset_X_double_update_cmd,
    output reg [63:0]   offset_Y_double,
    output reg          offset_Y_double_update_cmd,

        //input data for the pattern
    output reg [23:0]   pattern_increment_step_x, //offset increment step in Q1.23 format
    output reg          update_pattern_increment_step_x_cmd,
    output reg [23:0]   pattern_increment_step_y, //offset increment step in Q1.23 format
    output reg          update_pattern_increment_step_y_cmd,
    output reg [23:0]   pattern_step_count_x, //number of steps to take
    output reg          update_pattern_step_count_x_cmd,
    output reg [23:0]   pattern_step_count_y, //number of steps to take
    output reg          update_pattern_step_count_y_cmd
);

// META COMMANDS CODEs:
localparam  Y_INC_MSB = 8'h01,
            Y_INC_LSB = 8'h02,
            X_PHASE = 8'h04,
            X_AMPL = 8'h08,
            Z_PHASE = 8'h10,
            Z_SCALE_FACTOR = 8'h20,
            POINTS_PERIOD = 8'h40,
            PIXEL_X = 8'h80,
            PIXEL_Y = 8'h11,
            BYTE_PACKET = 8'h12,
            X_AMPL_SCALING = 8'h14,
            Y_AMPL_SCALING = 8'h18,            
            Y_PHASE = 8'h21,
            Y_AMPL = 8'h22,
            INT_POINT_MSB = 8'h24,
            INT_POINT_LSB = 8'h25,
            LOCKIN_PHASE = 8'h28,
            LOCKIN_CIC_DEC = 8'h32,
            LOCKIN_MA_LEN = 8'h34,
            LOCKIN_MA_STAGES = 8'h38,
            LOCKIN_SUM_POINTS_MSB = 8'h41,
            LOCKIN_SUM_POINTS_LSB = 8'h42,
            ROTATION_COS = 8'h44,
            ROTATION_SIN = 8'h45,
            NUMBER_OF_ROTATIONS = 8'h48,
            PI_COEFF_1_MSB = 8'h50,
            PI_COEFF_1_CSB = 8'h51,
            PI_COEFF_1_LSB = 8'h52,
            PI_COEFF_2_MSB = 8'h54,
            PI_COEFF_2_CSB = 8'h55,
            PI_COEFF_2_LSB = 8'h56,
            X_OFFSET_MSB = 8'h60,
            X_OFFSET_CSB = 8'h61,
            X_OFFSET_LSB = 8'h62,
            Y_OFFSET_MSB = 8'h64,
            Y_OFFSET_CSB = 8'h65,
            Y_OFFSET_LSB = 8'h66,
            PAT_INC_X = 8'h70,
            PAT_COUNT_X = 8'h71,
            PAT_INC_Y = 8'h72,
            PAT_COUNT_Y = 8'h73;

// STATE MACHINE
localparam  IDLE = 0,
            EVAL = 1;

// registers for FAST mode
reg Y_INC_MSB_written, Y_INC_LSB_written, X_PHASE_written, X_AMPL_written, Z_PHASE_written, Z_SCALE_FACTOR_written, POINTS_PERIOD_written, PIXEL_X_written, PIXEL_Y_written, X_AMPL_SCALING_written;
assign meta_FastSTM_written = Y_INC_MSB_written & Y_INC_LSB_written & X_AMPL_written & PIXEL_Y_written & X_AMPL_SCALING_written;
reg Y_update_increment_step_MSB_cmd, Y_update_increment_step_LSB_cmd, rotation_update_sin_cmd, rotation_update_cos_cmd, SIN_update_increment_step_cmd_temp;

// registers for ATOM mode
reg Y_AMPL_SCALING_written, Y_PHASE_written, Y_AMPL_written, LOCKIN_PHASE_written, LOCKIN_CIC_DEC_written, LOCKIN_MA_LEN_written, LOCKIN_MA_STAGES_written, LOCKIN_SUM_POINTS_MSB_written, LOCKIN_SUM_POINTS_LSB_written, NUMBER_OF_ROTATIONS_written;
wire meta_Atom_circle_legacy_written = atommode_circle_nlegacy? (NUMBER_OF_ROTATIONS_written & LOCKIN_MA_LEN_written) : (LOCKIN_CIC_DEC_written & LOCKIN_MA_LEN_written & LOCKIN_SUM_POINTS_LSB_written);
assign meta_Atom_written = X_AMPL_written & X_AMPL_SCALING_written & Y_AMPL_SCALING_written & Y_PHASE_written & Y_AMPL_written & meta_Atom_circle_legacy_written;
reg lockin_sum_points_update_MSB_cmd, lockin_sum_points_update_LSB_cmd;

//registers for PI
reg PI_coefficient_1_MSB_written, PI_coefficient_1_CSB_written, PI_coefficient_1_LSB_written,  PI_coefficient_2_MSB_written, PI_coefficient_2_CSB_written, PI_coefficient_2_LSB_written;
reg PI_coefficient_1_MSB_update_cmd, PI_coefficient_1_CSB_update_cmd, PI_coefficient_1_LSB_update_cmd,  PI_coefficient_2_MSB_update_cmd, PI_coefficient_2_CSB_update_cmd, PI_coefficient_2_LSB_update_cmd;
assign meta_PI_coefficient_written = PI_coefficient_1_MSB_written && PI_coefficient_1_CSB_written && PI_coefficient_1_LSB_written && PI_coefficient_2_MSB_written && PI_coefficient_2_CSB_written && PI_coefficient_2_LSB_written;

//registers for double offsets
reg offset_X_double_MSB_update_cmd, offset_X_double_CSB_update_cmd, offset_X_double_LSB_update_cmd,  offset_Y_double_MSB_update_cmd, offset_Y_double_CSB_update_cmd, offset_Y_double_LSB_update_cmd;

reg [2:0] STATE = IDLE;

// META COMMANDS DECODING AND RESET
always @(posedge clk ) begin
    if (reset || wipe_settings) begin        
        points_per_period <= 0;
        Y_increment_step <= 0;
        X_phase <= 0;
        X_ampl <= 0;
        Z_phase <= 0;
        Z_scale_factor <= 0;
        X_pixel <= 0;
        Y_pixel <= 0;
        X_ampl_scaling <= 0;
        //Byte_UDP_packet <= DEFAULT_UDP_PAYLOAD;
        Y_ampl_scaling <= 0;
        Y_phase <= 0;
        Y_ampl <= 0;
        lockin_phase <= 0;  
        lockin_CIC_decimation_rate <= 0;    
        lockin_MA_length <= 0;   
        lockin_MA_stages <= 1;
        lockin_sum_points <= 0;
        number_of_rotations <= 8'd1;
        rotation_cos <= 16'h4000;
        rotation_cos <= 16'h0000;
        PI_coefficient_1 <= 0;
        PI_coefficient_2 <= 0;

        Y_INC_MSB_written <= 0;
        Y_INC_LSB_written <= 0;
        X_PHASE_written <= 0;
        X_AMPL_written <= 0;
        Z_PHASE_written <= 0;
        Z_SCALE_FACTOR_written <= 0;
        POINTS_PERIOD_written <= 0;
        PIXEL_X_written <= 0;
        PIXEL_Y_written <= 0;
        X_AMPL_SCALING_written <= 0;
        Y_AMPL_SCALING_written <= 0;
        Y_PHASE_written <= 0;
        Y_AMPL_written <= 0;
        LOCKIN_PHASE_written <= 0;
        LOCKIN_CIC_DEC_written <= 0;
        LOCKIN_MA_LEN_written <= 0;
        LOCKIN_MA_STAGES_written <= 0;
        NUMBER_OF_ROTATIONS_written <= 0;

        X_update_phase_cmd <= 0;
        Z_update_phase_cmd <= 0;
        Z_update_scale_factor_cmd <= 0;
        points_per_period_update_cmd <= 0;
        Y_update_phase_cmd <= 0;
        lockin_update_phase_cmd <= 0;
        lockin_update_CIC_decimation_rate_cmd <= 0;
        lockin_MA_length_update_cmd <= 0;
        X_update_ampl_scaling_cmd <= 0;
        Y_update_ampl_scaling_cmd <= 0;
        Y_update_increment_step_LSB_cmd <= 0;
        Y_update_increment_step_MSB_cmd <= 0;
        Y_update_increment_step_cmd <= 0;
        SIN_update_increment_step_cmd_temp <= 0;
        rotation_update_sin_cmd <= 0;
        rotation_update_cos_cmd <= 0;
        rotation_update_cmd <= 0;
        lockin_sum_points_update_cmd <= 0;
        lockin_sum_points_update_MSB_cmd <= 0;
        lockin_sum_points_update_LSB_cmd <= 0;
        number_of_rotations_update_cmd <= 0;

        PI_coefficient_1_MSB_written <= 0;
        PI_coefficient_1_CSB_written <= 0;
        PI_coefficient_1_LSB_written <= 0;
        PI_coefficient_2_MSB_written <= 0;
        PI_coefficient_2_CSB_written <= 0;
        PI_coefficient_2_LSB_written <= 0;
        PI_coefficient_1_MSB_update_cmd <= 0;
        PI_coefficient_1_CSB_update_cmd <= 0;
        PI_coefficient_1_LSB_update_cmd <= 0;
        PI_coefficient_2_MSB_update_cmd <= 0;
        PI_coefficient_2_CSB_update_cmd <= 0;
        PI_coefficient_2_LSB_update_cmd <= 0;
        PI_coefficient_1_update_cmd <= 0;
        PI_coefficient_2_update_cmd <= 0;

        offset_X_double_MSB_update_cmd <= 0;
        offset_X_double_CSB_update_cmd <= 0;
        offset_X_double_LSB_update_cmd <= 0;
        offset_Y_double_MSB_update_cmd <= 0;
        offset_Y_double_CSB_update_cmd <= 0;
        offset_Y_double_LSB_update_cmd <= 0;

        pattern_increment_step_x <= 0;
        update_pattern_increment_step_x_cmd <= 0;
        pattern_increment_step_y <= 0;
        update_pattern_increment_step_y_cmd <= 0;
        pattern_step_count_x <= 0;
        update_pattern_step_count_x_cmd <= 0;
        pattern_step_count_y <= 0;
        update_pattern_step_count_y_cmd <= 0;

        STATE <= IDLE;  
    end
    else begin
        case (STATE)
            IDLE: begin
                X_update_phase_cmd <= 0;
                Z_update_phase_cmd <= 0;
                Z_update_scale_factor_cmd <= 0;
                points_per_period_update_cmd <= 0;
                Y_update_phase_cmd <= 0;
                SIN_update_increment_step_cmd_temp <= 0;
                lockin_update_phase_cmd <= 0;
                lockin_update_CIC_decimation_rate_cmd <= 0;
                lockin_MA_length_update_cmd <= 0;
                X_update_ampl_scaling_cmd <= 0;
                Y_update_ampl_scaling_cmd <= 0;
                number_of_rotations_update_cmd <= 0;
                update_pattern_increment_step_x_cmd <= 0;
                update_pattern_increment_step_y_cmd <= 0;
                update_pattern_step_count_x_cmd <= 0;
                update_pattern_step_count_y_cmd <= 0;

                if (Y_update_increment_step_MSB_cmd && Y_update_increment_step_LSB_cmd) begin
                    Y_update_increment_step_cmd <= 1'b1;
                    Y_update_increment_step_LSB_cmd <= 0;
                    Y_update_increment_step_MSB_cmd <= 0;
                end
                else Y_update_increment_step_cmd <= 1'b0;

                if (rotation_update_sin_cmd && rotation_update_cos_cmd) begin
                    rotation_update_cmd <= 1'b1;
                    rotation_update_sin_cmd <= 1'b0;
                    rotation_update_cos_cmd <= 1'b0;
                end
                else rotation_update_cmd <= 1'b0;

                if (lockin_sum_points_update_MSB_cmd && lockin_sum_points_update_LSB_cmd) begin
                    lockin_sum_points_update_cmd <= 1'b1;
                    lockin_sum_points_update_MSB_cmd <= 1'b0;
                    lockin_sum_points_update_LSB_cmd <= 1'b0;
                end  
                else lockin_sum_points_update_cmd <= 1'b0;

                if (PI_coefficient_1_MSB_update_cmd && PI_coefficient_1_CSB_update_cmd && PI_coefficient_1_LSB_update_cmd) begin
                    PI_coefficient_1_MSB_update_cmd <= 1'b0;
                    PI_coefficient_1_CSB_update_cmd <= 1'b0;
                    PI_coefficient_1_LSB_update_cmd <= 1'b0;
                    PI_coefficient_1_update_cmd <= 1'b1;
                end
                else PI_coefficient_1_update_cmd <= 1'b0;

                if (PI_coefficient_2_MSB_update_cmd && PI_coefficient_2_CSB_update_cmd && PI_coefficient_2_LSB_update_cmd) begin
                    PI_coefficient_2_MSB_update_cmd <= 1'b0;
                    PI_coefficient_2_CSB_update_cmd <= 1'b0;
                    PI_coefficient_2_LSB_update_cmd <= 1'b0;
                    PI_coefficient_2_update_cmd <= 1'b1;
                end
                else PI_coefficient_2_update_cmd <= 1'b0;

                if (offset_X_double_MSB_update_cmd && offset_X_double_CSB_update_cmd && offset_X_double_LSB_update_cmd) begin
                    offset_X_double_MSB_update_cmd <= 1'b0;
                    offset_X_double_CSB_update_cmd <= 1'b0;
                    offset_X_double_LSB_update_cmd <= 1'b0;
                    offset_X_double_update_cmd <= 1'b1;
                end
                else offset_X_double_update_cmd <= 1'b0;

                if (offset_Y_double_MSB_update_cmd && offset_Y_double_CSB_update_cmd && offset_Y_double_LSB_update_cmd) begin
                    offset_Y_double_MSB_update_cmd <= 1'b0;
                    offset_Y_double_CSB_update_cmd <= 1'b0;
                    offset_Y_double_LSB_update_cmd <= 1'b0;
                    offset_Y_double_update_cmd <= 1'b1;
                end
                else offset_Y_double_update_cmd <= 1'b0;
                
                ack <= 1'b0;
                nak <= 1'b0;
                err <= 1'b0;

                if (received_data_valid) begin
                    STATE <= EVAL;
                end
            end

            EVAL: begin
                STATE <= IDLE;
                case (received_data[31 -: 8])
                    Y_INC_MSB: begin
                        Y_increment_step[31-:16] <= received_data[15:0];
                        Y_update_increment_step_MSB_cmd <= 1'b1;
                        Y_INC_MSB_written <= 1'b1;
                        ack <= 1'b1;
                    end
                    Y_INC_LSB: begin
                        Y_increment_step[15:0] <= received_data[15:0];
                        Y_update_increment_step_LSB_cmd <= 1'b1;
                        Y_INC_LSB_written <= 1'b1;
                        ack <= 1'b1;
                    end
                    X_PHASE: begin
                        X_phase[15:0] <= received_data[15:0];
                        X_update_phase_cmd <= 1'b1; 
                        X_PHASE_written <= 1'b1;
                        ack <= 1'b1;
                    end
                    X_AMPL: begin
                        X_ampl[15:0] <= received_data[15:0];
                        X_AMPL_written <= 1'b1;                        
                        SIN_update_increment_step_cmd_temp <= 1'b1;
                        ack <= 1'b1;
                    end
                    Z_PHASE: begin
                        Z_phase[15:0] <= received_data[15:0];
                        Z_update_phase_cmd <= 1'b1;
                        Z_PHASE_written <= 1'b1;
                        ack <= 1'b1;
                    end
                    Z_SCALE_FACTOR: begin
                        Z_scale_factor[15:0] <= received_data[15:0];
                        Z_update_scale_factor_cmd <= 1'b1;
                        Z_SCALE_FACTOR_written <= 1'b1;
                        ack <= 1'b1;
                    end
                    POINTS_PERIOD: begin
                        if(DAC_stopped && received_data[15:0] != 16'd0 && received_data[15:0] <= 16'd8192) begin
                            points_per_period[15:0] <= received_data[15:0];
                            points_per_period_update_cmd <= 1'b1;
                            POINTS_PERIOD_written <= 1'b1;
                            ack <= 1'b1;
                        end
                        else err <= 1'b1;
                    end
                    PIXEL_X: begin
                        if(DAC_stopped) begin
                            X_pixel[15:0] <= received_data[15:0];
                            PIXEL_X_written <= 1'b1;
                            ack <= 1'b1;
                        end
                        else err <= 1'b1;
                    end
                    PIXEL_Y: begin
                        if(DAC_stopped) begin
                            Y_pixel[15:0] <= received_data[15:0];
                            PIXEL_Y_written <= 1'b1;
                            ack <= 1'b1;
                        end
                        else err <= 1'b1;
                    end
                    // BYTE_PACKET: begin
                    //     if(DAC_stopped && received_data[15:0] <= 16'd9014 && received_data[15:0] >= 16'd1514 && received_data[0] == 1'b0) begin //Must be in the range of the possible jumbo frame MTU and must be even
                    //         Byte_UDP_packet[15:0] <= received_data[15:0] - 16'd42;
                    //         ack <= 1'b1;
                    //     end
                    //     else err <= 1'b1;
                    // end
                    X_AMPL_SCALING: begin
                        X_ampl_scaling[15:0] <= received_data[15:0];
                        X_update_ampl_scaling_cmd <= 1'b1;
                        X_AMPL_SCALING_written <= 1'b1;
                        ack <= 1'b1;
                    end                    
                    Y_AMPL_SCALING: begin
                        Y_ampl_scaling[15:0] <= received_data[15:0];
                        Y_update_ampl_scaling_cmd <= 1'b1;
                        Y_AMPL_SCALING_written <= 1'b1;
                        ack <= 1'b1;
                    end                    
                    Y_PHASE: begin
                        Y_phase[15:0] <= received_data[15:0];
                        Y_update_phase_cmd <= 1'b1; 
                        Y_PHASE_written <= 1'b1;
                        ack <= 1'b1;
                    end
                    Y_AMPL: begin
                        Y_ampl[15:0] <= received_data[15:0];
                        Y_AMPL_written <= 1'b1;
                        SIN_update_increment_step_cmd_temp <= 1'b1;
                        ack <= 1'b1;
                    end
                    LOCKIN_PHASE: begin
                        lockin_phase[15:0] <= received_data[15:0];
                        lockin_update_phase_cmd <= 1'b1; 
                        LOCKIN_PHASE_written <= 1'b1;
                        ack <= 1'b1;
                    end
                    LOCKIN_CIC_DEC: begin
                        lockin_CIC_decimation_rate[15:0] <= received_data[15:0];
                        lockin_update_CIC_decimation_rate_cmd <= 1'b1;
                        LOCKIN_CIC_DEC_written <= 1'b1;
                        ack <= 1'b1;
                    end
                    LOCKIN_MA_LEN: begin
                        lockin_MA_length[15:0] <= received_data[15:0];
                        lockin_MA_length_update_cmd <= 1'b1;
                        LOCKIN_MA_LEN_written <= 1'b1;
                        ack <= 1'b1;
                    end
                    // LOCKIN_MA_STAGES: begin
                    //     if(DAC_stopped && received_data[15:0] == 16'd1) begin
                    //         lockin_MA_stages[15:0] <= received_data[15:0];
                    //         LOCKIN_MA_STAGES_written <= 1'b1;
                    //         ack <= 1'b1;
                    //     end
                    //     else err <= 1'b1;
                    // end
                    LOCKIN_SUM_POINTS_MSB:begin
                        lockin_sum_points[31:16] <= received_data[15:0];
                        lockin_sum_points_update_MSB_cmd <= 1'b1;
                        LOCKIN_SUM_POINTS_MSB_written <= 1'b1;
                        ack <= 1'b1;
                    end
                    LOCKIN_SUM_POINTS_LSB:begin
                        lockin_sum_points[15:0] <= received_data[15:0];
                        lockin_sum_points_update_LSB_cmd <= 1'b1;
                        LOCKIN_SUM_POINTS_LSB_written <= 1'b1;
                        ack <= 1'b1;
                    end
                    ROTATION_COS: begin
                        rotation_cos <= received_data[15:0];
                        rotation_update_cos_cmd <= 1'b1;
                        ack <= 1'b1;
                    end
                    ROTATION_SIN: begin
                        rotation_sin <= received_data[15:0];
                        rotation_update_sin_cmd <= 1'b1;
                        ack <= 1'b1;
                    end
                    NUMBER_OF_ROTATIONS: begin
                        number_of_rotations <= received_data[7:0];
                        number_of_rotations_update_cmd <= 1'b1;
                        NUMBER_OF_ROTATIONS_written <= 1'b1;
                        ack <= 1'b1;
                    end
                    PI_COEFF_1_MSB: begin
                        PI_coefficient_1[63:48] <= received_data[15:0];
                        PI_coefficient_1_MSB_update_cmd <= 1'b1;
                        PI_coefficient_1_MSB_written <= 1'b1;
                        ack <= 1'b1;
                    end
                    PI_COEFF_1_CSB: begin
                        PI_coefficient_1[47:24] <= received_data[23:0];
                        PI_coefficient_1_CSB_update_cmd <= 1'b1;
                        PI_coefficient_1_CSB_written <= 1'b1;
                        ack <= 1'b1;
                    end
                    PI_COEFF_1_LSB: begin
                        PI_coefficient_1[23:0] <= received_data[23:0];
                        PI_coefficient_1_LSB_update_cmd <= 1'b1;
                        PI_coefficient_1_LSB_written <= 1'b1;
                        ack <= 1'b1;
                    end
                    PI_COEFF_2_MSB: begin
                        PI_coefficient_2[63:48] <= received_data[15:0];
                        PI_coefficient_2_MSB_update_cmd <= 1'b1;
                        PI_coefficient_2_MSB_written <= 1'b1;
                        ack <= 1'b1;
                    end
                    PI_COEFF_2_CSB: begin
                        PI_coefficient_2[47:24] <= received_data[23:0];
                        PI_coefficient_2_CSB_update_cmd <= 1'b1;
                        PI_coefficient_2_CSB_written <= 1'b1;
                        ack <= 1'b1;
                    end
                    PI_COEFF_2_LSB: begin
                        PI_coefficient_2[23:0] <= received_data[23:0];
                        PI_coefficient_2_LSB_update_cmd <= 1'b1;
                        PI_coefficient_2_LSB_written <= 1'b1;
                        ack <= 1'b1;
                    end
                    X_OFFSET_MSB: begin
                        if(DAC_stopped) begin
                            offset_X_double[63:48] <= received_data[15:0];
                            offset_X_double_MSB_update_cmd <= 1'b1;
                            ack <= 1'b1;
                        end
                        else err <= 1'b1;
                    end
                    X_OFFSET_CSB: begin
                        if(DAC_stopped) begin
                            offset_X_double[47:24] <= received_data[23:0];
                            offset_X_double_CSB_update_cmd <= 1'b1;
                            ack <= 1'b1;
                        end
                        else err <= 1'b1;
                    end
                    X_OFFSET_LSB: begin
                        if(DAC_stopped) begin
                            offset_X_double[23:0] <= received_data[23:0];
                            offset_X_double_LSB_update_cmd <= 1'b1;
                            ack <= 1'b1;
                        end
                        else err <= 1'b1;
                    end
                    Y_OFFSET_MSB: begin
                        if(DAC_stopped) begin
                            offset_Y_double[63:48] <= received_data[15:0];
                            offset_Y_double_MSB_update_cmd <= 1'b1;
                            ack <= 1'b1;
                        end
                        else err <= 1'b1;
                    end
                    Y_OFFSET_CSB: begin
                        if(DAC_stopped) begin
                            offset_Y_double[47:24] <= received_data[23:0];
                            offset_Y_double_CSB_update_cmd <= 1'b1;
                            ack <= 1'b1;
                        end
                        else err <= 1'b1;
                    end
                    Y_OFFSET_LSB: begin
                        if(DAC_stopped) begin
                            offset_Y_double[23:0] <= received_data[23:0];
                            offset_Y_double_LSB_update_cmd <= 1'b1;
                            ack <= 1'b1;
                        end
                        else err <= 1'b1;
                    end
                    PAT_INC_X: begin
                        pattern_increment_step_x[23:0] <= received_data[23:0];
                        update_pattern_increment_step_x_cmd <= 1'b1;
                        ack <= 1'b1;
                    end
                    PAT_INC_Y: begin
                        pattern_increment_step_y[23:0] <= received_data[23:0];
                        update_pattern_increment_step_y_cmd <= 1'b1;
                        ack <= 1'b1;
                    end
                    PAT_COUNT_X: begin
                        pattern_step_count_x[23:0] <= received_data[23:0];
                        update_pattern_step_count_x_cmd <= 1'b1;
                        ack <= 1'b1;
                    end
                    PAT_COUNT_Y: begin
                        pattern_step_count_y[23:0] <= received_data[23:0];
                        update_pattern_step_count_y_cmd <= 1'b1;
                        ack <= 1'b1;
                    end


                    default: begin
                        nak <= 1'b1;                        
                    end
                endcase
            end
            default: begin
                STATE <= IDLE;                     
            end
        endcase
    end
end

//Increment step calculation (in order to have waveform peak increment of less then 1mV per period)
//When the soft strat/stop multiplier is 16'h4000, the movement is in steady state.
//This value is shifted by (1+floor(log2(X_ampl))) to reach the value 16'h4000 in a number of increment greater
//than the peak-peak ampliture.
//There is an extra shift, so 2+shift_value_X because the increment happens twice per period (on each zero crossing)

//For the atom tracking we select the smallest increment step which is used on both the movement controller.

wire [15:0] shift_value_X, shift_value_Y;

log2n #(.BITS(16)) log2_shiftx(
	.clock(clk),
	.reset(reset),
	.data_in(X_ampl),
	.log2_out(shift_value_X)
);

log2n #(.BITS(16)) log2_shifty(
	.clock(clk),
	.reset(reset),
	.data_in(Y_ampl),
	.log2_out(shift_value_Y)
);

//Choose the increment step accoarding to the larger amplitude between X and Y in AT mode (only X in FAST)
always @(posedge clk) begin
    if (reset) begin
        SIN_update_increment_step_cmd <= 1'b0;
        SIN_increment_step <= 0;
    end
    else begin
        SIN_update_increment_step_cmd <= SIN_update_increment_step_cmd_temp; //register to add a delay to sync with the log2n operation
        if (!atom_nFast || shift_value_X >= shift_value_Y) begin
            SIN_increment_step <= (16'h4000) >> (2+shift_value_X);
        end
        else begin
            SIN_increment_step <= (16'h4000) >> (2+shift_value_Y);
        end
    end    
end

endmodule