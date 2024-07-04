module dual_averager_wrapper #(
	parameter AVERAGING_POINTS_BITS = 16,	//BITS for averaging_points (so max averaging factor (2^AVERAGING_POINTS_BITS)-1)
	parameter INPUT_DATA_BITS = 16,			//BITS for the input data
	parameter SIGNED = 1					//1 for signed data_in
)(
    input   clock,
    input   reset,
	input 	shift, //1 if shift wanted for the average (to use only if averaging_points = 2^n)
    input 	[AVERAGING_POINTS_BITS-1:0] averaging_points,

    input   [INPUT_DATA_BITS-1:0] data_in_1,
    input   [INPUT_DATA_BITS-1:0] data_in_2,
    input   run_averaging,

    output  [INPUT_DATA_BITS + AVERAGING_POINTS_BITS-1:0] data_out_1,
    output  [INPUT_DATA_BITS + AVERAGING_POINTS_BITS-1:0] data_out_2,
	output  data_valid    
);

wire data_valid_1, data_valid_2;

averager #(
    .INPUT_DATA_BITS(INPUT_DATA_BITS),
    .AVERAGING_POINTS_BITS(AVERAGING_POINTS_BITS),
    .SIGNED(SIGNED)
) averager_1 (
	.clock(clock),
	.reset(reset),
	.shift(shift),
	.averaging_points(averaging_points),
    
	.data_in(data_in_1),
	.run_averaging(run_averaging),

	.data_out(data_out_1),
	.data_valid(data_valid_1)
);

averager #(
    .INPUT_DATA_BITS(INPUT_DATA_BITS),
    .AVERAGING_POINTS_BITS(AVERAGING_POINTS_BITS),
    .SIGNED(SIGNED)
) averager_2 (
	.clock(clock),
	.reset(reset),
	.shift(shift),
	.averaging_points(averaging_points),

	.data_in(data_in_2),
	.run_averaging(run_averaging),

	.data_out(data_out_2),
	.data_valid(data_valid_2)
);

assign data_valid = data_valid_1 && data_valid_2;

endmodule