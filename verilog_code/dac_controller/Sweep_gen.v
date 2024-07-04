module Sweep_gen (
    input           clk_50,
    input           reset,
    //Commands
    input           start_fifo_cmd,
    input           start_sweep_cmd,
    input           stop_sweep_cmd,
    //controller status:
    output reg      running,
    input           running_fb,
    //mode control:
    input           mode_nCont_disc,
    //sweep parameters
    input signed [31:0] frequency_initial_single,
    input [31:0]        frequency_final_single,
    input signed [63:0] frequency_step_single,
    input [31:0]        number_of_clock_single,
    input signed [15:0] wfm_amplitude_single,
    //fifo parameters
    output reg      fifo_rd_ack,
    input [195:0]   fifo_rd_data,
    input           fifo_rd_empty,

    //ADC sync
    input [15:0]            ADC_delay,
    output                  ADC_acquire,
    output [31:0]           frequency_current_del,
    //ouptut wfm delayed for demodulation
    output [79:0]    	    output_freq_wfm,

    //output wfm for DACs
    output reg              reset_NCO,
    input                   dac_busy,
    output signed [15:0]    sweep_sin_scaled_DAC,
    output                  sweep_out_valid
);

wire [15:0] wfm_amplitude_fifo = fifo_rd_data[15:0];
wire [31:0] number_of_clock_fifo = fifo_rd_data[47:16];
wire [63:0] frequency_step_fifo = fifo_rd_data[111:48];
wire [31:0] frequency_final_fifo = fifo_rd_data[143:112];
wire [31:0] frequency_initial_fifo = fifo_rd_data[175:144];

reg fifo_nsingle;
reg [31:0] frequency_initial, frequency_final, number_of_clock;
reg [15:0] wfm_amplitude;
reg [63:0] frequency_step;

localparam  NCO_latency = 10, //8 w/o dither, 10 w/ dither
            SHF_REG_latency = NCO_latency + 2; //+1 for the scaling multiplier and +1 for the delay of the enable

///////////// ADC SYNC ////////////
wire shift_register_wfm_ready;

shift_register_delayer  #(.MAX_LENGTH(1024)) ADC_acquire_delayer(
	.clock(clk_50),
	.reset(reset),
	.enable(1'b1),
	.length(ADC_delay+1), //+1 to account for the delay added by frequecy sum @ row 67
	.data_in(sweep_out_valid),
	.data_out(ADC_acquire)
);

shift_register_ram_based  #(
    .MAX_LENGTH(1024),	//Max length of the moving average
    .DATA_BITS(80) //Bits of the words in the shift registers
) shift_register_wfm (
	.clock(clk_50),
	.reset(reset),
	.enable(1'b1),	//keep the shift register always flowing, the validity is defined by the ADC_acquire
	.length(ADC_delay), 
    .data_in({sweep_sin_scaled_DAC, frequency_current_del, sweep_sin_data_del, sweep_cos_data_del}),
	.data_out(output_freq_wfm),
	.ready(shift_register_wfm_ready)
);

///////// SIN only for raw data view /////////
// reg signed [31:0] sin_as_dac;
// wire signed [15:0] sin_as_dac_scaled = sin_as_dac[31-:16]; //Q1.15
// always @(posedge clk_50 ) begin
//     if (!dac_busy) begin
//         sin_as_dac <= sweep_sin_data * $signed({{1'b0},wfm_amplitude});
//     end
// end

///////// SYNC MOD. FREQ to the SIN & COS DATA /////////
reg [15:0] sweep_sin_data_del, sweep_cos_data_del;
reg signed [31:0] frequency_current;
always @(posedge clk_50 ) begin
    sweep_sin_data_del <= sweep_sin_data; //Delay to account for the DAC scaling product (this is synchronous with what goes to the DACs)
    sweep_cos_data_del <= sweep_cos_data; //Delay to account for the DAC scaling product (this is synchronous with what goes to the DACs)
    frequency_current <= frequency_initial + freq_modulation[63-:32];
end
wire [31:0] shift_register_out;
wire shift_register_ready;
shift_register_ram_based  #(
    .MAX_LENGTH(16),	//Max length of the moving average
    .DATA_BITS(32) //Bits of the words in the shift registers
) shift_register_freq (
	.clock(clk_50),
	.reset(reset),
	.enable(1'b1),	//keep the shift register always flowing, the validity is defined by the sweep_out_valid
	.length(SHF_REG_latency), //Minimum allowed length is 1 //-a for the delay due to the previous always block
	.data_in(frequency_current),
	.data_out(frequency_current_del),
	.ready(shift_register_ready)
);

////////////// MAIN FSM /////////////

localparam  MAIN_IDLE = 0,
            MAIN_WAIT_FB = 1,
            MAIN_RUNNING = 2,
            MAIN_ENDING = 3,
            MAIN_END = 4,
            MAIN_WAIT_RESET = 5;

reg [2:0] FSM_main;

reg sweep_start;

always @(posedge clk_50 ) begin
    if (reset) begin
        sweep_start <= 1'b0;
        running <= 1'b0;
        reset_NCO <= 1'b1;
        FSM_main <= MAIN_IDLE;
    end
    else begin
        case (FSM_main)
            MAIN_IDLE: begin
                reset_NCO <= 1'b0;
                running <= 1'b0;
                if ((start_sweep_cmd || start_fifo_cmd) && shift_register_ready && shift_register_wfm_ready && !running_fb) begin
                    fifo_nsingle <= start_fifo_cmd;
                    running <= 1'b1;
                    FSM_main <= MAIN_WAIT_FB;
                end
            end 
            MAIN_WAIT_FB: begin
                if (running_fb) begin
                    FSM_main <= MAIN_RUNNING;
                    sweep_start <= 1'b1;
                end
            end
            MAIN_RUNNING: begin
                sweep_start <= 1'b0;
                if (sweep_end) begin
                    running <= 1'b0;
                    FSM_main <= MAIN_ENDING;
                end
            end
            MAIN_ENDING: begin
                if (!sweep_out_valid) begin
                    FSM_main <= MAIN_END;
                end
            end
            MAIN_END: begin
                sweep_start <= 1'b0;
                if (!dac_busy) begin
                    reset_NCO <= 1'b1;
                    FSM_main <= MAIN_WAIT_RESET;
                end
            end
            MAIN_WAIT_RESET: begin
                reset_NCO <= 1'b0;
                if (!dac_busy && !reset_NCO) begin
                    FSM_main <= MAIN_IDLE;
                end
            end 
            default: begin
                sweep_start <= 1'b0;
                running <= 1'b0;
                FSM_main <= MAIN_IDLE;
            end
        endcase
    end
end

/////////////// SWEEP /////////////////

localparam  SWEEP_IDLE = 0,
            SWEEP_CONTINUE = 1,
            SWEEP_DISCRETE = 2;

reg [2:0] FSM_sweep;

wire less_then = ($signed(freq_modulation[63-:32]) <= $signed(frequency_final));
wire greater_then = ($signed(freq_modulation[63-:32]) >= $signed(frequency_final));

reg sweep_enable, sweep_end;
reg [31:0] step_counter;
reg [63:0] clock_counter;
reg signed [63:0] freq_modulation;

always @(posedge clk_50 ) begin
    if (reset) begin
		sweep_end <= 1'b0;
        sweep_enable <= 1'b0;
        sweep_end <= 1'b0;
        freq_modulation <= 0;
        step_counter <= 0;
        clock_counter <= 0;
        FSM_sweep <= SWEEP_IDLE;
    end
    else begin
        case (FSM_sweep)
            SWEEP_IDLE: begin
                sweep_end <= 1'b0;
                fifo_rd_ack <= 1'b0;
                clock_counter <= 0;
                step_counter <= 0;
                if (sweep_start) begin
                    freq_modulation <= 0;
                    sweep_enable <= 1'b1;
                    if(fifo_nsingle) begin
                        frequency_initial <= frequency_initial_fifo;
                        frequency_final <= frequency_final_fifo;
                        frequency_step <= frequency_step_fifo;
                        number_of_clock <= number_of_clock_fifo;
                        wfm_amplitude <= wfm_amplitude_fifo;
                        fifo_rd_ack <= 1'b1;
                    end
                    else begin
                        frequency_initial <= frequency_initial_single;
                        frequency_final <= frequency_final_single;
                        frequency_step <= frequency_step_single;
                        number_of_clock <= number_of_clock_single;
                        wfm_amplitude <= wfm_amplitude_single;
                    end
                    if (mode_nCont_disc) FSM_sweep <= SWEEP_DISCRETE;
                    else FSM_sweep <= SWEEP_CONTINUE;
                end
            end 
            SWEEP_CONTINUE: begin
                fifo_rd_ack <= 1'b0;
                if ((frequency_final[31] && less_then) || (!frequency_final[31] && greater_then)) begin
                    sweep_enable <= 1'b0; 
                    sweep_end <= 1'b1;
                    FSM_sweep <= SWEEP_IDLE;
                end
                else begin
                    if (stop_sweep_cmd) begin
                        sweep_enable <= 1'b0; 
                        sweep_end <= 1'b1;
                        FSM_sweep <= SWEEP_IDLE;
                    end
                    freq_modulation <= freq_modulation + frequency_step;
                end
            end
            SWEEP_DISCRETE: begin
                fifo_rd_ack <= 1'b0;
                clock_counter <= clock_counter + 1;
                if (stop_sweep_cmd) begin
                    sweep_enable <= 1'b0; 
                    sweep_end <= 1'b1;
                    FSM_sweep <= SWEEP_IDLE;
                end
                else if (clock_counter == number_of_clock - 1) begin
                    if (step_counter == frequency_final - 1) begin
                        if (fifo_nsingle && !fifo_rd_empty) begin
                            frequency_initial <= frequency_initial_fifo;
                            frequency_final <= frequency_final_fifo;
                            frequency_step <= frequency_step_fifo;
                            number_of_clock <= number_of_clock_fifo;
                            wfm_amplitude <= wfm_amplitude_fifo;
					        freq_modulation <= 0;
                            step_counter <= 0;                      
                            clock_counter <= 0;
                            fifo_rd_ack <= 1'b1;
                        end
                        else begin
                            sweep_enable <= 1'b0; 
                            sweep_end <= 1'b1;
                            FSM_sweep <= SWEEP_IDLE;
                        end                        
                    end
                    else begin   
                        step_counter <= step_counter + 1;                     
                        clock_counter <= 0;
                        freq_modulation <= freq_modulation + frequency_step;
                    end                        
                end
            end 
            default: begin
                sweep_end <= 1'b0;
					  sweep_enable <= 1'b0;
					  sweep_end <= 1'b0;
					  freq_modulation <= 0;
                FSM_main <= SWEEP_IDLE;
            end
        endcase
    end
end

wire signed[15:0] sweep_sin_data, sweep_cos_data;

Sweep Sweep0 (
    .clk(clk_50),       // clk.clk
    .reset_n(!(reset||reset_NCO)),   // rst.reset_n
    .clken(sweep_enable || sweep_out_valid),     //  in.clken
    .phi_inc_i(frequency_initial), //    .phi_inc_i
    .freq_mod_i(freq_modulation[63-:32]),
    .fsin_o(sweep_sin_data),    // out.fsin_o
    .fcos_o(sweep_cos_data),
    .out_valid()  //    .out_valid
);
/////////////////// MULTIPLIER ///////////////////////
reg signed [32:0] sweep_sin_scaled;

always @(posedge clk_50 ) begin
    sweep_sin_scaled <= sweep_sin_data * $signed({{1'b0},wfm_amplitude}); //Q2.31 (Q1.15*Q1.16)
end

assign sweep_sin_scaled_DAC = sweep_sin_scaled[31-:16]; //Q1.15
///////////// LATENCY //////////////////
// Compensante the latency of the sweep
shift_register_delayer  #(.MAX_LENGTH(16)) sweep_valid(
	.clock(clk_50),
	.reset(reset),
	.enable(1'b1),
	.length(SHF_REG_latency), 
	.data_in(sweep_enable),
	.data_out(sweep_out_valid)
);


endmodule