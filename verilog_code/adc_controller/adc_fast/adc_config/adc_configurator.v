`include "ADC_spi_interface.v"
`include "AD9653_lut_config.v"

module ADC_configurator(
		input 			clk,
		input 			reset,
		input 			start,		
		
		output reg 		ADC_ready,
		output [7:0] 	data_read,
		output 			data_valid,
		output 			busy,

		// SPI connections
		output 			cs_n,
		output 			sclk,
		inout 			data_adc
);

//LUT for the ADC
wire [12:0] address;
wire [7:0] data_spi;
wire rw;

AD9653_lut_config AD9653_lut_config_1 ( 
	.index(lut_index),
	.pwr(1'b1),	//power-on
	.test_pattern(2'b00), //normal operation
	.sel_chan(4'b1111), //all channels
	
	.data(data_spi), 
	.address(address),
	.rw(rw)
);

// SPI interface for the ADC configuration, write or read one adress at the time
reg start_spi = 1'b0;

ADC_spi_interface ADC_spi_interface_1(
	.clock_50(clk),
	.reset(reset),
	.address(address),
	.rw(rw),
	.width(2'b00),
	.data_write(data_spi),
	.start(start_spi),
	.data_read(data_read),
	.busy(busy),
	.data_valid(data_valid),
	
	//ADC
	.cs_n(cs_n),
	.sclk(sclk),
	.data_adc(data_adc)
);

//////////// FSMs handling the LUT and teh reset sequence ////////////////// 
localparam	LUT_START_RESET_INDEX = 5'd0,
			LUT_END_RESET_INDEX = 5'd1,
			LUT_START_CONFIG_INDEX = 5'd2,
			LUT_STOP_CONFIG_INDEX = 5'd9;

localparam	IDLE = 3'd0,
 			START_RESET = 3'd1,
			WAIT_RESET = 3'd2,
 			START_CONFIGURATION = 3'd3,
			WAIT_CONFIGURATION = 3'd4,
			DONE = 3'd5;

reg [2:0] STATE_CONF = IDLE;

reg [4:0] start_index, stop_index;
reg adc_configured;

//Main FSM handling the reset and configuration part of the LUT
always @(posedge clk ) begin
	if(reset) begin
		ADC_ready <= 1'b0;
		adc_configured <= 1'b0;
		start_index <= LUT_START_RESET_INDEX;
		stop_index <= LUT_END_RESET_INDEX;
		STATE_CONF <= IDLE;
	end
	else begin
		case (STATE_CONF)

			IDLE: begin
				ADC_ready <= 1'b0;
				adc_configured <= 1'b0;
				start_index <= LUT_START_RESET_INDEX;
				stop_index <= LUT_END_RESET_INDEX;
				if (start) begin
					STATE_CONF <= START_RESET;
				end
			end

			START_RESET: begin //reset of the digital part of the ADC, needed after the clock (LMK) initialization and VREF change
				start_index <= LUT_START_RESET_INDEX;
				stop_index <= LUT_END_RESET_INDEX;
				start_lut_burst <= 1;
				STATE_CONF <= WAIT_RESET;
			end

			WAIT_RESET: begin
				start_lut_burst <= 0;
				if (lut_burst_done_delayed && adc_configured == 1'b0) begin
					STATE_CONF <= START_CONFIGURATION;
				end
				if (lut_burst_done_delayed && adc_configured == 1'b1) begin
					STATE_CONF <= DONE;
				end
			end

			START_CONFIGURATION: begin
				start_index <= LUT_START_CONFIG_INDEX;
				stop_index <= LUT_STOP_CONFIG_INDEX;
				start_lut_burst <= 1;
				STATE_CONF <= WAIT_CONFIGURATION;
			end

			WAIT_CONFIGURATION: begin	
				start_lut_burst <= 0;
				if (lut_burst_done) begin
					adc_configured <= 1'b1;
					STATE_CONF <= DONE;
				end
			end

			DONE: begin			
				ADC_ready <= 1'b1;
				STATE_CONF <= DONE;
			end

			default: begin
				STATE_CONF <= IDLE;
			end

		endcase
	end
end

//FSM scrolling the LUT and sending data to the SPI interface module
reg [4:0] lut_index = 5'd0;
reg start_lut_burst;
reg lut_burst_done;
wire lut_burst_done_delayed;

localparam		IDLE_SPI_BURST = 3'd0,
 				INCREMENT_INDEX = 3'd1,
 				SEND = 3'd2,
 				WAIT_DELAY = 3'd3;

reg [2:0] STATE_LUT = IDLE;

always @(posedge clk) begin
	if(reset) begin
		lut_burst_done <= 1'b0;
		lut_index <= 1'b0;
		STATE_LUT <= IDLE;
	end
	else begin
		case(STATE_LUT)

			IDLE_SPI_BURST: begin
				lut_burst_done <= 1'b0;
				if(start_lut_burst)
				begin
					STATE_LUT <= SEND;
					lut_index <= start_index;
				end
			end

			INCREMENT_INDEX: begin
				start_spi <= 1'b0;
				if(data_valid) begin
					lut_index <= lut_index + 5'd1;
					STATE_LUT <= SEND;
				end
			end

			SEND: begin			
				if(!busy) begin
					if(lut_index <= stop_index) begin
						start_spi <= 1'b1;
						STATE_LUT <= INCREMENT_INDEX;
					end
					else begin
						lut_burst_done <= 1'b1;
						STATE_LUT <= WAIT_DELAY;
					end
				end
			end

			WAIT_DELAY: begin			
				if(lut_burst_done_delayed) begin
					lut_burst_done <= 1'b0;
					STATE_LUT <= IDLE_SPI_BURST;
				end
			end
		endcase
	end
end

delayer #(.BIT_WIDTH(32)) lut_burst_done_delayer (
	.clk(clk),
	.reset(reset),
	.in(lut_burst_done),
	.delay(32'd50000000), //wait 1 sec
	.out(lut_burst_done_delayed)
);

endmodule
