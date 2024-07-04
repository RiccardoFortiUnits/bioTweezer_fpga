module ADS869x_spi_interface#(
	parameter TCONV = 665,	//in ns
	TACQ = 335,				//in ns
	CLOCK_FREQ = 100			//in MHz
)(

	input 				clock, // MAX 50 MHz clock
	input 				reset,
	input 				start,
	output reg 			busy,
	
	//FROM LUT
	input [6:0]			command,
	input [8:0] 		address,
	input [15:0]		data_write,

	//DATA FROM ADC
	output reg [17:0]	data_read,
	output reg 			data_valid,
		
	//ADC SPI
	output reg			SCLK,
	output reg 			CONV,
	output reg			SDI,
	input				SDO
);

//// START MAIN FSM ////
localparam 	IDLE = 0,
			WAIT = 1,
			WAIT2 = 2,
			READ_WRITE = 3,
			FINISH_ACQ = 4,
			FINISH_CONV = 5;

reg [2:0] STATE;

reg [31:0] raw_data_read;
reg [31:0] raw_data_write;

reg enable_sclk = 1'b0;

reg [4:0] bit_counter;

always @(posedge clock) begin
	if (reset) begin
		CONV <= 1'b1;
		data_valid <= 1'b0;
		enable_sclk <= 1'b0;
		SDI <= 1'b0;
		busy <= 1'b1;
		STATE <= IDLE;
	end
	else begin
		case (STATE)

			IDLE: begin				
				CONV <= 1'b1;
				bit_counter <= 5'd0;				
				SDI <= 1'b0;
				enable_sclk <= 1'b0;			
				acq_start <= 1'b0;
				conv_start <= 1'b0;
				busy <= 1'b0;
				if (start) begin
					busy <= 1'b1;
					data_valid <= 1'b0;
					raw_data_write <= {command, address, data_write};
					STATE <= WAIT;
				end
			end

			WAIT: begin
				SDI <= raw_data_write[31];
				CONV <= 1'b0;
				acq_start <= 1'b1;
				bit_counter <= 5'd0;
				enable_sclk <= 1'b1;
				STATE <= READ_WRITE;
			end

			READ_WRITE: begin
				if (SCLK) begin
					raw_data_read[31:1] <= raw_data_read[30:0];
					raw_data_read[0] <= SDO;					
					bit_counter <= bit_counter + 1'b1;
					if (bit_counter == 5'd31) begin
						enable_sclk <= 1'b0;			
						STATE <= FINISH_ACQ;
					end
					else begin
						SDI <= raw_data_write[31-bit_counter-1];
					end
				end
			end

			FINISH_ACQ: begin
				data_read <= raw_data_read [31 -: 18];
				data_valid <= 1'b1;
				acq_start <= 1'b0;
				if (acq_done) begin
					CONV <= 1'b1;
					STATE <= FINISH_CONV;
					conv_start <= 1'b1;
				end				
			end

			FINISH_CONV: begin
				if (conv_done) begin
					conv_start <= 1'b0;
					busy <= 1'b0;
					STATE <=IDLE;
				end
			end

			default:begin
				CONV <= 1'b1;
				data_valid <= 1'b0;
				enable_sclk <= 1'b0;
				busy <= 1'b0;
				STATE <= IDLE;
			end

		endcase
	end
end

//// END MAIN FSM ////

//// START FSM TO CONTROL ACQ AND CONV TIMING ////

localparam 	IDLE_ACQ = 0,
			WAIT_ACQ = 1,
			IDLE_CONV = 2,
			WAIT_CONV = 3;

reg [2:0] TIME_STATE;

reg [15:0] wait_counter;
reg acq_start, acq_done, conv_start, conv_done;

always @(posedge clock) begin
	if (reset) begin
		TIME_STATE <= IDLE;
	end
	else begin
		case (TIME_STATE)
			IDLE_ACQ: begin
				wait_counter <= 16'd0;
				acq_done <= 1'b0;
				conv_done <= 1'b0;
				if (acq_start) begin
					TIME_STATE <= WAIT_ACQ;
				end
			end
			WAIT_ACQ: begin
				wait_counter <= wait_counter + 1'b1;
				if (wait_counter >= TACQ*CLOCK_FREQ/1000) begin
					wait_counter <= 16'd0;
					acq_done <= 1'b1;
					TIME_STATE <= IDLE_CONV;
				end
			end
			IDLE_CONV: begin
				if (conv_start) begin
					TIME_STATE <= WAIT_CONV;
				end
			end
			WAIT_CONV: begin
				wait_counter <= wait_counter + 1'b1;
				if (wait_counter >= TCONV*CLOCK_FREQ/1000) begin
					wait_counter <= 16'd0;
					conv_done <= 1'b1;
					TIME_STATE <= IDLE_ACQ;
				end
			end
			default: begin
				wait_counter <= 16'd0;
				acq_done <= 1'b0;
				conv_done <= 1'b0;
				STATE <= IDLE_ACQ;
			end
		endcase
	end
end

//// END FSM TO CONTROL ACQ AND CONVERSION TIMING ////
always @(posedge clock ) begin
	if (enable_sclk) begin
		SCLK <= !SCLK;
	end
	else begin
		SCLK <= 1'b0;
	end
end

endmodule