module deserializer #(
    parameter   WIDTH = 32,
                FACTOR = 2
) (
    input                       clk,
    input                       rst,
    input [WIDTH -1 : 0]        in,
    input                       in_valid,
    output [WIDTH*FACTOR-1 : 0] out,
    output                      out_valid  
);

reg [$clog2(FACTOR) : 0] counter, counter_out_valid;
reg [WIDTH*FACTOR-1 : 0] in_temp;
reg counter_reset;

reg [WIDTH*FACTOR-1 : 0] out_temp;
reg out_valid_temp;

always @(posedge clk ) begin
    if (rst) begin
        in_temp <= 0;
        out_temp <= 0;
        out_valid_temp <= 0;
        counter <= 0;
        counter_out_valid <= 0;
    end
    else begin
        if (!(|counter_out_valid)) begin
            out_valid_temp <= 1'b0;
        end
        else begin
            counter_out_valid <= counter_out_valid - 1'b1;
        end

        if (in_valid) begin
            in_temp <= {in , in_temp[WIDTH*FACTOR-1 : WIDTH]};
            if (counter == FACTOR-1) begin
                out_temp <= {in , in_temp[WIDTH*FACTOR-1 : WIDTH]};
                out_valid_temp <= 1'b1;
                counter_out_valid <= FACTOR-1;
                counter <= 0;
            end
            else begin
                counter <= counter + 1'b1;
            end
        end        
    end
end


assign out = out_temp;
assign out_valid = out_valid_temp;

endmodule