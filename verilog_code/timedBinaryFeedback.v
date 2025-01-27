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
    input                                           in_valid,
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
    input   [1:0]                                      transmissionCfg,
    output reg [$clog2(maxActiveFeedbacCycles+1) -1:0] lastActiveDuration,
    output reg                                         lastActiveDuration_dataValid,
    output                                             lastReachedThreshold
);
localparam  cfg_useTimer = 0,
            cfg_use_x1 = 1;
localparam  trasmCfg_0to1 = 0,              //send the time intervals between the transitions from x0 to x1
            trasmCfg_1to0 = 1,              //send the time intervals between the transitions from x1 to x0
            trasmCfg_anyTransition = 2,     //send the time intervals between any transition (from x0 to x1 and from x1 to x0) (the reached threshold is specified by lastReachedThreshold)
            trasmCfg_everyCross = 3;        //send the time intervals between any 2 threshold crosses (even if they are from x0 to x0, or from x1 to x1)
localparam  s_crossed_x0 = 0,
            s_crossed_x1 = 1;
reg state;

reg [$clog2(maxActiveFeedbacCycles+1) -1:0] counter;
reg resetCounterNextCycle;

reg [inputBitSize -1:0] prev_in;
wire isTimerFinished = (cfg == cfg_useTimer) && (counter == 0);

wire crossing_x0, crossing_x1, crossing_any;
assign crossing_any = crossing_x0 || crossing_x1;
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
assign lastReachedThreshold = state;


always @(posedge clk)begin
    if(reset)begin
        prev_in <= 0;
        state <= s_crossed_x1;
        counter <= 0;
        lastActiveDuration <= 0;
        out <= 0;
        lastActiveDuration_dataValid <= 0;
        resetCounterNextCycle <= 0;
    end else begin
        if(in_valid)begin
            prev_in <= in;
            if(switchState[state])begin
                state <= ! state;
                out <= outputs[!state];
                resetCounterNextCycle <= 1;
            end else begin
                resetCounterNextCycle <= 0;            
            end

            case (transmissionCfg)
                trasmCfg_0to1 : begin
                    lastActiveDuration_dataValid <= crossing_x1 && state == s_crossed_x0;
                end
                trasmCfg_1to0 : begin
                    lastActiveDuration_dataValid <= crossing_x0 && state == s_crossed_x1;
                end
                trasmCfg_anyTransition : begin
                    lastActiveDuration_dataValid <= crossing_any && switchState[state];
                end
                trasmCfg_everyCross : begin
                    lastActiveDuration_dataValid <= crossing_any;
                end
            endcase
        end else begin
            lastActiveDuration_dataValid <= 0;
            resetCounterNextCycle <= 0; 
        end

        if(resetCounterNextCycle)begin
            lastActiveDuration <= 1;
        end else begin
            lastActiveDuration <= lastActiveDuration + 1;
        end

        case(state)
            s_crossed_x0: begin
                counter <= counter - 1;
            end
            s_crossed_x1 : begin
                counter <= maxTimeOn_x0;
            end
        endcase


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
force -freeze sim:/thresholdFeedback/cfg 1 0
force -freeze sim:/thresholdFeedback/transmissionCfg 0 0
force -freeze sim:/thresholdFeedback/valueWhenIn_x0 aaaa 0
force -freeze sim:/thresholdFeedback/valueWhenIn_x1 bbbb 0
run
# GetModuleFileName: Impossibile trovare il modulo specificato.
# 
# 
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
force -freeze sim:/thresholdFeedback/in 004 0
run
force -freeze sim:/thresholdFeedback/in 0008 0
run
force -freeze sim:/thresholdFeedback/in 0020 0
run
force -freeze sim:/thresholdFeedback/in 0047 0
run
force -freeze sim:/thresholdFeedback/in 0059 0
run
force -freeze sim:/thresholdFeedback/in 0030 0
run
force -freeze sim:/thresholdFeedback/in 0025 0
run
force -freeze sim:/thresholdFeedback/in 0004 0
run
run
force -freeze sim:/thresholdFeedback/in 0054 0
run
run
run
run
run
run
force -freeze sim:/thresholdFeedback/clk 1 0, 0 {50 ps} -r 100
force -freeze sim:/thresholdFeedback/reset z1 0
force -freeze sim:/thresholdFeedback/in 0 0
force -freeze sim:/thresholdFeedback/x0 10 0
force -freeze sim:/thresholdFeedback/x1 50 0
force -freeze sim:/thresholdFeedback/maxTimeOn_x0 3 0
force -freeze sim:/thresholdFeedback/cfg 1 0
force -freeze sim:/thresholdFeedback/transmissionCfg 1 0
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
force -freeze sim:/thresholdFeedback/in 004 0
run
force -freeze sim:/thresholdFeedback/in 0008 0
run
force -freeze sim:/thresholdFeedback/in 0020 0
run
force -freeze sim:/thresholdFeedback/in 0047 0
run
force -freeze sim:/thresholdFeedback/in 0059 0
run
force -freeze sim:/thresholdFeedback/in 0030 0
run
force -freeze sim:/thresholdFeedback/in 0025 0
run
force -freeze sim:/thresholdFeedback/in 0004 0
run
run
force -freeze sim:/thresholdFeedback/in 0054 0
run
run
run
run
run
run
force -freeze sim:/thresholdFeedback/clk 1 0, 0 {50 ps} -r 100
force -freeze sim:/thresholdFeedback/reset z1 0
force -freeze sim:/thresholdFeedback/in 0 0
force -freeze sim:/thresholdFeedback/x0 10 0
force -freeze sim:/thresholdFeedback/x1 50 0
force -freeze sim:/thresholdFeedback/maxTimeOn_x0 3 0
force -freeze sim:/thresholdFeedback/cfg 1 0
force -freeze sim:/thresholdFeedback/transmissionCfg 2 0
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
force -freeze sim:/thresholdFeedback/in 004 0
run
force -freeze sim:/thresholdFeedback/in 0008 0
run
force -freeze sim:/thresholdFeedback/in 0020 0
run
force -freeze sim:/thresholdFeedback/in 0047 0
run
force -freeze sim:/thresholdFeedback/in 0059 0
run
force -freeze sim:/thresholdFeedback/in 0030 0
run
force -freeze sim:/thresholdFeedback/in 0025 0
run
force -freeze sim:/thresholdFeedback/in 0004 0
run
run
force -freeze sim:/thresholdFeedback/in 0054 0
run
run
run
run
run
run
force -freeze sim:/thresholdFeedback/clk 1 0, 0 {50 ps} -r 100
force -freeze sim:/thresholdFeedback/reset z1 0
force -freeze sim:/thresholdFeedback/in 0 0
force -freeze sim:/thresholdFeedback/x0 10 0
force -freeze sim:/thresholdFeedback/x1 50 0
force -freeze sim:/thresholdFeedback/maxTimeOn_x0 3 0
force -freeze sim:/thresholdFeedback/cfg 1 0
force -freeze sim:/thresholdFeedback/transmissionCfg 3 0
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
force -freeze sim:/thresholdFeedback/in 004 0
run
force -freeze sim:/thresholdFeedback/in 0008 0
run
force -freeze sim:/thresholdFeedback/in 0020 0
run
force -freeze sim:/thresholdFeedback/in 0047 0
run
force -freeze sim:/thresholdFeedback/in 0059 0
run
force -freeze sim:/thresholdFeedback/in 0030 0
run
force -freeze sim:/thresholdFeedback/in 0025 0
run
force -freeze sim:/thresholdFeedback/in 0004 0
run
run
force -freeze sim:/thresholdFeedback/in 0054 0
run
run
run
run
run
run
*/