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
wire [25:0] alpha;
wire [31:0] start_fifo_cmd_2_125, stop_dac_cmd_2_125;
wire [31:0] clr_fifo_cmd_2, fifo_wr_2, fifo_full_2;
wire [191:0] sweep_data;
wire filter_order_125;

// Acquisition FIFOs for legacy mode and PML
wire acq_rdreq_fifo_legacy, acq_rdempty_fifo_legacy;
wire [107:0] acq_rddata_fifo_legacy;
wire acq_rdreq_fifo_PML, acq_rdempty_fifo_PML;
wire [107:0] acq_rddata_fifo_PML;

wire [25:0] pi_kp_coefficient;
wire [25:0] pi_ti_coefficient;
wire [15:0] output_when_pi_disabled;
wire [15:0] pi_setpoint;
wire [15:0] pi_limit_HI;
wire [15:0] pi_limit_LO;
wire [15:0] sumForDivision_offset;
wire [25:0] sumForDivision_multiplier;
wire [15:0] z_offset;
wire [25:0] z_multiplier;


`define synchToNewClock(outputClk, stretchEdgeName, wire_inputClk, wire_outputClk) \
sync_edge_det stretchEdgeName(              \
    .clk            (outputClk),            \
    .signal_in      (wire_inputClk),        \
    .data_out       (wire_outputClk),       \
    .rising         (),                     \
    .falling        ()                      \
);
`synchToNewClock(ADC_outclock_50, stretcher_pi_enable_cmd, pi_enable_cmd_125, pi_enable_cmd_50)
`synchToNewClock(ADC_outclock_50, stretcher_pi_reset_cmd, pi_reset_cmd_125, pi_reset_cmd_50)

`define syncPulseToNewClock(inputClk, outputClk, stretchEdgeName, wire_inputClk, wire_outputClk) \
    wire wire_inputClk, wire_outputClk;                                                       \
stretcher_edge_det stretchEdgeName (                                                          \
    .clk_a(inputClk),                                                                         \
    .clk_b(outputClk),                                                                        \
    .data_in_a(wire_inputClk),                                                                \
    .data_out_b(wire_outputClk)                                                               \
);
`syncPulseToNewClock(rx_xcvr_clk, ADC_outclock_50, stretcher_pi_kp_coefficient_update_cmd, pi_kp_coefficient_update_cmd_125, pi_kp_coefficient_update_cmd_50)
`syncPulseToNewClock(rx_xcvr_clk, ADC_outclock_50, stretcher_pi_ti_coefficient_update_cmd, pi_ti_coefficient_update_cmd_125, pi_ti_coefficient_update_cmd_50)
`syncPulseToNewClock(rx_xcvr_clk, ADC_outclock_50, stretcher_output_when_pi_disabled_update_cmd, output_when_pi_disabled_update_cmd_125, output_when_pi_disabled_update_cmd_50)
`syncPulseToNewClock(rx_xcvr_clk, ADC_outclock_50, stretcher_pi_setpoint_update_cmd, pi_setpoint_update_cmd_125, pi_setpoint_update_cmd_50)
`syncPulseToNewClock(rx_xcvr_clk, ADC_outclock_50, stretcher_pi_limit_LO, pi_limit_LO_update_cmd_125, pi_limit_LO_update_cmd_50)
`syncPulseToNewClock(rx_xcvr_clk, ADC_outclock_50, stretcher_pi_limit_HI, pi_limit_HI_update_cmd_125, pi_limit_HI_update_cmd_50)
`syncPulseToNewClock(rx_xcvr_clk, ADC_outclock_50, stretcher_sumForDivision_offset, sumForDivision_offset_update_cmd_125, sumForDivision_offset_update_cmd_50)
`syncPulseToNewClock(rx_xcvr_clk, ADC_outclock_50, stretcher_sumForDivision_multiplier, sumForDivision_multiplier_update_cmd_125, sumForDivision_multiplier_update_cmd_50)
`syncPulseToNewClock(rx_xcvr_clk, ADC_outclock_50, stretcher_z_offset, z_offset_update_cmd_125, z_offset_update_cmd_50)
`syncPulseToNewClock(rx_xcvr_clk, ADC_outclock_50, stretcher_z_multiplier, z_multiplier_update_cmd_125, z_multiplier_update_cmd_50)


wire pi_rdreq_output_fifo, x_rdreq_fifo, y_rdreq_fifo, z_rdreq_fifo, xSquare_rdreq_fifo, ySquare_rdreq_fifo, zSquare_rdreq_fifo;
wire [15:0] pi_rddata_output_fifo, x_rddata_fifo, y_rddata_fifo, z_rddata_fifo, xSquare_rddata_fifo, ySquare_rddata_fifo, zSquare_rddata_fifo;
wire pi_rdempty_output_fifo, x_rdempty_fifo, y_rdempty_fifo, z_rdempty_fifo, xSquare_rdempty_fifo, ySquare_rdempty_fifo, zSquare_rdempty_fifo;

wire [15:0] controllerOut;
wire [15:0] ray;
wire [15:0] x, y, z, xSquare, ySquare, zSquare;

/*how to add custom connections to the network module:
	
	reception: parameter setting
		for setting a parameter from a network command, you need to give to the module a register that will contain the new value of the parameter and
		a bit that will validate the next value
		To avoid having to manually add for each parameter some new inputs and structures in the internal modules, the module network_wrapper 
			takes as input a long register containing all the parameter registers and another containing all the validation bits. The size of these 
			registers is specified through some parametric values of the module, so that the compiler will automatically create the internal structure 
			to manage any number of parameters, with any size of the parameter registers.
			
			to handle large registers (i.e. with size > 16), which will require two transmissions to set the most significant bits and less significant bits,
			a separate couple of long register and validation bits register is available. 
			
			So, to add a new register to the network_wrapper:
				-if the register is longer than 16bits (and shorter than 32)
					-increase the value nOflargeRegisters
					-add to largeRegisterStartIdxs its previous last value plus the size of the new register (es: previously largeRegisterStartIdxs 
						was {32'd52, 32'd26, 32'd0}, and the new register is 20bits, then the new value for largeRegisterStartIdxs 
						is {32'd72, 32'd52, 32'd26, 32'd0} (72=52+20))
					-add the register wire to the output largeRegisters (add on the left)
					-add the validate wire to the output largeRegisters_update_cmd (add on the left)
					
				-if the register is shorter than 16bits, use the "small" registers instead (nOfsmallRegisters, smallRegisters_update_cmd...)
				
			After that, the module will update the values when receiving an UDP request with payload "CPAR" + <param idx> + 0x00 + <new_value>
			the parameter idx (1 byte) is decided as follows:
			first, all large registers, which will take 2 indexes each, one for the MSB and the other for the LSB
			then, all small registers (one idx each)
			
	transmission: data stream
		if enabled, there will be a constant stream of data. The structure of the data of every packet is:
			-header byte: a simple counter that gets updated on every transmission, to check for missing or double packets
			-data to stream, from a list of FIFOs. For now, every FIFO has to have the same bit size (FIFO_LENGTH). Transmission is done whenever 
				all the FIFOs have some data ready (so, manage the filling speed of the FIFOs to change the transimssion rate)
		to add a new FIFO
			-increase nOfFifos
			-add the relative wires to the rdreq_fifo, rddata_fifo and rdempty_fifo registers.
			

*/
network_wrapper #(
	.LOCKIN_NUMBER(LOCKIN_NUMBER),

   .largeRegisterStartIdxs      ({32'd104, 32'd78, 32'd52, 32'd26, 32'd0}),
   .nOflargeRegisters           (4),
   .smallRegisterStartIdxs      ({32'h60, 32'h50, 32'h40, 32'h30, 32'h20, 32'h10, 32'h0}),
   .nOfsmallRegisters           (6),
   .maxTransmissionSize         (16),
	
   .FIFO_LENGTH(16),
   .nOfFifos(7)
	
) network_wrapper_0 (
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
	 
     .largeRegisters             ({z_multiplier, sumForDivision_multiplier, pi_ti_coefficient, pi_kp_coefficient}),
     .largeRegisters_update_cmd  ({z_multiplier_update_cmd_125, sumForDivision_multiplier_update_cmd_125, pi_ti_coefficient_update_cmd_125, pi_kp_coefficient_update_cmd_125}),
     .smallRegisters             ({z_offset, sumForDivision_offset, pi_limit_HI, pi_limit_LO, pi_setpoint, output_when_pi_disabled}),
     .smallRegisters_update_cmd  ({z_offset_update_cmd_125, sumForDivision_offset_update_cmd_125, pi_limit_HI_update_cmd_125, pi_limit_LO_update_cmd_125, pi_setpoint_update_cmd_125, output_when_pi_disabled_update_cmd_125}),
    // DACs and ADC status
//    .DAC_running(DAC_running_125),
//    .DAC_stopped(DAC_stopped_125),
//	 
    .rdreq_fifo	({zSquare_rdreq_fifo,   ySquare_rdreq_fifo,   xSquare_rdreq_fifo,   z_rdreq_fifo,   y_rdreq_fifo,   x_rdreq_fifo,   pi_rdreq_output_fifo}),
    .rddata_fifo	({zSquare_rddata_fifo,  ySquare_rddata_fifo,  xSquare_rddata_fifo,  z_rddata_fifo,  y_rddata_fifo,  x_rddata_fifo,  pi_rddata_output_fifo}),
    .rdempty_fifo	({zSquare_rdempty_fifo, ySquare_rdempty_fifo, xSquare_rdempty_fifo, z_rdempty_fifo, y_rdempty_fifo, x_rdempty_fifo, pi_rdempty_output_fifo}),
//    	 

//    .rdreq_fifo 	  ({xSquare_rdreq_fifo,   ySquare_rdreq_fifo,   y_rdreq_fifo,   x_rdreq_fifo}),
//    .rddata_fifo    ({xSquare_rddata_fifo,  ySquare_rddata_fifo,  y_rddata_fifo,  x_rddata_fifo}),
//    .rdempty_fifo   ({xSquare_rdempty_fifo, ySquare_rdempty_fifo, y_rdempty_fifo, x_rdempty_fifo}),
         
    .DAC_running(1'b0),
    .DAC_stopped(1'b1),
    .ADC_ready(ADC_ready_125),
	 
	 .SW(SW),
	 .KEY(KEY),
//	 .led(LEDR[3:0])
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
wire controllerOut_valid;
tweezerController#(
	.inputBitSize			(16),
	.inputFracSize		(15),
	.outputBitSize		(16),
	.outputFracSize		(15),
	.coeffBitSize			(26),
	.coeffFracSize		(24),		//you can have values between -2 and 1.9999
	.workingBitSize		(28),	
	.workingFracSize	(24)
)tc(
	.clk												(ADC_outclock_50),
	.reset											(reset_50),
	.XDIFF											(input_D_data),//the wires for the circuit are a bit awkward, so I had to shuffle the inputs a bit
	.YDIFF											(input_C_data),
	.SUM												(input_B_data),
	.retroactionController						(controllerOut),
	.retroactionController_valid				(controllerOut_valid),
	.PI_reset										(pi_reset_cmd_50 | SW[1]),
	.PI_enable										(pi_enable_cmd_50 | SW[2]),
	.PI_freeze										(1'b0),
	.PI_kp											(pi_kp_coefficient),
	.PI_ki											(pi_ti_coefficient),
	.PI_kp_update									(pi_kp_coefficient_update_cmd_50),
	.PI_ki_update									(pi_ti_coefficient_update_cmd_50),
	.output_when_pi_disabled					(output_when_pi_disabled),
	.PI_setpoint									(pi_setpoint),
	.pi_limit_HI									(pi_limit_HI),
	.pi_limit_LO									(pi_limit_LO),
	
   .sumForDivision_offset         			(sumForDivision_offset),
   .sumForDivision_multiplier   			  	(sumForDivision_multiplier),
	.z_offset										(z_offset),
	.z_multiplier									(z_multiplier),
   .x                   (x),
   .y                   (y),
   .z                   (z),
   .xSquare            (xSquare),
   .ySquare            (ySquare),
   .zSquare            (zSquare),
	.ray(ray),
	.addFeedback(0),
	.useSUM(1),
//	.leds(LEDR[7:4])
);


dacs_ad5541a dacs_ad5541a_0 (
    .clock(ADC_outclock_50),
    .reset(reset_DAC),

    .dac1_datain(16'h8000),					//setpoint for the output shift
    .dac2_datain(controllerOut+16'h8000),	//PI output
    .dac3_datain(ray+16'h8000),				//calculated ray
    .dac4_datain(x+16'h8000),				//unused (put any debug signal you like)
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

localparam nOfDataPerTransmission = 'h40000;

`define setDataHandler(_in, _enableData, _readRequest, _dataRead, _readEmpty, moduleName) \
dataHandlerForTransmission #(                                                             \
    .dataBitSize                    (16),                                                 \
    .max_nOfDataPerTransmission     (nOfDataPerTransmission),                             \
    .fifoSize                       (32)                                                  \
) moduleName(                                                                             \
    .dataClk                        (ADC_outclock_50),                                    \
    .fifoReadClk                    (rx_xcvr_clk),                                        \
    .reset                          (reset_50 | reset | SW[9] | (!_enableData)),          \
    .nOfDataPerTransmission         (nOfDataPerTransmission),                             \
    .in                             (_in),                                                \
    .enableData                     (_enableData),                                        \
    .readRequest                    (_readRequest),                                       \
    .dataRead                       (_dataRead),                                          \
    .readEmpty                      (_readEmpty),                                         \
);


`setDataHandler(controllerOut , controllerOut_valid, pi_rdreq_output_fifo  , pi_rddata_output_fifo  , pi_rdempty_output_fifo  , handler_controllerOut)
`setDataHandler(x             , controllerOut_valid, x_rdreq_fifo          , x_rddata_fifo          , x_rdempty_fifo          , handler_x            )
`setDataHandler(y             , controllerOut_valid, y_rdreq_fifo          , y_rddata_fifo          , y_rdempty_fifo          , handler_y            )
`setDataHandler(z		         , controllerOut_valid, z_rdreq_fifo          , z_rddata_fifo          , z_rdempty_fifo          , handler_z            )
`setDataHandler(xSquare       , controllerOut_valid, xSquare_rdreq_fifo    , xSquare_rddata_fifo    , xSquare_rdempty_fifo    , handler_xSquare      )
`setDataHandler(ySquare       , controllerOut_valid, ySquare_rdreq_fifo    , ySquare_rddata_fifo    , ySquare_rdempty_fifo    , handler_ySquare      )
`setDataHandler(zSquare       , controllerOut_valid, zSquare_rdreq_fifo    , zSquare_rddata_fifo    , zSquare_rdempty_fifo    , handler_zSquare      )



////////////////// STATUS //////////////
onOffDisplay ood(
	controllerOut_valid,
	HEX0,
	HEX1,
	HEX2
);
assign HEX3 = 'hFF;


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
