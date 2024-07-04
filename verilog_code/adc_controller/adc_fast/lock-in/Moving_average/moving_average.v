module moving_average #(
    parameter MAX_DECIMATION = 1024,
    DATA_BITS = 64
) (
    input   clock,
    input   reset,
    output  ready,

    input [DATA_BITS-1:0]     data_in,
    input                     data_in_valid,
    input [$clog2(MAX_DECIMATION)-1:0]    length,    //length of the moving average, must be at least 1

    output reg [DATA_BITS-1:0]    data_out,
    output reg                    data_out_valid
);

assign ready = shift_register_ready;

always @(posedge clock ) begin
    if (reset) begin
        data_out_valid <= 1'b0;
        data_out <= 0;
    end
    else begin        
        if (shift_register_ready && data_in_valid && length != 0) begin    //when a new data arrives it added and the "length" older data removed
            data_out <= data_out + data_in - data_shifted;
            data_out_valid <= 1'b1;
        end
        else begin
            data_out_valid <= 1'b0;
        end
    end
end

wire [DATA_BITS-1:0] data_shifted;
wire shift_register_ready;

shift_register_ram_based #(
    .MAX_LENGTH(MAX_DECIMATION),
    .DATA_BITS(DATA_BITS)
) shift_register (
    .clock (clock),
    .reset (reset),
    .enable (data_in_valid),
    .length (length),
    .data_in(data_in),
    .data_out(data_shifted),
    .ready(shift_register_ready)
);

endmodule