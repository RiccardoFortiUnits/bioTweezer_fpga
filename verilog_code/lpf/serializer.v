//the module get a parallel input as {in_n,...,in_2,in_1}
//the output is serial at clk: in_1, in_2, ...

//for rate conversion (out clock faster than data in clock) the FACTOR is the division between the in data clock rate and the clk applied to the module

//for same rate operation the in and in_valid data can't be applied faster than 1 every FACTOR cycles of the clock
//in this case the input and output data have the same clock)
//this is useful to multiplex different sporadic inputs to send sequentially to a single block (maybe after a downsampling)


module serializer #(
    parameter   WIDTH = 32,
                FACTOR = 2
) (
    input                       clk,
    input                       rst,
    input [WIDTH*FACTOR-1 : 0]  in,
    input                       in_valid,
    output [WIDTH-1 : 0]        out,
    output                      out_valid  
);

reg [$clog2(FACTOR) : 0] counter;
reg [WIDTH*FACTOR-1 : 0] in_temp;
reg out_valid_temp;

always @(posedge clk ) begin
    if (rst) begin
        counter <= 0;
        in_temp <= 0;
        out_valid_temp <= 1'b0;
    end
    else if(in_valid || (|counter)) begin
        counter <= counter + 1'b1;        
        if (counter == 0) begin
            in_temp <= in;
            out_valid_temp <= 1'b1;
        end
        else begin
            in_temp <= in_temp >> WIDTH;
        end

        if (counter == FACTOR-1) begin
            counter <= 0;
        end
        
    end
    else begin
        out_valid_temp <= 1'b0;
    end
end

assign out = in_temp[WIDTH-1 : 0];
assign out_valid = out_valid_temp;

    
endmodule