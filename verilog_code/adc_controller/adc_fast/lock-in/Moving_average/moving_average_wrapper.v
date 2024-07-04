`include "cascaded_moving_average.v"
`include "moving_average.v"

module moving_average_wrapper #(
    parameter MAX_DECIMATION = 1024,
    INPUT_DATA_BITS = 32,
    OUTPUT_DATA_BITS = 64,
    MAX_CASCADED_MAs = 3,
    SIGNED = 1
) (
    input   clock,
    input   reset,
    output  ready,

    input [INPUT_DATA_BITS-1:0]     data_in_x,
    input [INPUT_DATA_BITS-1:0]     data_in_y,
    input                           data_in_valid,

    input [$clog2(MAX_DECIMATION):0]    length_moving_average,
    input [$clog2(MAX_CASCADED_MAs):0]  order_rolloff,          

    output [OUTPUT_DATA_BITS-1:0]    data_out_x,
    output [OUTPUT_DATA_BITS-1:0]    data_out_y,
    output                          data_out_valid
);

wire ready_x, ready_y;
assign ready = ready_x && ready_y;
wire data_out_valid_x, data_out_valid_y;
assign data_out_valid = data_out_valid_x && data_out_valid_y;

cascaded_moving_average #(
        .MAX_DECIMATION(MAX_DECIMATION),
        .INPUT_DATA_BITS(INPUT_DATA_BITS),
        .OUTPUT_DATA_BITS(OUTPUT_DATA_BITS),
        .MAX_CASCADED_MAs(MAX_CASCADED_MAs),
        .SIGNED(SIGNED)
    ) MA_X (
        .clock(clock),
        .reset(reset),
        .ready(ready_x),
        .data_in(data_in_x),
        .data_in_valid(data_in_valid),
        .length_moving_average(length_moving_average),
        .order_rolloff(order_rolloff),
        .data_out(data_out_x),
        .data_out_valid(data_out_valid_x)
);

cascaded_moving_average #(
        .MAX_DECIMATION(MAX_DECIMATION),
        .INPUT_DATA_BITS(INPUT_DATA_BITS),
        .OUTPUT_DATA_BITS(OUTPUT_DATA_BITS),
        .MAX_CASCADED_MAs(MAX_CASCADED_MAs),
        .SIGNED(SIGNED)
    ) MA_Y (
        .clock(clock),
        .reset(reset),
        .ready(ready_y),
        .data_in(data_in_y),
        .data_in_valid(data_in_valid),
        .length_moving_average(length_moving_average),
        .order_rolloff(order_rolloff),
        .data_out(data_out_y),
        .data_out_valid(data_out_valid_y)
);

endmodule