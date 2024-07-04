`include "ADS869x/ADS869x.v"
`include "ADS869x/ADS869x_spi_interface.v"
`include "ADS869x/ADS869x_lut.v"
`include "MAX31855K.v"

module ADC_SLOW_wrapper #(parameter DATA_FREQUENCY = 10, //in Hz //max is 10 for the thermocouple
                                    CLOCK_FREQUENCY = 50 //in MHz
)  (
    input           clk_50,
    input           reset,

    input           acquire,
    input           start_configuration,
    output          adc_configured,

	// ADC SPI interface
    output 			AD869_SCLK,
    output          AD869_RST_n,
	output [1:0]	AD869_CONV,
	output			AD869_SDI,
	input [1:0]		AD869_SDO,
    
    // THERMOCOUPLE SPI interface
    output          TC_SCLK,
    output          TC_CS_n,
    input           TC_SDO,

	// TEMPERATURE AND VOLTAGES DATA FIFO	
	input           temp_voltage_clr_fifo,
	input           temp_voltage_rdclk_fifo,
	input           temp_voltage_rdreq_fifo,
	output [63:0]   temp_voltage_rddata_fifo,
	output          temp_voltage_rdempty_fifo
);

// ACQUISITION TIMING MANAGEMENT

localparam  COUNTER_NUMBER = (CLOCK_FREQUENCY*1000000) / DATA_FREQUENCY;

reg [31:0] counter = 31'b0;
reg start_acquisition = 1'b0;
wire adc_slow_busy = SADC1_busy || SADC2_busy || TC_busy;

reg acquire_2, acquire_1;
always @(posedge clk_50 ) begin
    acquire_1 <= acquire;
    acquire_2 <= acquire_1;
end

always @(posedge clk_50) begin
	if (reset) begin
        start_acquisition <= 1'b0;
        counter <= 31'b0;
	end
	else begin
        start_acquisition <= 1'b0;
        if (acquire_2) begin
            if (counter == COUNTER_NUMBER - 1 && !adc_slow_busy) begin
                counter <= 31'b0;
                start_acquisition <= 1'b1;
            end
            if (counter < COUNTER_NUMBER - 1) begin
                counter <= counter + 1'b1;
            end		
        end
        else begin
            counter <= 31'b0;
        end
    end
end

wire [17:0] SADC1_data;
wire SADC1_busy, SADC1_valid;

// ADC ICs

ADS869x #(.CLOCK_FREQ(CLOCK_FREQUENCY)) ADS8691_SADC1(
    .clock(clk_50),
    .reset(reset),
    .start_configuration(start_configuration),

    .acquire(start_acquisition),
    .busy(SADC1_busy),
    .adc_configured(adc_configured),
    .data_read(SADC1_data),
    .data_valid(SADC1_valid),

    //ADC SPI
    .RST_n(AD869_RST_n),
	.SCLK(AD869_SCLK),
	.CONV(AD869_CONV[1]),
	.SDI(AD869_SDI),
	.SDO(AD869_SDO[1])      
);

wire [17:0] SADC2_data;
wire SADC2_busy, SADC2_valid;
ADS869x #(.CLOCK_FREQ(CLOCK_FREQUENCY)) ADS8691_SADC2(
    .clock(clk_50),
    .reset(reset),
    .start_configuration(start_configuration),

    .acquire(start_acquisition),
    .busy(SADC2_busy),
    .adc_configured(),
    .data_read(SADC2_data),
    .data_valid(SADC2_valid),

    //ADC SPI
	.CONV(AD869_CONV[0]),
	.SDO(AD869_SDO[0])      
);

// THERMOCOUPLE IC

wire SCV_fault, SCG_fault, OC_fault;
wire [13:0] TC_external_data;
wire [11:0] TC_internal_data;
wire TC_busy, TC_data_valid;

MAX31855K MAX31855K_0(
    .clk_50(clk_50),
    .reset(reset),

    .start_acq(start_acquisition),
    .data_valid(TC_data_valid),
    .busy(TC_busy),

    .temperature_data(TC_external_data),
    .temperature_internal_data(TC_internal_data),
    .SCV_fault(SCV_fault),
    .SCG_fault(SCG_fault),
    .OC_fault(OC_fault),

    .MAX_SCLK(TC_SCLK),
    .MAX_CSn(TC_CS_n),
    .MAX_SDO(TC_SDO)
);

//FIFO WRITING FSM and FIFO

localparam 	IDLE = 0,
			WAIT_ADC = 1;

reg [1:0] STATE;
wire adc_slow_data_valid = TC_data_valid && SADC1_valid && SADC2_valid;

always @(posedge clk_50) begin
	if (reset) begin
        STATE <= IDLE;
        fifo_wrreq <= 1'b0;
	end
	else begin
        case (STATE)
            IDLE: begin
                fifo_wrreq <= 1'b0;
                if (start_acquisition) begin
                    STATE <= WAIT_ADC;
                end
            end

            WAIT_ADC: begin
                if (adc_slow_data_valid) begin                    
                    fifo_wrreq <= 1'b1;
                    STATE <= IDLE;
                end
            end

            default: begin
                fifo_wrreq <= 1'b0;
                STATE <= IDLE;
            end
        endcase
    end
end

wire [63:0] data_to_fifo = {{SCV_fault || SCG_fault}, OC_fault, TC_external_data, TC_internal_data, SADC1_data, SADC2_data};
wire fifo_wrfull;
reg fifo_wrreq;

adc_fifo_64	adc_fifo_slow (
	.data ( data_to_fifo ),
	.wrclk ( clk_50 ),
	.wrreq ( fifo_wrreq ),    
	.wrfull ( fifo_wrfull ),

    .aclr ( temp_voltage_clr_fifo ),
	.rdclk ( temp_voltage_rdclk_fifo ),
	.rdreq ( temp_voltage_rdreq_fifo ),
	.q ( temp_voltage_rddata_fifo ),
	.rdempty ( temp_voltage_rdempty_fifo )
);
    
endmodule