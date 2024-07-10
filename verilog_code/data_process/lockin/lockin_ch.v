module lockin_ch #(
    parameter LOCKIN_latency = 3,	//Lockin module latency
    parameter LOCKIN2_latency = 5	//Lockin module latency
) (
    input   	clk_adc,
    input   	clk_adc_fast,
    input   	reset,
    input       filter_order, //0 for order 1, 1 for order 2

    input [63:0]    lockin_nco_wfm, 
	input [15:0]    lockin_input, 
	input           lockin_input_acquire, 
	input           lockin_output_acquire,

    input signed [26:0]     alpha,

    output reg [31:0]   X_reg,
    output reg [31:0]   Y_reg,
    output reg [31:0]   freq_reg,
    output reg          lockin_output_valid,
    input               lockin_output_read
);
// input pipeline
// reg [15:0] lockin_input_temp, lockin_sin_temp, lockin_cos_temp;
// reg [32:0] lockin_freq_temp;
// reg lockin_input_acquire_temp, lockin_output_acquire_temp;
// always @(posedge clk_adc ) begin
//     lockin_input_temp <= lockin_input;
//     lockin_freq_temp <= lockin_nco_wfm[63:32];
//     lockin_sin_temp <= lockin_nco_wfm[31:16];
//     lockin_cos_temp <= lockin_nco_wfm[15:0];
//     lockin_input_acquire_temp <= lockin_input_acquire;
//     lockin_output_acquire_temp <= lockin_output_acquire;
// end

//delay the acquire for the lockin latency (-1 to sample the last valid data before the input changes)
wire lockin_output_acquire_del;
shift_register_delayer  #(.MAX_LENGTH(LOCKIN2_latency)) lockin_output_acquire_delayer(
	.clock(clk_adc),
	.reset(reset),
	.enable(1'b1),
	.length(filter_order? (LOCKIN2_latency-1) : (LOCKIN_latency-1)),
	.data_in(lockin_output_acquire),
	.data_out(lockin_output_acquire_del)
);

// lockin
wire [31:0] X_out;
wire [31:0] Y_out;
wire out_valid;
lockin lockin_0(
    .clk(clk_adc_fast),
    .rst(reset || reset_lockin), //reset at the last acquire
    .filter_order(filter_order),
    .signal_in(lockin_input),
    .sin_ref(lockin_nco_wfm[31:16]),
    .cos_ref(lockin_nco_wfm[15:0]),
    .in_valid(lockin_input_acquire),
    .alpha(alpha),
    .X_out(X_out),
    .Y_out(Y_out),
    .out_valid (out_valid)
);

// temporary store the input freq to the lock in to sync it with the output
// lockin_output_acquire (XY_acquire) changes just before the frequency change, so this stores the freq before it changes
reg [31:0] freq_reg_temp;
always @(posedge clk_adc or posedge reset) begin
    if (reset) freq_reg_temp <= 0;
    else if (lockin_output_acquire) freq_reg_temp <= lockin_nco_wfm[63:32];
end

// samples the output of the lockin at the last sample of the frequency step
always @(posedge clk_adc or posedge reset) begin
    if (reset) begin
        X_reg <= 0;
        Y_reg <= 0;
        freq_reg <= 0;
    end
    else if (lockin_output_acquire_del) begin
        X_reg <= X_out;
        Y_reg <= Y_out;
        freq_reg <= freq_reg_temp;
    end
end
// keep a flag for the output data until it's read
// there is no write protection, it's possible to lose a sample
// if the clocks per step is less than the number of lock-in this is not a problem
// the round-robin polling technique to write to the fifo should be fast enough
always @(posedge clk_adc or posedge reset) begin
    if (reset) begin
        lockin_output_valid <= 1'b0;
    end
    else begin
        if (lockin_output_acquire_del) lockin_output_valid <= 1'b1;
        if (lockin_output_read) lockin_output_valid <= 1'b0;
    end
end

reg reset_lockin, reset_lockin_temp,reset_lockin_temp2;
always @(posedge clk_adc  or posedge reset) begin
    if (reset) begin
        reset_lockin <= 1'b0;
        reset_lockin_temp <= 1'b0;
    end 
    else begin
        reset_lockin_temp <= (lockin_output_acquire_del && !lockin_input_acquire);
        reset_lockin_temp2 <= reset_lockin_temp;
        reset_lockin <= reset_lockin_temp2;
    end
end


endmodule