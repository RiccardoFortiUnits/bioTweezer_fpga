module H_Cube_test(

	//////////// CLOCK //////////
	input						REFCLK_125,
	input 		          		CLOCK_125_p,
	input 		          		CLOCK_50_B5B,
	input 		          		CLOCK_50_B6A,
	input 		          		CLOCK_50_B7A,
	input 		          		CLOCK_50_B8A,

	//////////// LED //////////
	output		     [7:0]		LEDG,
	output		     [9:0]		LEDR,

	//////////// KEY //////////
	input 		          		CPU_RESET_n,
	input 		     [3:0]		KEY,

	//////////// SW //////////
	input 		     [9:0]		SW,

	//////////// SEG7 //////////
	output		     [6:0]		HEX0,
	output		     [6:0]		HEX1,
	output		     [6:0]		HEX2,
	output		     [6:0]		HEX3,

	//////////// I2C for Audio/HDMI-TX/Si5338/HSMC //////////
	//output		          		I2C_SCL,
	//inout 		          		I2C_SDA,

	// 4 DACs
    output DAC_SCK,
    output [3:0] DAC_CS_N,
    output [3:0] DAC_SDO,

    //ADC interface
    input adc_fclk,
	input [1:0] adc_ch_A,
	input [1:0] adc_ch_B,
	input [1:0] adc_ch_C,
	input [1:0] adc_ch_D,

	// ADC SPI interface
	output adc_spi_sclk,
	inout adc_spi_sdio,
	output adc_spi_csb,
	//output adc_spi_sync,

	// I2C clock source interface
	inout lmk_i2c_sda,
	inout lmk_i2c_scl,   

    input sfp_rx_0,       
    output sfp_tx_0
);

/////////// PLL initialization ////////////

wire clock_100;
wire pll_locked;

pll pll_0 (
    .refclk(CLOCK_50_B7A),   //  refclk.clk
    .rst(!CPU_RESET_n),      //   reset.reset
    .outclk_0(clock_100), // outclk0.clk
    .locked(pll_locked)    //  locked.export
);

// Initial reset upon pll startup
wire reset, reset_n;
wire start_config;
initial_reset initial_reset_0
(
	.clk(clock_100),  		    // system clock 50MHz 
	.reset_n(pll_locked), 		// system reset 
    .delay(32'd50_000_000),     // clock cycles to wait after the pll is locked to deassert reset_n
	.delay_reset_n(reset_n) ,
	.start_config(start_config) // start the configuration of the MAC and TRC
);
assign reset = !reset_n;

//////////// UDP core ////////////////
wire rx_xcvr_clk; //125MHz clock used in the decoders

wire mode_nCont_disc, mode_nRaw_dem;
wire [2:0]  gain;
wire [15:0] wfm_amplitude, dem_delay;
wire [31:0] frequency_initial,frequency_final,step_counter;
wire [63:0] frequency_step;

wire fifo_rd_ack, fifo_rd_empty;
wire [195:0] fifo_rd_data;

wire start_fifo_cmd_125, start_dac_cmd_125, stop_dac_cmd_125;

wire acq_rdreq_fifo_108, acq_rdempty_fifo_108;
wire [107:0] acq_rddata_fifo_108;

network_wrapper network_wrapper_0 (
    .clock_100(clock_100),
    .ref_clk_125(REFCLK_125),
    .rx_xcvr_clk(rx_xcvr_clk),  //output
    .reset(reset),
    .start_mac_trc_config(start_config),

    .sfp_rx_0(sfp_rx_0),
    .sfp_tx_0(sfp_tx_0),
    
    .mode_nCont_disc(mode_nCont_disc),
    .mode_nRaw_dem(mode_nRaw_dem),

    //parameters
    .frequency_initial(frequency_initial),
    .frequency_final(frequency_final),
    .frequency_step(frequency_step),
    .step_counter(step_counter),
    .wfm_amplitude(wfm_amplitude),
    .gain(gain),
    .dem_delay(dem_delay),

    //fifo parameters
    .fifo_rd_clk(ADC_outclock_50),
    .fifo_rd_ack(fifo_rd_ack),
    .fifo_rd_data(fifo_rd_data),
    .fifo_rd_empty(fifo_rd_empty),

    //acq mode commands
    .start_fifo_cmd(start_fifo_cmd_125),
    .start_dac_cmd(start_dac_cmd_125),
    .stop_dac_cmd(stop_dac_cmd_125),

    // DACs and ADC status
    .DAC_running(DAC_running_125),
    .ADC_ready(ADC_ready_125),

    // acq FIFO
	.acq_rdreq_fifo_108(acq_rdreq_fifo_108),
	.acq_rddata_fifo_108(acq_rddata_fifo_108),
	.acq_rdempty_fifo_108(acq_rdempty_fifo_108)
);

/////////////// SYNC ////////////////
//this is used for values changing at run time
//all the other paramenters come directly from the 125 MHz domanin
//without any register, since they change only when not beeing used
wire start_fifo_cmd_50, start_dac_cmd_50, stop_dac_cmd_50;
wire DAC_running_125, ADC_ready_125;
wire DAC_running_50_fb; //feedback on the DAC running 125 to be sure the signal has arrived before starting

clock_synchronizer clock_synchronizer_inst(
    .clk_125(rx_xcvr_clk),
    .clk_50(ADC_outclock_50),

    .start_fifo_cmd_125(start_fifo_cmd_125),
    .start_fifo_cmd_50(start_fifo_cmd_50),
    .start_dac_cmd_125(start_dac_cmd_125),    
    .start_dac_cmd_50(start_dac_cmd_50),
    .stop_dac_cmd_125(stop_dac_cmd_125),
    .stop_dac_cmd_50(stop_dac_cmd_50),

    .DAC_running_50(DAC_running_50),
    .DAC_running_125(DAC_running_125),
    .DAC_running_50_fb(DAC_running_50_fb),//feedback for DAC_running_125
    .ADC_ready_50(ADC_ready_50),
    .ADC_ready_125(ADC_ready_125)
);

///////////////// DACs /////////////////////////

wire DAC_running_50, ADC_acquire;
wire [79:0] sweep_freq_wfm;

DAC_wrapper DAC_wrapper_0 (
    .clk_50(ADC_outclock_50),
    .reset(reset_DAC),

    .start_fifo_cmd(start_fifo_cmd_50),
    .start_dac_cmd(start_dac_cmd_50),
    .stop_dac_cmd(stop_dac_cmd_50),// || ~(|KEY)), 
    
    .running(DAC_running_50),
    .running_fb(DAC_running_50_fb),

    .DAC_SCK(DAC_SCK),
    .DAC_CS_N(DAC_CS_N),
    .DAC_SDO(DAC_SDO),

    .mode_nCont_disc(mode_nCont_disc),

    .ADC_acquire(ADC_acquire),
    .sweep_freq_wfm(sweep_freq_wfm),

    .SW(SW[3:0]),
    .frequency_initial(frequency_initial),
    .frequency_final(frequency_final),
    .frequency_step(frequency_step),
    .step_counter(step_counter),
    .wfm_amplitude(wfm_amplitude),
    .dem_delay(dem_delay),

    //fifo parameters
    .fifo_rd_ack(fifo_rd_ack),
    .fifo_rd_data(fifo_rd_data),
    .fifo_rd_empty(fifo_rd_empty)
);

/////////// FAST ADC and LOCKIN ///////////////
//CDC of the reset to the 50 MHz clock domain from the 100MHz of the pll
wire reset_50;
sync_edge_det sync_edge_det_reset(
    .clk(CLOCK_50_B7A),
    .signal_in(reset),
    .data_out(reset_50)
);

wire ADC_outclock_50, ADC_ready_50;
wire reset_DAC;

wire [15:0] input_A_data, input_B_data, input_C_data, input_D_data;

ADC_FAST_wrapper ADC_FAST_wrapper_0 (
    .clk_50(CLOCK_50_B7A),
    .ADC_outclock_50(ADC_outclock_50),
    .reset(reset_50),
    .reset_DAC(reset_DAC),
    .ADC_ready(ADC_ready_50),

    .start_conf(!reset_50),
	.lmk_i2c_sda(lmk_i2c_sda), 
	.lmk_i2c_scl(lmk_i2c_scl),

    .adc_spi_sclk(adc_spi_sclk),
    .adc_spi_sdio(adc_spi_sdio),
    .adc_spi_csb(adc_spi_csb),

    .adc_fclk(adc_fclk),
	.adc_ch_A(adc_ch_A),
	.adc_ch_B(adc_ch_B),
	.adc_ch_C(adc_ch_C),
	.adc_ch_D(adc_ch_D),

    .input_A_data(input_A_data),
    .input_B_data(input_B_data),
    .input_C_data(input_C_data),
    .input_D_data(input_D_data)      
);

data_processor main_data_processor (
    .clk_adc(ADC_outclock_50),
    .clk_udp(rx_xcvr_clk),
    .reset(reset_50),

    .mode_nCont_disc(mode_nCont_disc),
    .mode_nRaw_dem(mode_nRaw_dem),
    .gain(gain),

    .ADC_data_in(input_D_data),
    .ADC_data_out(input_C_data),
    .SW(SW[9]),

    .ADC_acquire(ADC_acquire),
    .sweep_freq_wfm(sweep_freq_wfm),

    .acq_rddata_fifo_108(acq_rddata_fifo_108),
    .acq_rdempty_fifo_108(acq_rdempty_fifo_108),
    .acq_rdreq_fifo_108(acq_rdreq_fifo_108)
);

// wire [5:0] data_out_single_carry ;

// //ALT_INBUF KEY_IN (.i(KEY[0]), .o(data_out_single_carry [0])); 

// assign data_out_single_carry[0] = KEY[0];

// CARRY_SUM CARRY_0 (
//     .sin(1), 
//     .cin(data_out_single_carry [0]),  //<carry_in> cannot be fed by an input pin
//     .cout(data_out_single_carry[1]) //<carry_out> cannot feed an output pin
// );

// CARRY_SUM CARRY_1 (
//     .sin(1), 
//     .cin(data_out_single_carry[1]),  //<carry_in> cannot be fed by an input pin
//     .cout(data_out_single_carry[2]) //<carry_out> cannot feed an output pin
// );

// CARRY_SUM CARRY_2(
//     .sin(1), 
//     .cin(data_out_single_carry[2]),  //<carry_in> cannot be fed by an input pin
//     .cout(data_out_single_carry[3]) //<carry_out> cannot feed an output pin
// );

// CARRY_SUM CARRY_3 (
//     .sin(1), 
//     .cin(data_out_single_carry[3]),  //<carry_in> cannot be fed by an input pin
//     .cout(data_out_single_carry[4]) //<carry_out> cannot feed an output pin
// );

// CARRY_SUM CARRY_4 (
//     .sin(1), 
//     .cin(data_out_single_carry[4]),  //<carry_in> cannot be fed by an input pin
//     .cout(data_out_single_carry[5]) //<carry_out> cannot feed an output pin
// );

// genvar i;
// generate
// 	for (i = 1; i <= 15; i = i + 1) begin : cascade
// 		CARRY_SUM CARRY (
//             .sin(0), 
//             .cin(data_out_single_carry[i-1]),  //<carry_in> cannot be fed by an input pin
//             .cout(data_out_single_carry[i]) //<carry_out> cannot feed an output pin
//         );
// 	end
// endgenerate

// reg [5:0] data_out_single_carry_reg ;

// genvar i;
// generate
// 	for (i = 0; i <= 5; i = i + 1) begin : cascade
//         always @(posedge clock_100 ) begin
//             data_out_single_carry_reg[i] <= data_out_single_carry[i];
//         end
//         assign LEDR = data_out_single_carry_reg;
// 	end
// endgenerate

////////////////// STATUS //////////////

assign HEX3 = 'h55;
assign HEX2 = 'hAA;
assign HEX1 = 'h55;
assign HEX0 = 'hAA;


assign LEDG[0] = pll_locked;
assign LEDG[1] = reset_n;
assign LEDG[2] = ~reset_DAC;
assign LEDG[7] = DAC_running_50;

assign LEDR[7:0] = input_A_data[15:8];

//assign LEDR[9:8] = 2'b00;
wire input_saturating = (input_D_data == 16'h7FFF) || (input_D_data == 16'h8000);
//assign LEDR = {9{input_saturating}};



endmodule
