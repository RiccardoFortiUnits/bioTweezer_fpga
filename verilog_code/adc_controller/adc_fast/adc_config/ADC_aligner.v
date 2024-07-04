module adc_aligner(
		input 			clk,
		input 			reset,
        input           adc_lvds_pll_locked,
		input [7:0]		frm_data,		
		
		output reg 		bitslip,
		output reg 		data_aligned
);

localparam		IDLE = 3'd0,
 				WAIT = 3'd1,
                ALIGNED = 3'd2;

reg [2:0] STATE = IDLE;
reg [2:0] counter;

always @(posedge clk) begin
	if(reset) begin
		bitslip <= 1'b0;
		data_aligned <= 1'b0;
        counter <= 3'd0;
		STATE <= IDLE;
	end
	else begin
		case(STATE)

			IDLE: begin
				if(adc_lvds_pll_locked && frm_data != 8'b11110000) //data not aligned
				begin
					bitslip <= 1'b1;
                    counter <= 3'd3;
					STATE <= WAIT;
				end
                if(adc_lvds_pll_locked && frm_data == 8'b11110000) //data aligned
				begin
					bitslip <= 1'b0;
					STATE <= ALIGNED;
				end
			end

			WAIT: begin //wait in order for the bitslip to affect the output data
                bitslip <= 1'b0;
				if (counter == 3'd0) begin
                    STATE <= IDLE;
                end
                else begin
                    counter <= counter - 1'b1;
                end
			end

			ALIGNED: begin
                data_aligned <= 1'b1;
			end

		endcase
	end
end

endmodule
