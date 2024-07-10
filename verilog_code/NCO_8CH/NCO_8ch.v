module NCO_8ch (
    input           clk_50,
    input           reset,
    //Commands
    input [7:0]     start_cmd,
    input [7:0]     stop_cmd,
    //controller status:
    output [7:0] running,
    
    //Sweep FIFO
    input [7:0]     clr_fifo_cmd,
    input           clk_udp,
    input [191:0]   sweep_data_udp,
    input [7:0]     fifo_wr_udp,
    output [7:0]    fifo_full_udp,
    
    //ADC sync
    input [15:0]            ADC_delay,
    output [7:0]            ADC_acquire,
    output [7:0]            XY_acquire,
    //ouptut wfm delayed for demodulation
    output [NCO_CHANNELS*64-1:0] output_wfm,

    //output wfm for DACs
    output signed [15:0]    data_DAC,
    output                  data_DAC_valid
);

localparam  NCO_latency = 9 + 1, //7 w/o dither, 9 w/ dither (without FM) // + 1 for the delay of the enable? don'know why, the delay between phi_inc_i and outputs is 10
            LOCKIN_latency = 3; //the lockin module has a factor 3 latency and is needed to sample the X and Y at the right time

localparam NCO_CHANNELS = 8;

// 8 CHANNEL FSM INSTANTIATION //

wire [7:0] XY_ch_acquire;
wire [7:0] NCO_ch_enable;
wire [79:0] NCO_ch_parameters [7:0];
wire [31:0] frequency_initial_ch [7:0];
wire [31:0] frequency_modulation_ch [7:0];
wire [15:0] wfm_amplitude_ch [7:0];

genvar i;
generate
    for (i = 0; i < NCO_CHANNELS ; i = i+1) begin : loop_FSM
        FSM_NCOch FSM_NCOchi(
            .clk_50(clk_50),
            .reset(reset),

            .start_cmd(start_cmd[i]),
            .stop_cmd(stop_cmd[i]),

            .running(running[i]),

            .clr_fifo_cmd(clr_fifo_cmd[i]),
            .clk_udp(clk_udp),
            .sweep_data_udp(sweep_data_udp),
            .fifo_wr_udp(fifo_wr_udp[i]),
            .fifo_full_udp(fifo_full_udp[i]),

            .XY_ch_acquire(XY_ch_acquire[i]),
            .NCO_ch_parameters(NCO_ch_parameters[i]),
            .NCO_ch_enable(NCO_ch_enable[i])
        );
		 assign wfm_amplitude_ch[i] = NCO_ch_parameters[i][15:0];
		 assign frequency_modulation_ch[i] = NCO_ch_parameters[i][47:16];
		 assign frequency_initial_ch[i] = NCO_ch_parameters[i][79:48];
    end
endgenerate

// NCO INPUT LOGIC //
reg [31:0] frequency_initial_nco, frequency_modulation_nco;
reg [2:0] sel_nco_in;
always @(posedge clk_50) begin
    if (reset) begin
        frequency_initial_nco <= frequency_initial_ch[0];
        frequency_modulation_nco <= frequency_modulation_ch[0];
        sel_nco_in <= 1;
    end
    else begin
        sel_nco_in <= sel_nco_in + 1'b1;
        frequency_initial_nco <= frequency_initial_ch[sel_nco_in] + frequency_modulation_ch[sel_nco_in];
        //frequency_modulation_nco <= frequency_modulation_ch[sel_nco_in];
    end
end
// NCO //
wire signed[15:0] sin_data_nco, cos_data_nco;
wire out_valid_nco;
NCO_8ch_IP NCO_8ch_IP0 (
    .clk(clk_50),       // clk.clk
    .reset_n(!reset),   // rst.reset_n
    .clken(1'b1),     //  in.clken
    .phi_inc_i(frequency_initial_nco),
    //.freq_mod_i(frequency_modulation_nco),//NCO with 30 bit freq.mod
    .fsin_o(sin_data_nco),    // out.fsin_o
    .fcos_o(cos_data_nco),
    .out_valid(out_valid_nco)  //    .out_valid
);
// NCO OUTPUT LOGIC //

// SIGNAL TO DAC SCALING
// !!! the wavefrom amplitude changes earlier then the NCO corresponding output, due to the NCO latency (~ 10 clock cycles)
// !!! this slightly alterate the output signal for a few clock cycles and it can create amplitute glitches (no zero crossing check)
reg signed [32:0] sin_data_scaled_ch [NCO_CHANNELS-1 : 0];
wire signed [15:0] sin_data_DAC_ch [NCO_CHANNELS-1 : 0];
integer h;

reg [2:0] sel_nco_out_dac;
always @(posedge clk_50) begin
    if (reset) begin     
        sel_nco_out_dac <= 3'd0;
        for (h=0; h<NCO_CHANNELS; h=h+1) begin
            sin_data_scaled_ch[h] <= 32'd0;
        end     
    end
    else if (out_valid_nco) begin
        sel_nco_out_dac <= sel_nco_out_dac + 1'b1;
        sin_data_scaled_ch[sel_nco_out_dac] <= sin_data_nco * $signed({{1'b0},wfm_amplitude_ch[sel_nco_out_dac]}); //Q2.31 (Q1.15*Q1.16) here in order to use 1 dsp      
    end
end
genvar k;
generate
    for (k = 0; k < NCO_CHANNELS ; k = k+1) begin : loop_scaling
        assign sin_data_DAC_ch[k] = (data_scaled_ch_valid[k])? sin_data_scaled_ch[k][31-:16] : 16'd0; //Q1.15
    end
endgenerate

// two extra clock latency cycles compared to the old implementation for the sum of the outputs
reg signed [18:0] sum_0, sum_1, sum_tot; //3 bit growth for 8 sums
always @(posedge clk_50) begin
    if (reset) begin
        sum_0 <= 0;
        sum_1 <= 0;
        sum_tot <= 0;
    end
    else begin
        sum_0 <= sin_data_DAC_ch[0] + sin_data_DAC_ch[1] + sin_data_DAC_ch[2] + sin_data_DAC_ch[3];
        sum_1 <= sin_data_DAC_ch[4] + sin_data_DAC_ch[5] + sin_data_DAC_ch[6] + sin_data_DAC_ch[7];
        sum_tot <= sum_0 + sum_1;
    end
end
assign data_DAC = ((sum_tot[18]==sum_tot[17]) && (sum_tot[18]==sum_tot[16]) && (sum_tot[18]==sum_tot[15]))?
                    sum_tot[15:0] : {sum_tot[18],{15{!sum_tot[18]}}}; //overflow logic


///////////// LATENCY //////////////////
//this is when sin_data_scaled_ch is valid, one cycle after sin_data_nco and cos_data_nco are valid 
//+1 for the input multiplexing and again +1 for the multiplication
wire [NCO_CHANNELS-1 : 0] data_scaled_ch_valid;
shift_register_parallel  #(.MAX_LENGTH(16), .BIT_WIDTH(NCO_CHANNELS)) sweep_valid(
	.clock(clk_50),
	.reset(reset),
	.enable(1'b1),
	.length(1 + NCO_latency + 1),
	.data_in(NCO_ch_enable),
	.data_out(data_scaled_ch_valid)
);


//This is when the value to the DAC is valid, 2 clocks after the multiplication for the 2 stage sum
shift_register_delayer  #(.MAX_LENGTH(4)) DAC_data_valid(
	.clock(clk_50),
	.reset(reset),
	.enable(1'b1),
	.length(2'd2), 
	.data_in(|data_scaled_ch_valid),
	.data_out(data_DAC_valid)
);

// This signals when the data coming from the ADC is actually in phase with what is getting out of the DAC for the lockin
// this accounts for the NCO latency, the multiplication latency, the sum latency (then the signal goes to the DAC logic)
//  +ADC_delay accounts for the DAC logic and physical delays in the ADC IC/deserializer
shift_register_parallel  #(.MAX_LENGTH(128), .BIT_WIDTH(NCO_CHANNELS)) ADC_acquire_delayer(
	.clock(clk_50),
	.reset(reset),
	.enable(1'b1),
	.length(1 + NCO_latency + 1 + 2 + ADC_delay),
	.data_in(NCO_ch_enable),
	.data_out(ADC_acquire)
);
// This tells the lockin to sample his output, which has to account for the delays of ADC_acquire + the lockin -1
// the -1 is to synch it with the last sample of the prev. freq and not the first of the new one
shift_register_parallel  #(.MAX_LENGTH(128), .BIT_WIDTH(NCO_CHANNELS)) XY_acquire_delayer(
	.clock(clk_50),
	.reset(reset),
	.enable(1'b1),
	.length(1 + NCO_latency + 1 + 2 +ADC_delay),
	.data_in(XY_ch_acquire),
	.data_out(XY_acquire)
);

wire [31:0] frequency_current;
wire [31:0] sinc_cos_wfm_temp;

// This delays the frequency driving the NCO in order to send it to the lockin in phase with the ADC data coming in
// the initial +1 is missing beacuse this signal comes after the NCO input mux
// there is a final -1 to account for the demultiplexing following this signal (which adds 1 delay and so sync it with "ADC_acquire")
//Sizes to use 1 M10k
shift_register_ram_based  #(
    .MAX_LENGTH(256),	//Max length of the moving average
    .DATA_BITS(32) //Bits of the words in the shift registers
) shift_register_freq (
    .clock(clk_50),
    .reset(reset),
    .enable(1'b1),	//keep the shift register always flowing, the validity is defined by the sweep_out_valid
    .length(NCO_latency + 1 + 2 + ADC_delay-1), //To sync the freq with the outputs from the NCO and then of the shift_register_wfm (-1 for the demux)
    //.data_in(frequency_modulation_nco+frequency_initial_nco),
    .data_in(frequency_initial_nco),
    .data_out(frequency_current)
);

// As frequency_current but with a signal coming from the NCO output, so NCO,latency is not needed
//Sizes to use 1 M10k
shift_register_ram_based  #(
    .MAX_LENGTH(128),
    .DATA_BITS(32) 
) shift_register_wfm (
    .clock(clk_50),
    .reset(reset),
    .enable(1'b1),
    .length(1 + 2 + ADC_delay-1), 
    .data_in({sin_data_nco, cos_data_nco}),
    .data_out(sinc_cos_wfm_temp)
);

//to sync outvalid NCO with the shift_register_wfm for the demultiplexing 
wire out_valid_nco_lockin;
shift_register_parallel #(
    .MAX_LENGTH(128),
    .BIT_WIDTH(3) 
) shift_register_wfm_valid( 
	.clock(clk_50),
	.reset(reset),
	.enable(1'b1),
	.length(1 + 2 + ADC_delay - 1),// -1), //-1 for the demux (it has to be the same of shift_register_wfm)
	.data_in(sel_nco_out_dac),
	.data_out(sel_nco_out_lockin)
);

//demultiplexing the output of the NCO
reg [63:0] output_wfm_ch [NCO_CHANNELS-1 : 0];
wire [2:0] sel_nco_out_lockin;
always @(posedge clk_50) begin
    if (reset) begin
        for (h=0; h<NCO_CHANNELS; h=h+1) begin
            output_wfm_ch[h] <= 64'd0;
        end        
        //sel_nco_out_lockin <= 0;
    end
    else begin
        //sel_nco_out_lockin <= sel_nco_out_lockin + 1'b1;
        output_wfm_ch[sel_nco_out_lockin] <= {frequency_current,sinc_cos_wfm_temp}; //NCO with 30 bit       
    end
end

//shape the signal to be sent to the lockins
assign output_wfm = {output_wfm_ch[7], output_wfm_ch[6], output_wfm_ch[5], output_wfm_ch[4], output_wfm_ch[3], output_wfm_ch[2], output_wfm_ch[1], output_wfm_ch[0]};

endmodule