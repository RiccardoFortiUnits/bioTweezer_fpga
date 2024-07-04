//module which "out_reg" goes high after "in" is stable high for at least the "delay" clock cycles
//the falling edge is istantaneous
module delayer #(parameter BIT_WIDTH = 16)
(
    input                   clk,
    input                   reset,
    input                   in,
    input [BIT_WIDTH-1:0]   delay, //must be at least 1
    output                  out
);

localparam  IDLE = 2'd0,
            COUNT = 2'd1;
            
reg out_reg;
reg [BIT_WIDTH-1:0] counter;
reg [1:0] STATE = IDLE;

always @ (posedge clk)
begin
    if (reset) begin
        out_reg <= 1'b0;
        STATE <= IDLE;
    end
    else begin
        case(STATE)
            IDLE: begin
                out_reg <= 1'b0;
                if(in) begin
                    counter <= delay - 1'b1; //for the input registers               
                    STATE <= COUNT;
                    if (delay == 1) out_reg <= 1'b1;
                end
            end

            COUNT: begin
                if(!in) begin
                    out_reg <= 1'b0;
                    STATE <= IDLE;
                end
                else if(counter == 0) begin
                    out_reg <= 1'b1;
                end
                else begin
                    out_reg <= 1'b0;
                    counter <= counter - 1'b1;
                end
            end            
        endcase
    end
end

assign out = (delay == 0)? in:((!in)? 1'b0 : out_reg);

endmodule
 