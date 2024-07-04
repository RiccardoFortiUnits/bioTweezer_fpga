/// Module calculating the floor of the log2 of data_in ///
module log2n #(
    parameter BITS = 16
) (
    input               clock,
    input               reset,
    input [BITS-1:0]    data_in,
    output reg [$clog2(BITS)-1:0]  log2_out
);

reg[$clog2(BITS):0] i;

always @(posedge clock) begin
    if (reset) begin
        log2_out <= 0;
    end
    else begin
        if (data_in == 0) begin
            log2_out <= 0;
        end
        else begin
            for (i=0; i < BITS; i = i+1'b1) begin
                if (data_in[i] == 1'b1) begin
                    log2_out <= i[$clog2(BITS)-1:0];
                end
            end
        end        
    end    
end
    
endmodule