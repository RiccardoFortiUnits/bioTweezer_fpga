module XZ_controller #(parameter COUNTER_TH = 2000)  //parameter for the soft startup ramp
(
    input	        clk,
    input           reset,

    input disable_ramp,
    input start_cmd,    
    input stop_cmd,
    input update_phase_cmd,
    input [15:0] points_per_period, //number of points in memory
    input [15:0] scale_factor, //Q2.14 - 16'b0100000000000000 for a scale factor of 1
    input update_scale_factor_cmd,
    input [15:0] WFM_ampl_scale, //Q2.14
    input [15:0] increment_step,
    //Memory reading
    input [15:0] phase,
    output [15:0] mem_address,
    input [15:0] mem_data,
    input mem_busy,
    //LOCK-IN reference memory address
    input [15:0] lock_in_phase,
    output [15:0] sin_ref_address,
    output [15:0] cos_ref_address,    
    //DAC writing
    input dac_busy,
    output reg dac_start = 1'b0,
    output [15:0] dac_data,
    //Y sync commands
    output reg start_Y,
    output reg period,
    output reg pos_peak_period,
    output reg neg_peak_period,
    output reg stop_ramp_cmd,
    //controller status:
    output running,
    output stopped
);

assign stopped = (STATE == IDLE);
assign running = (STATE == ACQUISITION);


reg signed [15:0] multiplier = 16'd0; //Q2.14
wire signed [31:0] product0, product1;

//Data manipulation for offset, soft start and scaling factor
mult16x16 soft_starter (
    .clken (1'b1),
    .clock(clk),
    .dataa(mem_data), //Q1.15
    .datab(multiplier), //Q2.14
    .result(product0)  //Q3.29
);
mult16x16 scaling (
    .clken (1'b1),
    .clock(clk),
    .dataa(product0[29-:16]), //Q1.15
    .datab(actual_ampl_scale), //Q2.14
    .result(product1) //Q3.29
);
assign dac_data = product1[29-:16] + offset; //Q1.15

reg [15:0] offset = 16'd0;
reg [15:0] ramp_counter;

localparam  IDLE = 0,
            START_RAMP = 1,
            SOFT_START = 2,
            ACQUISITION = 3,
            SOFT_STOP = 4,
            STOP_RAMP = 5,
            WAIT_Y_SYNC = 6;

reg [3:0] STATE = IDLE;

reg start_write = 1'b0;
reg stop_write = 1'b0;

always @(posedge clk ) begin
    if (reset) begin
        STATE <= IDLE;
        stop_write <= 1'b0;
        start_write <= 1'b0;
        multiplier <= 16'd0;
        start_Y <= 1'b0;
        stop_ramp_cmd <= 1'b0; 
    end
    else begin
        case (STATE)
            IDLE: begin
                stop_write <= 1'b0;
                start_write <= 1'b0;
                multiplier <= 16'd0;
                stop_ramp_cmd <= 1'b0; 
                if (!mem_busy && start_cmd) begin
                    if (disable_ramp) begin
                        STATE <= SOFT_START;
                        offset <= 16'h8000;
                    end
                    else begin
                        STATE <= START_RAMP;                        
                    end
                    start_write <= 1'b1;
                end                
            end
            START_RAMP: begin
                start_write <= 1'b0;
                if (offset == 16'h8000) begin
                    STATE <= SOFT_START;
                end
                else if (ramp_counter == COUNTER_TH - 1'b1) begin
                    offset <= offset + 1'b1;
                    ramp_counter <= 16'd0;
                end             
                else begin
                    ramp_counter <= ramp_counter + 1'b1;
                end
            end
            SOFT_START: begin
                if (multiplier == 16'h4000) begin
                    STATE <= ACQUISITION;
                    start_Y <= 1'b1;
                end
                else if (zero_crossing) begin
                    multiplier <= multiplier + increment_step;
                end
            end
            ACQUISITION: begin
                start_Y <= 1'b0;
                if (stop_cmd) begin
                    STATE <= SOFT_STOP;
                end  
            end
            SOFT_STOP: begin                
                if (multiplier == 16'd0) begin
                    if (disable_ramp) begin
                        STATE <= IDLE;
                        stop_write <= 1'b1;
                    end
                    else begin
                        STATE <= WAIT_Y_SYNC;
                        stop_ramp_cmd <= 1'b1;                      
                    end                 
                end
                else if (zero_crossing) begin
                    multiplier <= multiplier - increment_step;
                end
            end
            WAIT_Y_SYNC:begin
                STATE <= STOP_RAMP;
            end
            STOP_RAMP: begin
                stop_ramp_cmd <= 1'b0; 
                if (offset == 16'd0) begin
                    STATE <= IDLE;
                    stop_write <= 1'b1;
                end
                else if (ramp_counter == COUNTER_TH - 1'b1) begin
                    offset <= offset - 1'b1;
                    ramp_counter <= 16'd0;
                end             
                else begin
                    ramp_counter <= ramp_counter + 1'b1;
                end
            end

            default: begin
                STATE <= IDLE;
            end
        endcase
    end
end

//global memory address counter
localparam  DISABLED = 0,
            WRITE = 1,
            INCREMENT_COUNTER = 2;

reg [2:0] STATE_DAC = DISABLED;

reg [15:0] mem_counter;

reg zero_crossing, wave_positive_peak, wave_negative_peak;

always @(posedge clk ) begin
    zero_crossing <= 1'b0;
    wave_positive_peak <= 1'b0;
    wave_negative_peak <= 1'b0;                
    period <= 1'b0;
    pos_peak_period <= 1'b0;
    neg_peak_period <= 1'b0;
    if (reset) begin
        STATE_DAC <= DISABLED;
        mem_counter <= 16'd0;
        dac_start <= 1'b0; 
    end
    else begin
        case (STATE_DAC)
            DISABLED: begin
                dac_start <= 1'b0;
                mem_counter <= 16'd0;
                if (start_write == 1'b1) begin
                    STATE_DAC <= WRITE;
                end
            end 
            WRITE: begin                
                if (stop_write) begin
                     STATE_DAC <= DISABLED;
                end               
                else if (!dac_busy) begin // +1'b1 added to reduce phase mismatch due to the real DAC/ADC latency
                    dac_start <= 1'b1;                    
                    STATE_DAC <= INCREMENT_COUNTER;
                    /*zero_crossing <= (mem_address == (points_per_period>>1) + 1'b1 || mem_address == 16'd0 + 1'b1);
                    wave_positive_peak <= (mem_address == (points_per_period>>2) + 1'b1);
                    wave_negative_peak <= (mem_address == ((points_per_period>>2)+(points_per_period>>1) + 1'b1));                
                    period <= (mem_counter == 1'b0  + 2'd2);
                    pos_peak_period <= (mem_counter == (points_per_period>>2)  + 2'd2);
                    neg_peak_period <= (mem_counter == ((points_per_period>>2)+(points_per_period>>1)  + 2'd2)); */
                    zero_crossing <= (mem_address == (points_per_period>>2) + 1'b1 || mem_address == ((points_per_period>>2)+(points_per_period>>1) + 1'b1));
                    wave_positive_peak <= (mem_address == 16'd0 + 1'b1);
                    wave_negative_peak <= (mem_address == (points_per_period>>1) + 1'b1);                
                    period <= (mem_counter == 16'd0  + 3'd4);
                    pos_peak_period <= (mem_counter == 16'd0  + 3'd4);
                    neg_peak_period <= (mem_counter == (points_per_period>>1)  + 3'd4);
                end
            end
            INCREMENT_COUNTER: begin
                dac_start <= 1'b0;     
                if (mem_counter >= points_per_period - 1) begin
                    mem_counter <= 16'd0;           
                end
                else begin
                    mem_counter <= mem_counter + 1'b1;
                end                                      
                STATE_DAC <= WRITE;
            end
            default: begin
                STATE_DAC <= DISABLED;
            end
        endcase
    end
end

//phase correction

reg signed [15:0] actual_phase;
reg signed [15:0] target_phase = 16'd0;

always @(posedge clk ) begin
    if (reset || update_phase_cmd) begin
        target_phase <= points_per_period - phase; // always >= 0, correction of phase side
    end 
end

localparam  SYNC = 0,
            UPDATE = 1,
            WAIT = 2;

reg [2:0] STATE_PHASE = SYNC;

wire signed [15:0] diff = target_phase - actual_phase;


always @(posedge clk ) begin
    if (reset) begin
        STATE_PHASE <= SYNC;
        actual_phase <= target_phase;
    end
    else begin
        case (STATE_PHASE)
            SYNC : begin 
                if (STATE == IDLE) begin
                    actual_phase <= target_phase;
                end
                else if (target_phase != actual_phase) begin
                    STATE_PHASE <= UPDATE;
                end
            end
            UPDATE: begin
                if (wave_positive_peak || wave_negative_peak) begin        
                    if ((diff > $signed(points_per_period >> 1)) || (diff[15] && (diff > -(points_per_period >> 1)))) begin
                        if (actual_phase == 16'd0) actual_phase <= points_per_period;
                        else actual_phase <= actual_phase - 1'b1;                        
                    end
                    else begin
                        if (actual_phase == points_per_period) actual_phase <= 16'd1;
                        else actual_phase <= actual_phase + 1'b1;
                    end
                    STATE_PHASE <= WAIT;
                end
            end
            WAIT: begin
                if (diff == 16'd0) begin
                    STATE_PHASE <= SYNC;
                end
                else if (zero_crossing) begin
                    STATE_PHASE <= UPDATE;
                end
            end
            default : begin
                STATE_PHASE <= SYNC;
            end
        endcase
    end
end

wire [16:0] sum = mem_counter + actual_phase;
assign mem_address = (sum[15:0] >= points_per_period)? (sum[15:0] - points_per_period) : sum[15:0];

wire [16:0] sum1 = mem_address + lock_in_phase;
assign sin_ref_address = (sum1[15:0] >= points_per_period)? (sum1[15:0] - points_per_period) : sum1[15:0];

wire [16:0] sum2 = sin_ref_address + (points_per_period>>2);
assign cos_ref_address = (sum2[15:0] >= points_per_period)? (sum2[15:0] - points_per_period) : sum2[15:0];

//scale_factor

reg signed [15:0] actual_scale_factor = 16'd0;
reg signed [15:0] target_scale_factor = 16'd0;
reg [2:0] STATE_SCALE = SYNC;

localparam  NONE = 0,
            INCREMENT = 1,
            DECREMENT = 2;

reg [2:0] DIRECTION;
reg [2:0] DIRECTION_OLD;

always @(posedge clk ) begin
    if (reset || update_scale_factor_cmd) begin
        target_scale_factor <= scale_factor;
    end     
end

always @(posedge clk ) begin
    if (reset) begin
        STATE_SCALE <= SYNC;
        DIRECTION <= NONE;
        DIRECTION_OLD <= NONE;
        actual_scale_factor <= target_scale_factor;
    end
    else begin
        case (STATE_SCALE)
            SYNC : begin
                DIRECTION <= NONE;
                DIRECTION_OLD <= NONE;
                if (STATE == IDLE) begin
                    actual_scale_factor <= target_scale_factor;
                end
                else if (actual_scale_factor != target_scale_factor) begin
                    STATE_SCALE <= UPDATE;
                end
            end
            UPDATE: begin
                if (zero_crossing) begin 
                    DIRECTION_OLD <= DIRECTION;                    
                    if (target_scale_factor < actual_scale_factor) begin
                        actual_scale_factor <= actual_scale_factor - increment_step;
                        DIRECTION <= DECREMENT;
                    end
                    if (target_scale_factor > actual_scale_factor) begin
                        actual_scale_factor <= actual_scale_factor + increment_step;
                        DIRECTION <= INCREMENT;
                    end
                    STATE_SCALE <= WAIT;
                end
            end
            WAIT: begin
                if (((DIRECTION_OLD != NONE) && (DIRECTION_OLD != DIRECTION)) || (target_scale_factor == actual_scale_factor)) begin
                    actual_scale_factor <= target_scale_factor;
                    STATE_SCALE <= SYNC;
                end
                else begin
                    STATE_SCALE <= UPDATE;
                end                
            end
            default : begin
                STATE_SCALE <= SYNC;
            end
        endcase
    end
end

wire signed [31:0] actual_ampl_scale_extended; //Q4.28
wire signed [15:0] actual_ampl_scale = actual_ampl_scale_extended [29 -: 16]; //Q2.14

mult16x16 amplitude (
    .clken (1'b1),
    .clock(clk),
    .dataa(WFM_ampl_scale), //Q2.14
    .datab(actual_scale_factor), //Q2.14
    .result(actual_ampl_scale_extended) //Q4.28
);

endmodule