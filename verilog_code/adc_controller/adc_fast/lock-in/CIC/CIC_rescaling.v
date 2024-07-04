module CIC_rescaling #(
    parameter MAX_CIC_RATE = 16384
) (
    input       clock,
    input       reset,
    input [decimation_rate_bits-1:0] CIC_decimation_rate,

    input [59:0] CIC_data_x,
    input [59:0] CIC_data_y,
    input CIC_data_valid,

    output reg [31:0] CIC_output_x,
    output reg [31:0] CIC_output_y,
    output reg CIC_rescaled_valid
);

localparam decimation_rate_bits = $clog2(MAX_CIC_RATE+1);

wire [$clog2(decimation_rate_bits)-1:0] log2_CIC_decimation_rate;
log2n #(.BITS(decimation_rate_bits)) log2_averaging(
	.clock(clock),
	.reset(reset),
	.data_in(CIC_decimation_rate),
	.log2_out(log2_CIC_decimation_rate)
);

wire [$clog2(decimation_rate_bits):0] shift_value = log2_CIC_decimation_rate << 1; //*2 a causa del numero di stadi (2)

wire [59:0] CIC_data_x_shifted, CIC_data_y_shifted;
unbiased_rounding #(
	.AVERAGING_POINTS_BITS(decimation_rate_bits<< 1),	
	.INPUT_DATA_BITS(60)		
) unbiased_rounding_x (    
	.shift_value(shift_value),
    .data_in(CIC_data_x),
    .data_out(CIC_data_x_shifted)
);
unbiased_rounding #(
	.AVERAGING_POINTS_BITS(decimation_rate_bits<< 1),	
	.INPUT_DATA_BITS(60)		
) unbiased_rounding_y (    
	.shift_value(shift_value),
    .data_in(CIC_data_y),
    .data_out(CIC_data_y_shifted)
);

always @(posedge clock ) begin
    if (reset) begin
        CIC_rescaled_valid <= 1'b0;
        CIC_output_x <= 0;
        CIC_output_y <= 0;
    end
    else begin
        CIC_rescaled_valid <= 1'b0;
        if (CIC_data_valid) begin
            CIC_output_x <= CIC_data_x_shifted[31:0];
            CIC_output_y <= CIC_data_y_shifted[31:0];
            CIC_rescaled_valid <= 1'b1;
        end   
    end
    
end
    
endmodule