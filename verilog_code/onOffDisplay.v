module onOffDisplay(
    input wire control,       // Input wire to control the display
    output reg [6:0] seg1,    // 7-segment display 1
    output reg [6:0] seg2,    // 7-segment display 2
    output reg [6:0] seg3     // 7-segment display 3
);

// 7-segment display encoding for 'O', 'N', 'F'
parameter O     = 7'b1000000;
parameter N     = 7'b0101011;
parameter F     = 7'b0001110;
parameter BLANK = 7'b1111111;

always @(*) begin
    if (control) begin
        // Display "ON"
        seg3 <= O;
        seg2 <= N;
        seg1 <= BLANK;
    end else begin
        // Display "OFF"
        seg3 <= O;
        seg2 <= F;
        seg1 <= F;
    end
end

endmodule
