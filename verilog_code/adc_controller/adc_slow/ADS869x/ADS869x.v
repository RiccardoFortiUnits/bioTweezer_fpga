//The SCLK is half the input clock of the module
module ADS869x #(
	parameter TCONV = 665,	//in ns
	TACQ = 335,				//in ns
	CLOCK_FREQ = 100			//in MHz
)(
    input               clock,
    input               reset,

    //Initial configuration ports
    input               start_configuration,
    output reg          adc_configured,
    
    //Normal operation ports
    input               acquire,
    output              busy,
    output reg [17:0]   data_read,
    output reg          data_valid,

    //ADC SPI
    output reg          RST_n,
	output 				SCLK,
	output   			CONV,
	output				SDI,
	input				SDO      
);

assign busy = busy_adc || ~adc_configured;

/// LUT for ADC configuration  ///
reg [4:0] index;
wire [6:0] command_from_lut;
wire [8:0] address_from_lut;
wire [15:0]	data_from_lut;
wire last_index;

ADS869x_lut ADS869x_lut_0 (
    .index(index),
    .command(command_from_lut),
    .address(address_from_lut),
    .data(data_from_lut),
    .last_index(last_index)
);

/// FSM for ADC configuration ///
localparam  IDLE = 0,
            CONFIGURE = 1,
            INCREMENT_INDEX = 2,
            WAIT_LAST_INDEX = 3,
            CONFIGURATION_DONE = 4;

reg [3:0] STATE = CONFIGURE;

reg start_adc_config;

always @(posedge clock) begin
    if (reset) begin
        start_adc_config <= 1'b0;
        adc_configured <= 1'b0;
        RST_n <= 1'b0;
        index <= 5'd0;
        STATE <= IDLE;
    end
    else begin
        case (STATE)
            IDLE: begin
                RST_n <= 1'b1;
                start_adc_config <= 1'b0;
                adc_configured <= 1'b0;
                index <= 5'd0;
                if (adc_reset_done && start_configuration) begin
                    STATE <= CONFIGURE;
                end
            end

            CONFIGURE: begin
                if (!busy_adc) begin
                    start_adc_config <= 1'b1;
                    STATE <= INCREMENT_INDEX;
                end
            end

            INCREMENT_INDEX: begin
                start_adc_config <= 1'b0;
                if (last_index) begin
                    STATE <= WAIT_LAST_INDEX;
                end
                else begin
                    index <= index + 1'b1;
                    STATE <= CONFIGURE;
                end
            end

            WAIT_LAST_INDEX: begin
                if (!busy_adc) begin
                    STATE <= CONFIGURATION_DONE;
                end
            end

            CONFIGURATION_DONE: begin
                adc_configured <= 1'b1;           
            end

            default: begin
                start_adc_config <= 1'b0;
                adc_configured <= 1'b0;
                index <= 5'd0;
                STATE <= IDLE;
            end
        endcase
    end
end

/// Delayer to wait the 20ms required after a POD reset ///
wire adc_reset_done;
delayer #(.BIT_WIDTH(32)) reset_delayer (
	.clk(clock),
	.reset(reset || !RST_n),
	.in(1'b1),
	.delay(20*CLOCK_FREQ*1000), //20 ms to reset at 50 MHz take 1000000 clock cycles
	.out(adc_reset_done)
);


/// Multiplexer for configuration or normal operation
reg [6:0] command;
reg [8:0] address;
reg [15:0] data_write;

always @* begin
    if (STATE != CONFIGURATION_DONE ) begin
        command <= command_from_lut;
        address <= address_from_lut;
        data_write <= data_from_lut;
        start_adc <= start_adc_config;
        data_read <= 18'd0;
        data_valid <= 1'b0;
    end
    else begin
        command <= 7'd0;
        address <= 9'd0;
        data_write <= 16'd0;
        start_adc <= acquire;
        data_read <= data_read_from_adc;
        data_valid <= data_valid_from_adc;
    end
end

/// SPI interface for the ADC
reg start_adc;
wire busy_adc, data_valid_from_adc;
wire [17:0] data_read_from_adc;
ADS869x_spi_interface #(.TCONV(TCONV), .TACQ(TACQ), .CLOCK_FREQ(CLOCK_FREQ)) ADS869x_spi_interface_0 (
    .clock(clock),
    .reset(reset),
    .start(start_adc),
    .busy(busy_adc),

    .command(command),
    .address(address),
    .data_write(data_write),

    .data_read(data_read_from_adc),
	.data_valid(data_valid_from_adc),

    .SCLK(SCLK),
    .CONV(CONV),
    .SDI(SDI),
    .SDO(SDO)
);
    
endmodule