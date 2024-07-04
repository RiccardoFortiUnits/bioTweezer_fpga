`include "CIC_rescaling.v"

module CIC_wrapper #(
    parameter MAX_CIC_RATE = 16384
) (
    input       clock,
    input       reset,

    input [31:0] averaged_x,
    input [31:0] averaged_y,
    input average_valid,

    input [decimation_rate_bits-1:0] CIC_decimation_rate,
    output [31:0] CIC_output_x,
    output [31:0] CIC_output_y,
    output CIC_output_valid
);

localparam decimation_rate_bits = $clog2(MAX_CIC_RATE+1);

wire CIC_data_x_valid, CIC_data_y_valid;
wire [59:0] CIC_output_x_raw, CIC_output_y_raw;

CIC_lockin CIC_X (
    .in_error (2'b00),
    .in_valid (average_valid),
    .in_ready (),
    .in_data (averaged_x),
    .out_data (CIC_output_x_raw),
    .out_error (),
    .out_valid (CIC_data_x_valid),
    .out_ready (1'b1),
    .clk (clock),
    .rate (CIC_decimation_rate),
    .reset_n (~reset)
);

CIC_lockin CIC_Y (
    .in_error (2'b00),
    .in_valid (average_valid),
    .in_ready (),
    .in_data (averaged_y),
    .out_data (CIC_output_y_raw),
    .out_error (),
    .out_valid (CIC_data_y_valid),
    .out_ready (1'b1),
    .clk (clock),
    .rate (CIC_decimation_rate),
    .reset_n (~reset)
);

wire [31:0] CIC_output_x_rescaled, CIC_output_y_rescaled;
wire CIC_output_rescaled_valid;

CIC_rescaling #(.MAX_CIC_RATE(MAX_CIC_RATE)) CIC_rescaling_0 (
    .clock(clock),
    .reset(reset),
    .CIC_decimation_rate(CIC_decimation_rate),

    .CIC_data_x(CIC_output_x_raw),
    .CIC_data_y(CIC_output_y_raw),
    .CIC_data_valid(CIC_data_x_valid && CIC_data_y_valid),

    .CIC_output_x(CIC_output_x_rescaled),
    .CIC_output_y(CIC_output_y_rescaled),
    .CIC_rescaled_valid(CIC_output_rescaled_valid)
);

assign CIC_output_x = (CIC_decimation_rate == 0)? 0 : (CIC_decimation_rate == 1)? averaged_x : CIC_output_x_rescaled;
assign CIC_output_y = (CIC_decimation_rate == 0)? 0 : (CIC_decimation_rate == 1)? averaged_y : CIC_output_y_rescaled;
assign CIC_output_valid  = (CIC_decimation_rate == 0)? 1'b0 : (CIC_decimation_rate == 1)? average_valid : CIC_output_rescaled_valid;
    
endmodule