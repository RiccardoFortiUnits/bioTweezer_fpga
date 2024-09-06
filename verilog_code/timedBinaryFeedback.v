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