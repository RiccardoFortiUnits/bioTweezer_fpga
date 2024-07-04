`include "adc_config/ADC_configurator.v"
`include "ADC_data_adder.v"
`include "LMK/lmk_conf.v"
`include "adc_config/adc_aligner.v"
`include "ADC_data_moving_average.v"

module ADC_FAST_wrapper (
    input   	clk_50,
    input   	reset,
	output reg	ADC_outclock_50,	
	output		ADC_outclock_100,
	output		reset_DAC,
	output		ADC_ready,

    // LMK configuration
    input   start_conf,
    inout   lmk_i2c_sda,
	inout   lmk_i2c_scl,

	// ADC SPI interface
	output 	adc_spi_sclk,
	inout 	adc_spi_sdio,
	output	adc_spi_csb,

	// ADC LVDS interface
	input 		adc_fclk,
	input [1:0] adc_ch_A,
	input [1:0] adc_ch_B,
	input [1:0] adc_ch_C,
	input [1:0] adc_ch_D,

	output reg [15:0] input_A_data, 
	output reg [15:0] input_B_data, 
	output reg [15:0] input_C_data, 
	output reg [15:0] input_D_data
);

wire lmk_done;
//ADC clock configuration
lmk_conf lmk_conf (
	.clk(clk_50),
	.reset(reset),

	.start(start_conf),
	.done(lmk_done),

	.i2c_sda(lmk_i2c_sda), 
	.i2c_scl(lmk_i2c_scl)   
);
// i2c_wrapper #(.CLK_FREQ(50000000), .I2C_FREQ(100000)) i2c_wrapper_fmc(
//     .clk(clk_50),
//     .reset(reset),

//     .start(start_conf),
//     .done(lmk_done),

//     .i2c_sda(lmk_i2c_sda),
//     .i2c_scl(lmk_i2c_scl)
// );

//Wait after clock configuration
wire lmk_done_delayed;
delayer #(.BIT_WIDTH(32)) lmk_delayer (
	.clk(clk_50),
	.reset(reset),
	.in(lmk_done),
	.delay(32'd100000000), //wait for 2 seconds
	.out(lmk_done_delayed)
);

//ADC SPI configuration
wire config_done;
ADC_configurator ADC_configurator_0(
		.clk(clk_50),
		.reset(reset),
		.start(lmk_done_delayed),
		
		.ADC_ready(config_done),

		// SPI connections
		.cs_n(adc_spi_csb),
		.sclk(adc_spi_sclk),
		.data_adc(adc_spi_sdio)
);

//ADC LVDS
wire adc_lvds_pll_locked;
wire signed [15:0] ch_A_data, ch_B_data, ch_C_data, ch_D_data;
adc_lvds adc_lvds_0 (
	.pll_areset(~config_done),
	.rx_in({adc_ch_A, adc_ch_B, adc_ch_C, adc_ch_D}),
	.rx_inclock(adc_fclk),
	.rx_locked(adc_lvds_pll_locked),
	.rx_out({ch_A_data, ch_B_data, ch_C_data, ch_D_data}),
	.rx_outclock(ADC_outclock_100)
);

//Wait for the deserializer to be locked and stable
wire adc_lvds_pll_locked_reg;
delayer #(.BIT_WIDTH(32)) deserializer_delayer (
	.clk(ADC_outclock_100),
	.reset(reset),
	.in(adc_lvds_pll_locked),
	.delay(32'd50000000), //wait for 0.5 seconds
	.out(adc_lvds_pll_locked_reg)
);

//Generate the 50MHz clock from the ADCs
always @(posedge ADC_outclock_100 ) begin
	if (!adc_lvds_pll_locked_reg) begin
		ADC_outclock_50 <= 1'b0;
	end
	else begin
		ADC_outclock_50 <= !ADC_outclock_50;
	end
end

wire adc_lvds_pll_locked_reg_2;
delayer #(.BIT_WIDTH(32)) deserializer_delayer_2 (
	.clk(ADC_outclock_100),
	.reset(reset),
	.in(adc_lvds_pll_locked_reg),
	.delay(32'd50000000), //wait for 0.5 seconds
	.out(adc_lvds_pll_locked_reg_2)
);

//Generate ADC ready and reset signal
sync_edge_det sync_edge_det_adc_data_aligned(
    .clk(ADC_outclock_50),
    .signal_in(adc_lvds_pll_locked_reg_2),
    .data_out(ADC_ready)
);
assign reset_DAC = !ADC_ready;

//ADC moving average @100MHz to have averaged samples @50MHz
wire signed [15:0] ch_A_data_100;
ADC_data_moving_average ADC_data_moving_average_A(
    .clock_100(ADC_outclock_100),    
    .data_in(ch_A_data),
    .data_out(ch_A_data_100)
);
wire signed [15:0] ch_B_data_100;
ADC_data_moving_average ADC_data_moving_average_B(
    .clock_100(ADC_outclock_100),    
    .data_in(ch_B_data),
    .data_out(ch_B_data_100)
);
wire signed [15:0] ch_C_data_100;
ADC_data_moving_average ADC_data_moving_average_current(
    .clock_100(ADC_outclock_100),   
    .data_in(ch_C_data),
    .data_out(ch_C_data_100)
);
wire signed [15:0] ch_D_data_100;
ADC_data_moving_average ADC_data_moving_average_Z(
    .clock_100(ADC_outclock_100),    
    .data_in(ch_D_data),
    .data_out(ch_D_data_100)
);

always @(posedge ADC_outclock_50) begin
	input_A_data <= ch_A_data_100;
	input_B_data <= ch_B_data_100;
	input_C_data <= ch_C_data_100;
	input_D_data <= ch_D_data_100;
end
    
endmodule