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

    input   [$clog2(maxActiveFeedbacCycles+1) -1:0] activeFeedbackMaxCycles,

    input   [outputBitSize -1:0]                    valueWhenIdle,
    input   [outputBitSize -1:0]                    valueWhenActive,
    output reg [outputBitSize -1:0]                 out
);

localparam  s_idle = 0,
            s_active = 1;
reg state;
reg [$clog2(maxActiveFeedbacCycles) -1:0] counter;
reg [inputBitSize -1:0] in_r, threshold_r;



wire shouldActivate;

generate
    if(isInputSigned)begin
        assign shouldActivate = actOnInGreaterThanThreshold ? 
                        $signed(in_r) > $signed(threshold_r) :
                        $signed(in_r) < $signed(threshold_r);
    end else begin
        assign shouldActivate = actOnInGreaterThanThreshold ? 
                        $unsigned(in_r) > $unsigned(threshold_r) :
                        $unsigned(in_r) < $unsigned(threshold_r);
    end
endgenerate

always @(posedge clk) begin
    if(reset) begin
        state <= 0;
        out <= 0;
        counter <= 0;
        in_r <= 0;
        threshold_r <= 0;
    end else begin
        in_r <= in;
        threshold_r <= threshold;
        case (state)
            s_idle : begin
                if(shouldActivate)begin
                    state <= s_active;
                    counter = activeFeedbackMaxCycles - 1;
                    out <= valueWhenActive;
                end else begin
                    out <= valueWhenIdle;
                end
            end
            s_active : begin
                if(counter)begin
                    counter <= counter - 1;
                    out <= valueWhenActive;
                end else begin
                    state <= s_idle;
                    out <= valueWhenIdle;
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