module timeout_check #(parameter BIT_WIDTH = 16)
(
    input                   clk,
    input                   reset,
    input                   restart_counter,
    input [BIT_WIDTH-1:0]   delay_length,
    output reg              timed_out_n
);

localparam  IDLE = 2'd0,
            COUNT = 2'd1;
reg reg_in;
reg [BIT_WIDTH-1:0] reg_delay;
reg [BIT_WIDTH-1:0] counter;
reg [1:0] STATE = IDLE;

always @ (posedge clk)
begin
    if (reset) begin
        timed_out_n <= 1'd0;
        counter <= 0;
        STATE <= IDLE;
    end
    else begin
        case(STATE)
            IDLE:
            begin
                if(restart_counter) begin
                    counter <= delay_length;
                    STATE <= COUNT;
                end
                else begin
                    counter <= 0;
                    STATE <= IDLE;
                end
                timed_out_n <= 1'd0;
            end

            COUNT:
            begin
                if(restart_counter) begin
                    counter <= delay_length;
                    STATE <= COUNT;
                end
                else begin
                    if(counter == 0) begin
                        STATE <= IDLE;
                    end
                    else begin
                        counter <= counter - 1'b1;
                        STATE <= COUNT;
                    end
                end
                timed_out_n <= 1'b1;
            end            
        endcase
    end
end

endmodule