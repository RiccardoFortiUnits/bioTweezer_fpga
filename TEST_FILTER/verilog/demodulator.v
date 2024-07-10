module demodulator #(
    parameter   BITS = 16,
                FACTOR = 2
) (
    input                   clk,
    input                   rst,
    input [BITS - 1 : 0]    signal_in,
    input [BITS - 1 : 0]    cos,
    input [BITS - 1 : 0]    sin,
    output [2*BITS-1:0]     out,
    output                  out_valid
);

reg [$clog2(FACTOR) : 0] counter;
reg [BITS-1 : 0] in_temp;
reg [2*BITS-1 : 0] ref_temp;

reg data_valid_0, data_valid;

always @(posedge clk ) begin
    if (rst) begin
        counter <= 0;
        data_valid_0 <= 1'b0;
        data_valid <= 1'b0;
    end
    else begin
        data_valid <= data_valid_0;
        if (counter == FACTOR-1) begin
            counter <= 0;
            data_valid_0 <= 1'b1;
            in_temp <= signal_in;
            ref_temp <= {sin, cos};
        end
        else begin
            counter <= counter + 1'b1;
            ref_temp <= ref_temp >> BITS;
        end
    end
end

// data_valid is synchronous with this
reg [BITS-1 : 0] ref, in;

always @(posedge clk ) begin
    if (rst) begin
        ref <= 0;
        in <= 0;
    end
    else begin
        in <= in_temp;
        ref <= ref_temp[BITS-1 : 0];
    end
end

reg [2*BITS-1 : 0] dem;
reg dem_valid;

always @(posedge clk ) begin
    if (rst) begin
        dem <= 0;
        dem_valid <= 0;
    end
    else begin
        dem <= $signed(in) * $signed(ref);
        dem_valid <= data_valid;
    end
end

assign out = dem;
assign out_valid = dem_valid;
    
endmodule