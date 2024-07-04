	module ADC_data_adder #(
		parameter AVERAGING_POINTS_BITS = 32 
	)(
    input   clock,
    input   reset,
	input	atom_nFast,

    input   ADC_acquire_fast,
    input   ADC_acquire_atom,
    input   [15:0] ADC_data,

	input 	[AVERAGING_POINTS_BITS-1:0] averaging_points,

    input   rdclk_fifo,
	input   rdreq_fifo_64,	
	output [63:0] rddata_fifo_64,
	output  rdempty_fifo_64
);

localparam  FP_CONVERSION_LATENCY = 3; //latency of the FP conversion

// Reset the averager when the acquisition has ended
// The reset when in atom mode is done through a dedicated signal from the lockin
wire reset_average;
sync_edge_det average_resetter (
    .clk(clock),
    .signal_in(ADC_acquire_fast),
    .falling(reset_average)
);

// Register the data because is coming from a different clock domain (100MHz)
reg [15:0] ADC_data_reg0, ADC_data_reg1;
always @(posedge clock ) begin
	ADC_data_reg0 <= ADC_data;
	ADC_data_reg1 <= ADC_data_reg0;
end

//	Averager
wire [AVERAGING_POINTS_BITS+16-1:0] averaged_data;
wire averaged_data_valid;
averager#(
    .INPUT_DATA_BITS(16),
    .AVERAGING_POINTS_BITS(AVERAGING_POINTS_BITS)
) averager_inst (
	.clock(clock),
	.reset(reset || reset_average),
	.shift(~atom_nFast), //in atom the division in done by the client
	.averaging_points(averaging_points),
	.data_in(ADC_data_reg1),
	.data_out(averaged_data),
	.run_averaging(ADC_acquire_fast || ADC_acquire_atom),
	.data_valid(averaged_data_valid)
);

wire [63:0] averaged_data_ext = {{16{averaged_data[AVERAGING_POINTS_BITS+16-1]}},averaged_data};


//64 BIT FIFO
//FastSTM mode: only the 16 LSB are used
//AtomtTracking mode: all the 64 bit are used
	
adc_fifo_64	lockin_fifo64_inst (
	.aclr (reset),
	.data (averaged_data_ext[63:0]), //in fast only the 16LSB are actually meaningfull
	.wrclk (clock),
	.wrreq (averaged_data_valid),

	.rdclk (rdclk_fifo),
	.rdreq (rdreq_fifo_64),
	.q (rddata_fifo_64),
	.rdempty (rdempty_fifo_64)
);
    
endmodule