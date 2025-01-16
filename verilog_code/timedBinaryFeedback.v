module timedBinaryFeedback #(
  parameter inputBitSize = 16,
  parameter outputBitSize = 16,
  parameter isInputSigned = 1,
  parameter maxActiveFeedbacCycles = 'h80000000
)(
    input                                           clk,
    input                                           reset,
    
    input   [inputBitSize -1:0]                     in,
    input   [inputBitSize -1:0]                     threshold,
    input                                           actOnInGreaterThanThreshold,

    input   [$clog2(maxActiveFeedbacCycles+1) -1:0] cyclesForActivation,
    input   [$clog2(maxActiveFeedbacCycles+1) -1:0] activeFeedbackMaxCycles,
    input   [$clog2(maxActiveFeedbacCycles+1) -1:0] idleWaitCycles,

    input   [outputBitSize -1:0]                    valueWhenIdle,
    input   [outputBitSize -1:0]                    valueWhenActive,
    output reg [outputBitSize -1:0]                 out
);

localparam  s_idle = 0,
            s_active = 1,
            s_waitIdle = 2;
reg [1:0] state;
reg [$clog2(maxActiveFeedbacCycles) -1:0] counter, activationCounter;
reg [inputBitSize -1:0] in_r, threshold_r;



wire isCurrentFrameActive;
reg canActivate;

generate
    if(isInputSigned)begin
        assign isCurrentFrameActive = actOnInGreaterThanThreshold ? 
                        $signed(in_r) > $signed(threshold_r) :
                        $signed(in_r) < $signed(threshold_r);
    end else begin
        assign isCurrentFrameActive = actOnInGreaterThanThreshold ? 
                        $unsigned(in_r) > $unsigned(threshold_r) :
                        $unsigned(in_r) < $unsigned(threshold_r);
    end
endgenerate

`define setActive                             \
    if(canActivate)begin                        \
        state <= s_active;                      \
        counter = activeFeedbackMaxCycles - 1;  \
        out <= valueWhenActive;                 \
    end else begin                              \
        state <= s_idle;                        \
        out <= valueWhenIdle;                   \
    end

always @(posedge clk) begin
    if(reset) begin
        state <= 0;
        out <= 0;
        counter <= 0;
        activationCounter <= 0;
        canActivate <= 0;
        in_r <= 0;
        threshold_r <= 0;
    end else begin
        in_r <= in;
        threshold_r <= threshold;

        if(isCurrentFrameActive)begin
            if(activationCounter == cyclesForActivation)begin
                canActivate <= 1;
            end else begin
                activationCounter <= activationCounter + 1;
                canActivate <= 0;                
            end
        end else begin
            activationCounter <= 0;
            canActivate <= 0;    
        end

        case (state)
            s_idle : begin
                `setActive
            end
            s_active : begin
                if(counter)begin
                    counter <= counter - 1;
                    out <= valueWhenActive;
                end else begin
                    if(!idleWaitCycles)begin
                        `setActive
                    end else begin
                        state <= s_waitIdle;
                        counter <= idleWaitCycles - 1;
                        out <= valueWhenIdle;
                    end
                end
            end
            s_waitIdle : begin
                if(counter)begin
                    counter <= counter - 1;
                    out <= valueWhenIdle;
                end else begin
                    `setActive
                end
            end
            default : begin
                state <= s_idle;
                out <= valueWhenIdle;
            end
        endcase
    end
end

endmodule

module thresholdFeedback #(
  parameter inputBitSize = 16,
  parameter outputBitSize = 16,
  parameter isInputSigned = 1,
  parameter maxActiveFeedbacCycles = 'h80000000
)(
    input                                           clk,
    input                                           reset,
    
    input   [inputBitSize -1:0]                     in,
    input   [inputBitSize -1:0]                     x0,
    input   [inputBitSize -1:0]                     x1,
    input   [$clog2(maxActiveFeedbacCycles+1) -1:0] maxTimeOn_x0,
    input                                           cfg,
    // input                                           actOnInGreaterThanx0,

    // input   [$clog2(maxActiveFeedbacCycles+1) -1:0] cyclesForActivation,
    // input   [$clog2(maxActiveFeedbacCycles+1) -1:0] activeFeedbackMaxCycles,
    // input   [$clog2(maxActiveFeedbacCycles+1) -1:0] idleWaitCycles,

    input   [outputBitSize -1:0]                    valueWhenIn_x0,
    input   [outputBitSize -1:0]                    valueWhenIn_x1,
    output reg [outputBitSize -1:0]                 out,
    output reg [$clog2(maxActiveFeedbacCycles+1) -1:0] lastActiveDuration,
    output reg                                         lastActiveDuration_dataValid
);
localparam  cfg_useTimer = 0,
            cfg_use_x1 = 1;
localparam  s_crossed_x0 = 0,
            s_crossed_x1 = 1;
reg state;

reg [$clog2(maxActiveFeedbacCycles+1) -1:0] counter;

reg [inputBitSize -1:0] prev_in;
wire isTimerFinished = (cfg == cfg_useTimer) && (counter == 0);

wire crossing_x0, crossing_x1;
generate
    if(isInputSigned)begin
        assign crossing_x0 = (( $signed (prev_in) <  $signed (x0) &  $signed (in) >=  $signed (x0)) || ( $signed (prev_in) >  $signed (x0) &  $signed (in) <=  $signed (x0)));
        assign crossing_x1 = isTimerFinished || ((cfg == cfg_use_x1) && ((( $signed (prev_in) <  $signed (x1) &  $signed (in) >=  $signed (x1)) || ( $signed (prev_in) >  $signed (x1) &  $signed (in) <=  $signed (x1)))));
    end else begin
        assign crossing_x0 = (($unsigned(prev_in) < $unsigned(x0) & $unsigned(in) >= $unsigned(x0)) || ($unsigned(prev_in) > $unsigned(x0) & $unsigned(in) <= $unsigned(x0)));
        assign crossing_x1 = isTimerFinished || ((cfg == cfg_use_x1) && ((($unsigned(prev_in) < $unsigned(x1) & $unsigned(in) >= $unsigned(x1)) || ($unsigned(prev_in) > $unsigned(x1) & $unsigned(in) <= $unsigned(x1)))));        
    end
endgenerate

wire [1:0] switchState = {crossing_x0, crossing_x1};//state x0 finishes when we cross x1, and vice versa
wire [outputBitSize -1:0] outputs[1:0];
assign outputs[0] = valueWhenIn_x0;
assign outputs[1] = valueWhenIn_x1;

always @(posedge clk)begin
    if(reset)begin
        prev_in <= 0;
        state <= s_crossed_x1;
        counter <= 0;
        lastActiveDuration <= 0;
        out <= 0;
        lastActiveDuration_dataValid <= 0;
    end else begin
        prev_in <= in;
        if(switchState[state])begin
            state <= ! state;
        end
        lastActiveDuration_dataValid <= switchState[s_crossed_x0] && state == s_crossed_x0;

        case(state)
            s_crossed_x0: begin
                counter <= counter - 1;
                lastActiveDuration <= lastActiveDuration + 1;//todo controlla
            end
            s_crossed_x1 : begin
                counter <= maxTimeOn_x0;
                lastActiveDuration <= 0;
            end
        endcase

        out <= outputs[state];

    end
end

endmodule
/*
add wave -position insertpoint sim:/thresholdFeedback/*
force -freeze sim:/thresholdFeedback/clk 1 0, 0 {50 ps} -r 100
force -freeze sim:/thresholdFeedback/reset z1 0
force -freeze sim:/thresholdFeedback/in 0 0
force -freeze sim:/thresholdFeedback/x0 10 0
force -freeze sim:/thresholdFeedback/x1 50 0
force -freeze sim:/thresholdFeedback/maxTimeOn_x0 3 0
force -freeze sim:/thresholdFeedback/cfg 0 0
force -freeze sim:/thresholdFeedback/valueWhenIn_x0 aaaa 0
force -freeze sim:/thresholdFeedback/valueWhenIn_x1 bbbb 0
run
force -freeze sim:/thresholdFeedback/reset 10 0
run

run
run
force -freeze sim:/thresholdFeedback/in 00f 0
run
force -freeze sim:/thresholdFeedback/in 0015 0
run
force -freeze sim:/thresholdFeedback/in 0019 0
run
run
run
run
run
run
run
force -freeze sim:/thresholdFeedback/in 004 0
run
run
force -freeze sim:/thresholdFeedback/cfg 01 0
force -freeze sim:/thresholdFeedback/in 0008 0
run
force -freeze sim:/thresholdFeedback/in 0020 0
run
force -freeze sim:/thresholdFeedback/in 0047 0
run
force -freeze sim:/thresholdFeedback/in 0059 0
run
run
run
*/