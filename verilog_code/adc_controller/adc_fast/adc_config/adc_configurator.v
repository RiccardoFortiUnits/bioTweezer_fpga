`include "ADC_spi_interface.v"
`include "AD9653_lut_config.v"

module ADC_configurator(
		input 			clk,
		input 			reset,
		input 			start,

		input [15:0]	align_data,	
		input 			align_data_locked,	
		output reg 		bitslip,
		
		output reg 		ADC_ready,
		output reg 		ADC_aligned,
		output [7:0] 	data_read,
		output 			data_valid,
		output 			busy,

		// SPI connections
		output 			cs_n,
		output 			sclk,
		inout 			data_adc
);

wire align_data_locked_reg;

sync_edge_det align_data_locked_sync(
    .clk(clk),
    .signal_in(align_data_locked),
    .data_out(align_data_locked_reg)
);

wire [15:0] align_data_reg;

sync_edge_det #(.WIDTH(16)) align_data_sync(
    .clk(clk),
    .signal_in(align_data),
    .data_out(align_data_reg)
);

//LUT for the ADC
wire [12:0] address;
wire [7:0] data_spi;
wire rw;

reg [1:0] test_pattern;

AD9653_lut_config AD9653_lut_config_1 ( 
	.index(lut_index),
	.pwr(1'b1),	//power-on
	.test_pattern(test_pattern), //normal operation
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
			LUT_STOP_CONFIG_INDEX = 5'd9,
			LUT_TEST_MODE = 5'd7;

localparam	IDLE = 6'd0,
 			START_RESET = 6'd1,
			WAIT_RESET = 6'd2,
 			START_CONFIGURATION = 6'd3,
			WAIT_CONFIGURATION = 6'd4,
			DONE = 6'd5,
			WAIT_LOCKED = 6'd6,
			CHECK_ALIGN = 6'd7,
			WAIT_ALIGN = 6'd8,
			SET_NORMAL_OPERATION = 6'd9,
			WAIT_NORMAL_OPERATION = 6'd10;

reg [5:0] STATE_CONF = IDLE;

reg [4:0] start_index, stop_index;
reg adc_configured;
reg [7:0] bitslip_counter;

//Main FSM handling the reset and configuration part of the LUT
always @(posedge clk ) begin
	if(reset) begin
		ADC_ready <= 1'b0;
		ADC_aligned <= 1'b0;
		test_pattern <= 2'b11;
		bitslip <= 1'b0;
		bitslip_counter <= 8'd0;
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
			end

			START_CONFIGURATION: begin
				start_index <= LUT_START_CONFIG_INDEX;
				stop_index <= LUT_STOP_CONFIG_INDEX;
				start_lut_burst <= 1;
				STATE_CONF <= WAIT_CONFIGURATION;
			end

			WAIT_CONFIGURATION: begin	
				start_lut_burst <= 0;
				if (lut_burst_done_delayed) begin
					adc_configured <= 1'b1;
					ADC_ready <= 1'b1;
					STATE_CONF <= WAIT_LOCKED;
				end
			end

			WAIT_LOCKED: begin
				if(align_data_locked_reg) STATE_CONF <= CHECK_ALIGN;
			end

			CHECK_ALIGN: begin
				if (align_data_reg == 16'b1010000110011100) begin
					STATE_CONF <= SET_NORMAL_OPERATION;
				end
				else begin
					STATE_CONF <= WAIT_ALIGN;
					bitslip <= 1'b1;
					bitslip_counter <= 8'd0;
				end 
			end

			WAIT_ALIGN: begin
				bitslip <= 1'b0;
				bitslip_counter <= bitslip_counter + 1;
				if (bitslip_counter == 8'd16) begin
					STATE_CONF <= CHECK_ALIGN;
				end
			end

			SET_NORMAL_OPERATION:begin
				test_pattern <= 2'b00;
				start_index <= LUT_TEST_MODE;
				stop_index <= LUT_TEST_MODE;
				start_lut_burst <= 1;
				STATE_CONF <= WAIT_NORMAL_OPERATION;
			end

			WAIT_NORMAL_OPERATION: begin	
				start_lut_burst <= 0;
				if (lut_burst_done_delayed) begin
					adc_configured <= 1'b1;
					STATE_CONF <= DONE;
				end
			end

			DONE: begin			
				ADC_aligned <= 1'b1;
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
