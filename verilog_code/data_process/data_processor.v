module data_processor (
    input   	clk_adc,
    input   	clk_adc_fast,
    input       clk_udp,
    input   	reset,

    input       mode_nRaw_dem,
    input [2:0] gain,
    output reg  overflow,

    input signed [15:0]    ADC_data_in,
    input signed [15:0]    ADC_data_out,
    input                   SW,

    input           ADC_acquire,
    input           XY_acquire,
    input [79:0]    sweep_freq_wfm,
    output signed [15:0]   ADC_data_in_gain,
    output signed [15:0]   current_sin_DAC,
    output signed [15:0]   current_sin,
    output signed [15:0]   current_cos,

    output [107:0]   acq_rddata_fifo_108,
    output          acq_rdempty_fifo_108,
    input           acq_rdreq_fifo_108
);

// wire signed [15:0] current_sin_DAC = $signed(sweep_freq_wfm[79-:16]);
assign current_sin_DAC = $signed(sweep_freq_wfm[79-:16]);
wire signed [31:0] current_freq = $signed(sweep_freq_wfm[63-:32]);
// wire signed [15:0] current_sin = $signed(sweep_freq_wfm[31-:16]);
assign current_sin = $signed(sweep_freq_wfm[31-:16]);
//wire signed [15:0] current_cos = $signed(sweep_freq_wfm[15-:16]);
assign current_cos = $signed(sweep_freq_wfm[15-:16]);

wire reset_average_end, sample_initial_freq;
sync_edge_det sync_edge_det_reset_acquire (
    .clk(clk_adc),
    .signal_in(ADC_acquire),
    .rising(sample_initial_freq),
    .falling(reset_average_end)
);

// wire signed [15:0] ADC_data_in_gain = ADC_data_in <<< gain;
assign ADC_data_in_gain = ADC_data_in <<< gain;
wire signed [15:0] ADC_data_out_gain = ADC_data_out  <<< gain;

always @(posedge clk_adc ) begin
    overflow <= 0;
    if (gain == 3'd6) begin
        overflow <= ((ADC_data_in[15] && !(&ADC_data_in[15 -: 6])) || (!ADC_data_in[15] && (|ADC_data_in[15 -: 6])));
    end
    if (gain == 3'd5) begin
        overflow <= ((ADC_data_in[15] && !(&ADC_data_in[15 -: 5])) || (!ADC_data_in[15] && (|ADC_data_in[15 -: 5])));
    end
    if (gain == 3'd4) begin
        overflow <= ((ADC_data_in[15] && !(&ADC_data_in[15 -: 4])) || (!ADC_data_in[15] && (|ADC_data_in[15 -: 4])));
    end
    if (gain == 3'd3) begin
        overflow <= ((ADC_data_in[15] && !(&ADC_data_in[15 -: 3])) || (!ADC_data_in[15] && (|ADC_data_in[15 -: 3])));
    end
    if (gain == 3'd2) begin
        overflow <= ((ADC_data_in[15] && !(&ADC_data_in[15 -: 2])) || (!ADC_data_in[15] && (|ADC_data_in[15 -: 2])));
    end
    if (gain == 3'd1) begin
        overflow <= ((ADC_data_in[15] && !(&ADC_data_in[15 -: 1])) || (!ADC_data_in[15] && (|ADC_data_in[15 -: 1])));
    end
end

wire signed [15:0] reference_signal = SW? ADC_data_out_gain : current_sin_DAC;

// if in discontinuos sweep mode, if the current and previosu frequency are different
// the average get resetted and nothing get written in the FIFO
// actually if the averager is outputting a valid sample it's starting a new average so
// the reset is not needed
wire freq_change = mode_nRaw_dem? (current_freq_del != current_freq_del1) : (current_freq != current_freq_del); //while demodulating extra latency needed for the multiplication
wire reset_averaging = freq_change && !average_valid && ((mode_nRaw_dem && ADC_acquire_del1)||(!mode_nRaw_dem && ADC_acquire_del));
reg frequency_change_udp;
always @(posedge clk_adc ) begin //flag to put in the FIFO to signal the frequency change
    if(freq_change) begin
        frequency_change_udp <= 1'b1;
    end
    if(frequency_change_udp && average_valid) begin
        frequency_change_udp <= 1'b0;
    end
end

wire [31:0] averaged_freq, averaged_sin, average_cos_original;
wire average_freq_valid, average_sin_valid, average_cos_valid;
wire average_valid = average_freq_valid || average_sin_valid || average_cos_valid;
averager #(
    .AVERAGING_POINTS_BITS(8),	//BITS for averaging_points (so max averaging factor (2^AVERAGING_POINTS_BITS)-1)
	.INPUT_DATA_BITS(32),		//BITS for the input data
	.SIGNED(1)					//1 for signed data_in
)averager_freq(
    .clock(clk_adc),
    .reset(reset || reset_averaging || reset_average_end),
	.shift(1),
	.averaging_points(mode_nRaw_dem? 8'd64 : 8'd16),
    .data_in(mode_nRaw_dem? current_freq_del : current_freq),
    .data_out(averaged_freq),	
    .run_averaging(mode_nRaw_dem? ADC_acquire_del : ADC_acquire),
    .data_valid(average_freq_valid)
);
averager #(
    .AVERAGING_POINTS_BITS(8),	//BITS for averaging_points (so max averaging factor (2^AVERAGING_POINTS_BITS)-1)
	.INPUT_DATA_BITS(32),		//BITS for the input data
	.SIGNED(1)					//1 for signed data_in
)averager_sin(
    .clock(clk_adc),
    .reset(reset || reset_averaging || reset_average_end),
	.shift(1),
	.averaging_points(mode_nRaw_dem? 8'd64 : 8'd16),
    .data_in(mode_nRaw_dem? ADC_data_in_mixed_sin : {{16{reference_signal[15]}},reference_signal}),
    .data_out(averaged_sin),	
    .run_averaging(mode_nRaw_dem? ADC_acquire_del : ADC_acquire), //this is used only in demodulation mode
    .data_valid(average_sin_valid)
);
averager #(
    .AVERAGING_POINTS_BITS(8),	//BITS for averaging_points (so max averaging factor (2^AVERAGING_POINTS_BITS)-1)
	.INPUT_DATA_BITS(32),		//BITS for the input data
	.SIGNED(1)					//1 for signed data_in
)averager_cos(
    .clock(clk_adc),
    .reset(reset || reset_averaging || reset_average_end),
	.shift(1),
	.averaging_points(mode_nRaw_dem? 8'd64 : 8'd16),
    .data_in(mode_nRaw_dem? ADC_data_in_mixed_cos : {{16{ADC_data_in_gain[15]}},ADC_data_in_gain}),
    .data_out(average_cos_original),	
    .run_averaging(mode_nRaw_dem? ADC_acquire_del : ADC_acquire),
    .data_valid(average_cos_valid)
);

data_fifo fifo_to_udp (
	.wrclk(clk_adc),
	.data({7'd0, frequency_change_udp, averaged_freq, averaged_sin, average_cos_original}),
	.wrreq(average_valid),
	.wrfull(),
	.rdclk(clk_udp),
	.q(acq_rddata_fifo_108),
	.rdreq(acq_rdreq_fifo_108),
	.rdempty(acq_rdempty_fifo_108)
);

reg signed [31:0] ADC_data_in_mixed_sin, ADC_data_in_mixed_cos, current_freq_del, current_freq_del1;
reg ADC_acquire_del, ADC_acquire_del1;
always @(posedge clk_adc) begin
    ADC_acquire_del <= ADC_acquire;
    ADC_acquire_del1 <= ADC_acquire_del;
    current_freq_del <= current_freq;
    current_freq_del1 <= current_freq_del;
    ADC_data_in_mixed_sin <= ADC_data_in_gain * current_sin;
    ADC_data_in_mixed_cos <= ADC_data_in_gain * current_cos;
end
endmodule