module current_meas (
    input   ADC_outclock,
    input   reset,

    input   ADC_acquire,
    input   [15:0] ADC_data,

    input   clr_fifo,
    input   rdclk_fifo,
	input   rdreq_fifo,	
	output [15:0] rddata_fifo,
	output  rdempty_fifo
);

//ADC samples averager (to reduce sample rate to 25 MHz)
localparam 	IDLE = 0,
			FIRST_SAMPLE = 1,
			SECOND_SAMPLE = 2;

reg [2:0] ADC_STATE = 1'b0;
reg signed [15:0] sample_1, sample_2;
reg wr_fifo_enable;

always @(posedge ADC_outclock ) begin
	if (reset) begin
		ADC_STATE <= IDLE;
		sample_1 <= 16'd0;
		sample_2 <= 16'd0;
		wr_fifo_enable <= 1'b0;
	end
	else begin
		case (ADC_STATE) 
			
			IDLE: begin
				wr_fifo_enable <= 1'b0;
				if (ADC_acquire) begin
					sample_1 <= ADC_data;
					ADC_STATE <= SECOND_SAMPLE;					
				end
			end

			FIRST_SAMPLE: begin
				sample_1 <= ADC_data;
				wr_fifo_enable <= 1'b0;
				if (ADC_acquire) ADC_STATE <= SECOND_SAMPLE;
				else ADC_STATE <= IDLE;
			end

			SECOND_SAMPLE: begin
				sample_2 <= ADC_data;
				wr_fifo_enable <= 1'b1;
				ADC_STATE <= FIRST_SAMPLE;
			end

		endcase
	end
end

wire signed [16:0] samples_sum = sample_1 + sample_2;
wire signed [15:0] samples_mean = samples_sum[16:1];

//ADC FIFO
adc_fifo16	current_fifo16_inst (
	.aclr ( clr_fifo ),
	.data ( samples_mean ),
	.wrclk ( ADC_outclock ),
	.wrreq ( wr_fifo_enable ),
	.wrusedw (),

	.rdclk ( rdclk_fifo ),
	.rdreq ( rdreq_fifo ),	
	.q ( rddata_fifo ),
	.rdempty ( rdempty_fifo ),
	.rdusedw(),
	.wrfull ()
);
    
endmodule