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
    output reg [outputBitSize -1:0]                 out
);
localparam  cfg_useTimer = 0,
            cfg_use_x1 = 1;
localparam  s_crossed_x0 = 0,
            s_crossed_x1 = 1;
reg state;

reg [$clog2(maxActiveFeedbacCycles) -1:0] counter;

reg [inputBitSize -1:0] prev_in;
wire isTimerFinished = (cfg == cfg_useTimer) && (counter == 0);
wire crossing_x0 = ((prev_in < x0 & in >= x0) || (prev_in > x0 & in <= x0));
wire crossing_x1 = isTimerFinished || ((cfg == cfg_use_x1) && (((prev_in < x1 & in >= x1) || (prev_in > x1 & in <= x1))));

wire [1:0] switchState = {crossing_x0, crossing_x1};//state x0 finishes when we cross x1, and vice versa
wire [outputBitSize -1:0] outputs = {valueWhenIn_x1, valueWhenIn_x0};

always @(posedge clk)begin
    if(reset)begin
        prev_in <= 0;
        state <= s_crossed_x1;
        counter <= 0;
    end else begin
        prev_in <= in;
        if(switchState[state])begin
            state <= ! state;
        end
        case(state)
            s_crossed_x0: counter <= counter - 1;
            s_crossed_x1 : counter <= maxTimeOn_x0;
        endcase

        out <= outputs[state];

    end
end

endmodule