module Lockin_test(

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

    //digital IO
    output [15:0] aux_io,

    input sfp_rx_0,       
    output sfp_tx_0
);

localparam  LOCKIN_NUMBER = 32;

/////////////// KEY0 bitslip ///////////////////
wire bitslip_in_reg, bitslip_in_debounced;
sync_edge_det sync_stop_start_button(
    .clk(CLOCK_50_B7A),
    .signal_in(!KEY[0]),
    .data_out(bitslip_in_reg)
);
debouncer debouncer_stop_start_button(
    .clk(CLOCK_50_B7A),
    .reset(reset_DAC),
    .data_in(bitslip_in_reg),
    .data_out(bitslip_in_debounced)
);

//inversion because enable is active low while mux2 is active high
assign aux_io[15] = 0;
assign aux_io[13] = 0;
assign aux_io[11] = 0;

assign aux_io[14] = 0;
assign aux_io[12] = 0;
assign aux_io[10] = 0;

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
	.clk(CLOCK_50_B7A),  		    // system clock 50MHz 
	.reset_n(pll_locked), 		// system reset 
    .delay(32'd50_000_000),     // clock cycles to wait after the pll is locked to deassert reset_n
	.delay_reset_n(reset_n) ,
	.start_config(start_config) // start the configuration of the MAC and TRC
);
assign reset = !reset_n;

//////////// UDP core ////////////////
wire rx_xcvr_clk; //125MHz clock used in the decoders


//legacymode
wire mode_nRaw_dem;
wire [2:0]  gain;
wire start_fifo_cmd_125, stop_dac_cmd_125;
wire fifo_rd_ack, fifo_rd_empty;
wire [191:0] fifo_rd_data;

// PML mode
wire [LOCKIN_NUMBER*8 - 1 : 0] lockin_config;
wire [26:0] alpha;
wire [31:0] start_fifo_cmd_2_125, stop_dac_cmd_2_125;
wire [31:0] clr_fifo_cmd_2, fifo_wr_2, fifo_full_2;
wire [191:0] sweep_data;
wire filter_order_125;

// Acquisition FIFOs for legacy mode and PML
wire acq_rdreq_fifo_legacy, acq_rdempty_fifo_legacy;
wire [107:0] acq_rddata_fifo_legacy;
wire acq_rdreq_fifo_PML, acq_rdempty_fifo_PML;
wire [107:0] acq_rddata_fifo_PML;

wire [26:0] pi_kp_coefficient;
wire [26:0] pi_ti_coefficient;
wire [26:0] pi_setpoint;
wire [13:0] pi_limit_HI;
wire [13:0] pi_limit_LO;

`define wire_doubleClock(inputClk, outputClk, stretchEdgeName, wire_inputClk, wire_outputClk) \
    wire wire_inputClk, wire_outputClk;                                                       \
stretcher_edge_det stretchEdgeName (                                                          \
    .clk_a(inputClk),                                                                         \
    .clk_b(outputClk),                                                                        \
    .data_in_a(wire_inputClk),                                                                \
    .data_out_b(wire_outputClk)                                                               \
);
`wire_doubleClock(rx_xcvr_clk, ADC_outclock_50, stretcher_pi_enable_cmd, pi_enable_cmd_125, pi_enable_cmd_50)
`wire_doubleClock(rx_xcvr_clk, ADC_outclock_50, stretcher_pi_reset_cmd, pi_reset_cmd_125, pi_reset_cmd_50)
`wire_doubleClock(rx_xcvr_clk, ADC_outclock_50, stretcher_pi_kp_coefficient_update_cmd, pi_kp_coefficient_update_cmd_125, pi_kp_coefficient_update_cmd_50)
`wire_doubleClock(rx_xcvr_clk, ADC_outclock_50, stretcher_pi_ti_coefficient_update_cmd, pi_ti_coefficient_update_cmd_125, pi_ti_coefficient_update_cmd_50)
`wire_doubleClock(rx_xcvr_clk, ADC_outclock_50, stretcher_pi_setpoint_update_cmd, pi_setpoint_update_cmd_125, pi_setpoint_update_cmd_50)


network_wrapper #(.LOCKIN_NUMBER(LOCKIN_NUMBER)) network_wrapper_0 (
    .clock_100(clock_100),
    .ref_clk_125(REFCLK_125),
    .rx_xcvr_clk(rx_xcvr_clk),  //output
    .reset(reset),
    .start_mac_trc_config(start_config),

    .sfp_rx_0(sfp_rx_0),
    .sfp_tx_0(sfp_tx_0),

    // GENERAL PARAMETERS //
    .pi_enable_cmd(pi_enable_cmd_125),

    .pi_reset_cmd(pi_reset_cmd_125),

    .pi_kp_coefficient(pi_kp_coefficient),
    .pi_kp_coefficient_update_cmd(pi_kp_coefficient_update_cmd_125),
    .pi_ti_coefficient(pi_ti_coefficient),
    .pi_ti_coefficient_update_cmd(pi_ti_coefficient_update_cmd_125),
    .pi_setpoint(pi_setpoint),
    .pi_setpoint_update_cmd(pi_setpoint_update_cmd_125),
    .pi_limit_HI(pi_limit_HI),
    .pi_limit_LO(pi_limit_LO),
    // DACs and ADC status
//    .DAC_running(DAC_running_125),
//    .DAC_stopped(DAC_stopped_125),
    .DAC_running(1'b0),
    .DAC_stopped(1'b1),
    .ADC_ready(ADC_ready_125),
	 .SW(SW),
	 .KEY(KEY)
);
////////// TEST NCO_8CH ///////////
wire[8*64-1:0] output_wfm;
wire[15:0] dac_data_PML;
wire dac_data_PML_valid;
wire [7:0] ADC_acquire2, XY_acquire2;
NCO_8ch NCO_8ch (
    .clk_50(ADC_outclock_50),
    .reset(reset_DAC),
    //Commands
    .start_cmd(start_fifo_cmd_2_50),
    .stop_cmd(stop_dac_cmd_2_50),
    //controller status:
    
    //Sweep FIFO (all @ 125MHz)
    .clr_fifo_cmd(clr_fifo_cmd_2),
    .clk_udp(rx_xcvr_clk),
    .sweep_data_udp(sweep_data),
    .fifo_wr_udp(fifo_wr_2),
    .fifo_full_udp(fifo_full_2),
    
    //ADC sync
    .ADC_delay(dem_delay),
    .ADC_acquire(ADC_acquire2),
    .XY_acquire(XY_acquire2),
    //ouptut wfm delayed for demodulation
    .output_wfm(output_wfm),

    //output wfm for DACs
    .data_DAC(dac_data_PML),
    .data_DAC_valid(dac_data_PML_valid)
);

wire filter_order_50;
parallel_data_processor #(.LOCKIN_NUMBER(LOCKIN_NUMBER)) parallel_data_processor (
    .clk_adc(ADC_outclock_50),
    .clk_adc_fast(ADC_outclock_100),
    .reset(reset_DAC),
    .filter_order(filter_order_50),

    .lockin_config(lockin_config),

    .input_data({input_D_data, input_C_data, input_B_data, input_A_data}),

    .alpha(alpha),

    .ADC_acquire(ADC_acquire2),
    .XY_acquire(XY_acquire2),
    .NCOs_wfm(output_wfm),

    .clk_udp(rx_xcvr_clk),
    .acq_rddata_fifo_108(acq_rddata_fifo_PML),
    .acq_rdempty_fifo_108(acq_rdempty_fifo_PML),
    .acq_rdreq_fifo_108(acq_rdreq_fifo_PML)
);

/////////////// SYNC ////////////////
//this is used for values changing at run time
//all the other paramenters come directly from the 125 MHz domanin
//without any register, since they change only when not beeing used
wire start_fifo_cmd_50, stop_dac_cmd_50;
wire DAC_running_125, ADC_ready_125;
wire DAC_running_50_fb; //feedback on the DAC running 125 to be sure the signal has arrived before starting
wire [31:0] start_fifo_cmd_2_50, stop_dac_cmd_2_50;

clock_synchronizer clock_synchronizer_inst(
    .clk_125(rx_xcvr_clk),
    .clk_50(ADC_outclock_50),

    //LEGACY controls
    .start_fifo_cmd_125(start_fifo_cmd_125),
    .start_fifo_cmd_50(start_fifo_cmd_50),
    .stop_dac_cmd_125(stop_dac_cmd_125),
    .stop_dac_cmd_50(stop_dac_cmd_50),

    //PML control
    .start_fifo_cmd_2_125(start_fifo_cmd_2_125),
    .start_fifo_cmd_2_50(start_fifo_cmd_2_50),
    .stop_dac_cmd_2_125(stop_dac_cmd_2_125),
    .stop_dac_cmd_2_50(stop_dac_cmd_2_50),
    .filter_order_125(filter_order_125),
    .filter_order_50(filter_order_50),

    //GENERAL signals
    .DAC_running_50(DAC_running_50),
    .DAC_running_125(DAC_running_125),
    .DAC_running_50_fb(DAC_running_50_fb),//feedback for DAC_running_125
    .DAC_stopped_50(DAC_stopped_50),
    .DAC_stopped_125(DAC_stopped_125),
    .DAC_stopped_50_fb(DAC_stopped_50_fb),//feedback for DAC_stopped_125
    .ADC_ready_50(ADC_ready_50),
    .ADC_ready_125(ADC_ready_125)
);

///////////////// DACs /////////////////////////

wire DAC_running_50 = 1;
wire ADC_acquire, XY_acquire;
wire [79:0] sweep_freq_wfm;
wire [15:0] controllerOut;
wire [15:0] ray;
wire controllerOut_valid;
tweezerController#(
	.inputBitSize			(16),
	.inputFracSize		(15),
	.outputBitSize		(16),
	.outputFracSize		(15),
	.coeffBitSize			(26),
	.coeffFracSize		(25),
	.workingBitSize		(24),	
	.workingFracSize	(20)
)tc(
	.clk												(ADC_outclock_50),
	.reset											(reset_50),
	.XDIFF											(input_A_data),
	.YDIFF											(input_B_data),
	.SUM												(0),
	.retroactionController						(controllerOut),
	.retroactionController_valid				(controllerOut_valid),
	.PI_reset										(pi_reset_cmd_50 | SW[1]),
	.PI_enable										(pi_enable_cmd_50 | SW[2]),
	.PI_freeze										(SW[8]),
	.PI_kp											(pi_kp_coefficient),
	.PI_ki											(pi_ti_coefficient),
	.PI_kp_update									(pi_kp_coefficient_update_cmd_50),
	.PI_ki_update									(pi_ti_coefficient_update_cmd_50),
	.PI_setpoint									(pi_setpoint)
	,
	.ray(ray),
	.addFeedback(SW[0]),
	.leds(LEDR[7:4])
);


dacs_ad5541a dacs_ad5541a_0 (
    .clock(ADC_outclock_50),
    .reset(reset_DAC),

    .dac1_datain(16'h8000),//setpoint per l'output shift
    .dac2_datain(controllerOut+16'h8000),
    .dac3_datain(input_A_data+16'h8000),
    .dac4_datain(ray+16'h8000),
    // .dac1_datain(16'h8000),
    // .dac2_datain(sweep_data+16'h8000),
    // .dac3_datain(sweep_data+16'h8000),
    // .dac4_datain(sweep_data+16'h8000),

    .select_dac(3'b100), //all dacs enabled
    .start(!reset_DAC),
    .busy(dac_busy),

    .sclk(DAC_SCK),
    .ldac_n(/*DAC_LDAC_N*/),
    .dac_sdo(DAC_SDO),
    .cs_n(DAC_CS_N)
);

/////////// FAST ADC and LOCKIN ///////////////
//CDC of the reset to the 50 MHz clock domain from the 100MHz of the pll
wire reset_50;
sync_edge_det sync_edge_det_reset(
    .clk(CLOCK_50_B7A),
    .signal_in(reset),
    .data_out(reset_50)
);

wire ADC_outclock_50, ADC_ready_50, ADC_outclock_100;
wire reset_DAC;

wire [15:0] input_A_data, input_B_data, input_C_data, input_D_data;

ADC_FAST_wrapper ADC_FAST_wrapper_0 (
    .clk_50(CLOCK_50_B7A),
    .ADC_outclock_50(ADC_outclock_50),
    .ADC_outclock_100(ADC_outclock_100),
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

reg [15:0] input_main_data_processor;

always @(*) begin
    case (SW[8:7])
        2'b00: input_main_data_processor <= input_D_data;
        2'b01: input_main_data_processor <= input_C_data;
        2'b10: input_main_data_processor <= input_B_data;
        2'b11: input_main_data_processor <= input_A_data;
        default: input_main_data_processor <= input_A_data;
    endcase
end

wire [31:0] X_reg, Y_reg;
data_processor main_data_processor (
    .clk_adc(ADC_outclock_50),
    .clk_adc_fast(ADC_outclock_100),
    .clk_udp(rx_xcvr_clk),
    .reset(reset_50),
    .mode_nRaw_dem(mode_nRaw_dem),
    .gain(gain),

    .ADC_data_in(input_main_data_processor),
    .ADC_data_out(input_C_data),
    .SW(SW[9]),

    .ADC_acquire(ADC_acquire),
    .XY_acquire(XY_acquire),
    .sweep_freq_wfm(sweep_freq_wfm),

    .acq_rddata_fifo_108(acq_rddata_fifo_legacy),
    .acq_rdempty_fifo_108(acq_rdempty_fifo_legacy),
    .acq_rdreq_fifo_108(acq_rdreq_fifo_legacy)
);

////////////////// STATUS //////////////

assign HEX3 = 'h55;
assign HEX2 = 'hAA;
assign HEX1 = 'h55;
assign HEX0 = 'hAA;


assign LEDG[0] = pll_locked;
assign LEDG[1] = reset_n;
assign LEDG[2] = ~reset_DAC;
assign LEDG[7] = DAC_running_50;


wire inputD_saturating = (input_D_data == 16'h7FFF) || (input_D_data == 16'h8000);
wire inputC_saturating = (input_C_data == 16'h7FFF) || (input_C_data == 16'h8000);
wire inputB_saturating = (input_B_data == 16'h7FFF) || (input_B_data == 16'h8000);
wire inputA_saturating = (input_A_data == 16'h7FFF) || (input_A_data == 16'h8000);
assign LEDR[3:0] = {inputD_saturating, inputC_saturating, inputB_saturating, inputA_saturating};



endmodule
