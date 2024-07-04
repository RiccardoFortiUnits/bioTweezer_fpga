`include "dacs_ad5541a.v"
`include "Sweep_gen.v"

module DAC_wrapper (
    input           clk_50,
    input           reset,
    //Commands
    input           start_fifo_cmd,
    input           start_dac_cmd,
    input           stop_dac_cmd,
    //DAC
    output          DAC_SCK,
    output          DAC_LDAC_N,
    output [3:0]    DAC_CS_N,
    output [3:0]    DAC_SDO,
    //controller status:
    output          running,
    input           running_fb,
    //mode control:
    input           mode_nCont_disc,
    //sweep parameters
    input [31:0]    frequency_initial,
    input [31:0]    frequency_final,
    input [63:0]    frequency_step,
    input [31:0]    step_counter,
    input signed [15:0]    wfm_amplitude,
    input [15:0]    dem_delay,
    input [3:0]     SW,
    //fifo parameters
    output          fifo_rd_ack,
    input [195:0]   fifo_rd_data,
    input           fifo_rd_empty,

    //ADC sync
    output          ADC_acquire,
    output [79:0]   sweep_freq_wfm,

    //ouptut wfm delayed 

    //step generator
    input           start_step_cmd,
    input           step_in_valid,
    output reg      step_out_valid
);

assign running = running_sweep || running_step;

/////////////// SWEEP /////////////////

wire [15:0] sweep_sin_scaled_DAC;
wire running_sweep, reset_NCO_DAC, sweep_valid;
Sweep_gen Sweep_gen_0(
    .clk_50(clk_50),
    .reset(reset),
    //Commands
    .start_fifo_cmd(start_fifo_cmd),
    .start_sweep_cmd(start_dac_cmd),
    .stop_sweep_cmd(stop_dac_cmd),
    //controller status:
    .running(running_sweep),
    .running_fb(running_fb || running_step),
    //mode control:
    .mode_nCont_disc(mode_nCont_disc),
    //sweep parameters
    .frequency_initial_single(frequency_initial),
    .frequency_final_single(frequency_final),
    .frequency_step_single(frequency_step),
    .number_of_clock_single(step_counter),
    .wfm_amplitude_single(wfm_amplitude),
    //fifo parameters
    .fifo_rd_ack(fifo_rd_ack),
    .fifo_rd_data(fifo_rd_data),
    .fifo_rd_empty(fifo_rd_empty),

    //ADC sync
    .ADC_delay(dem_delay), //at least 1
    .ADC_acquire(ADC_acquire),
    //ouptut wfm delayed for demodulation
    .output_freq_wfm(sweep_freq_wfm),

    //output wfm for DACs
    .reset_NCO(reset_NCO_DAC),
    .dac_busy(dac_busy),
    .sweep_sin_scaled_DAC(sweep_sin_scaled_DAC),
    .sweep_out_valid(sweep_valid)
);

/////////////////// Step ///////////////////
localparam  STEP_IDLE = 0,
            STEP_WAIT_FB = 1,
            STEP_RUNNING = 2,
            STEP_END = 3,
            STEP_WAIT_RESET = 4;

reg [2:0] STEP_STATE;
reg running_step, reset_step_DAC;

always @(posedge clk_50) begin
    if (reset) begin
        step_out_valid <= 1'b0;
        running_step <= 1'b0;
        reset_step_DAC <= 1'b0;
        STEP_STATE <= STEP_IDLE;
    end
    else begin
        case (STEP_STATE)
            STEP_IDLE: begin
                running_step <= 1'b0;
                if (start_step_cmd && !running) begin
                    running_step <= 1'b1;
                    STEP_STATE <= STEP_WAIT_FB;
                end
            end
            STEP_WAIT_FB: begin
                if (running_fb) begin
                    STEP_STATE <= STEP_RUNNING;                    
                    step_out_valid <= 1'b1;
                end
            end
            STEP_RUNNING: begin
                step_out_valid <= 1'b0;
                if (step_in_valid) begin
                    STEP_STATE <= STEP_END;
                end
            end
            STEP_END: begin
                reset_step_DAC <= 1'b1;
                STEP_STATE <= STEP_WAIT_RESET;
            end
            STEP_WAIT_RESET: begin
                reset_step_DAC <= 1'b0;
                if (!dac_busy && !reset_step_DAC) begin
                    STEP_STATE <= STEP_IDLE;
                end
            end 
            default: begin
                step_out_valid <= 1'b0;
                running_step <= 1'b0;
                reset_step_DAC <= 1'b0;
                STEP_STATE <= STEP_IDLE;
            end
        endcase
    end
end

// always @(posedge clk_50 ) begin
//     if (SW[8] == 1'b0 && counter == 0 ) begin
//         step_data <= 16'b1001100110011001;
//     end 
//     if (~dac_busy) begin
//         step_data <= 16'h0000;
//     end
// end

///////////// NOISE  //////////////////////

wire signed [15:0] gaussian_noise;

gng noise_gen
(
    // System signals
    .clk(clk_50),                    // system clock
    .rstn(~reset),                   // system synchronous reset, active low
    // Data interface
    .ce(1'b1),                     // clock enable
    .data_out(gaussian_noise)       // output data, s<16,11>
);

/////////////////// MULTIPLIERS ///////////////////////

reg signed [32:0] gaussian_noise_scaled;

always @(posedge clk_50 ) begin
    gaussian_noise_scaled <= gaussian_noise * $signed({{1'b0},wfm_amplitude}); //Q2.31 (Q1.15*Q1.16)
end

wire signed [15:0] gaussian_noise_scaled_cropped = gaussian_noise_scaled[31-:16]; //Q1.15

/////////////////// DACs ///////////////////////

wire dac_busy;
dacs_ad5541a dacs_ad5541a_0 (
    .clock(clk_50),
    .reset(reset || reset_NCO_DAC || reset_step_DAC),

    .dac1_datain(16'h8000),
    .dac2_datain(gaussian_noise_scaled_cropped+16'h8000),
    .dac3_datain(16'h8000),
    .dac4_datain((STEP_STATE==STEP_IDLE)? sweep_sin_scaled_DAC+16'h8000 : 16'b1001100110011001), //500 mv step
    // .dac1_datain(16'h8000),
    // .dac2_datain(sweep_data+16'h8000),
    // .dac3_datain(sweep_data+16'h8000),
    // .dac4_datain(sweep_data+16'h8000),

    .select_dac(3'b100), //all dacs enabled
    .start(sweep_valid || step_out_valid),
    .busy(dac_busy),

    .sclk(DAC_SCK),
    .ldac_n(DAC_LDAC_N),
    .dac_sdo(DAC_SDO),
    .cs_n(DAC_CS_N)
);
endmodule