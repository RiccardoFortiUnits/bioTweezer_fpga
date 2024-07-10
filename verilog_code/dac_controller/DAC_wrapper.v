`include "dacs_ad5541a.v"
`include "Sweep_gen.v"

module DAC_wrapper (
    input           clk_50,
    input   	    clk_adc_fast,
    input           reset,
    //Commands
    input           start_fifo_cmd,
    input           stop_dac_cmd,
    //DAC
    output          DAC_SCK,
    output          DAC_LDAC_N,
    output [3:0]    DAC_CS_N,
    output [3:0]    DAC_SDO,
    //controller status:
    output          running,
    input           running_fb,
    input signed [15:0]    wfm_amplitude,
    input [15:0]    dem_delay,
    input [3:0]     SW,
    //fifo parameters
    output          fifo_rd_ack,
    input [195:0]   fifo_rd_data,
    input           fifo_rd_empty,

    //ADC sync
    output          ADC_acquire,
    output          XY_acquire,
    output [79:0]   sweep_freq_wfm,

    //input DACs data from NCOs
    input [15:0]    data_DAC_PML,
    input [15:0]    data_DAC_PML_valid,
    input           filtering,

    //step generator
    input           start_step_cmd,
    input           step_in_valid,
    output reg      step_out_valid
);

assign running = running_sweep || data_DAC_PML_valid;

/////////////// SWEEP /////////////////

wire [15:0] sweep_sin_scaled_DAC;
wire running_sweep, reset_NCO_DAC, sweep_valid;
Sweep_gen Sweep_gen_0(
    .clk_50(clk_50),
    .reset(reset),
    //Commands
    .start_fifo_cmd(start_fifo_cmd),
    .stop_sweep_cmd(stop_dac_cmd),
    //controller status:
    .running(running_sweep),
    .running_fb(running_fb),
    //fifo parameters
    .fifo_rd_ack(fifo_rd_ack),
    .fifo_rd_data(fifo_rd_data),
    .fifo_rd_empty(fifo_rd_empty),

    //ADC sync
    .ADC_delay(dem_delay), //at least 1
    .ADC_acquire(ADC_acquire),
    .XY_acquire(XY_acquire),
    //ouptut wfm delayed for demodulation
    .output_freq_wfm(sweep_freq_wfm),

    //output wfm for DACs
    .reset_NCO(reset_NCO_DAC),
    .dac_busy(dac_busy),
    .sweep_sin_scaled_DAC(sweep_sin_scaled_DAC),
    .sweep_out_valid(sweep_valid)
);

wire [15:0] filt_out1, filt_out2;
wire filt_out_valid;

dac_filter dac_filter_0 (
    .clk(clk_adc_fast),
    .rst(reset),
    .signal_in(data_DAC_PML),
    .in_valid(data_DAC_PML_valid),
    .alpha(27'b000110000011101011111001101),
    .X_out(filt_out2), //this is of second stage
    .out_valid(filt_out_valid),
);

reg [15:0] data_DAC_PML_filt;
reg data_DAC_PML_filt_valid;

always @(posedge clk_50) begin
    if (reset) begin
        data_DAC_PML_filt <= 16'd0;
       data_DAC_PML_filt_valid <= 1'b0;
    end
    else begin
        data_DAC_PML_filt <= filt_out2;
        data_DAC_PML_filt_valid <= filt_out_valid;
    end
end

///////////// NOISE  //////////////////////

wire signed [15:0] gaussian_noise;

// gng noise_gen
// (
//     // System signals
//     .clk(clk_50),                    // system clock
//     .rstn(~reset),                   // system synchronous reset, active low
//     // Data interface
//     .ce(1'b1),                     // clock enable
//     .data_out(gaussian_noise)       // output data, s<16,11>
// );

/////////////////// MULTIPLIERS ///////////////////////

reg signed [32:0] gaussian_noise_scaled;

// always @(posedge clk_50 ) begin
//     gaussian_noise_scaled <= gaussian_noise * $signed({{1'b0},wfm_amplitude}); //Q2.31 (Q1.15*Q1.16)
// end

wire signed [15:0] gaussian_noise_scaled_cropped = gaussian_noise_scaled[32-:16]; //Q1.15

wire signed [15:0] DAC_PML_SEL = filtering ? data_DAC_PML_filt : data_DAC_PML;

wire signed [15:0] sweep_out = running_sweep? sweep_sin_scaled_DAC : DAC_PML_SEL;

/////////////////// DACs ///////////////////////
//if the start comes from the PML NCOs give priority to this signal

wire dac_busy;
dacs_ad5541a dacs_ad5541a_0 (
    .clock(clk_50),
    .reset(reset || reset_NCO_DAC),

    .dac1_datain(16'h8000),
    .dac2_datain(gaussian_noise_scaled_cropped+16'h8000),
    .dac3_datain(16'h8000), //PML output
    .dac4_datain(sweep_out+16'h8000), //sweeps output
    // .dac1_datain(16'h8000),
    // .dac2_datain(sweep_data+16'h8000),
    // .dac3_datain(sweep_data+16'h8000),
    // .dac4_datain(sweep_data+16'h8000),

    .select_dac(3'b100), //all dacs enabled
    .start(1'b1), //start from the 
    .busy(dac_busy),

    .sclk(DAC_SCK),
    .ldac_n(DAC_LDAC_N),
    .dac_sdo(DAC_SDO),
    .cs_n(DAC_CS_N)
);
endmodule