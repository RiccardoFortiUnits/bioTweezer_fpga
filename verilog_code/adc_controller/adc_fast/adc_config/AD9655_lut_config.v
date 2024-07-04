module AD9655_lut_config ( 

			// aux inputs to facilitate configuration
 			input 				pwr, 			// 1 to turn on, 0 to turn off
 			input [1:0] 		test_pattern, 	// 2'b00: normal op
			// real data
 			input [4:0] 		index,
			input [1:0]			sel_chan,
 			output reg [7:0] 	data, 
 			output reg [12:0] 	address,
 			output reg 			rw 				// 1 for read, 0 for write
);

// These register are valid ONLY for AD9655 ADC

// WARNING: global registers affect all the chip, while local registers affect only the channels selected with register DEV_INDEX (0x05);
// 			All registers are updated at the moment they are written
// 			

localparam 	SPI_CONF 	= 13'h00, 		// sets the spi mode - global
			DEV_INDEX	= 13'h05,
 			PWR_MODE	= 13'h08, 		// control powerdown options - local
 			GLB_CLK 	= 13'h09, 		// enables DCS - global
 			CLK_DIV 	= 13'h0B, 		// sets clock divide ratio - global
 			ENH_CTRL 	= 13'h0C,
 			TEST_MODE 	= 13'h0D, 		// set the test pattern generator on outputs - local
  			OFS_ADJ 	= 13'h10, 		// offset adjust - local
 			OUTPUT_MODE = 13'h14, 		// output mode - mixed
 			OUT_PHS 	= 13'h16, 		// output phase adjust - global
 			VREF 		= 13'h18, 		// input span select/Vref select - global
 			USR_PAT_1L 	= 13'h19,
 			USR_PAT_1M 	= 13'h1A,
 			USR_PAT_2L 	= 13'h1B,
 			USR_PAT_2M 	= 13'h1C,
 			DDR_MODE 	= 13'h21,
 			DDR_STATUS 	= 13'h22,
			USR_IOCTL_2 = 13'h101,
			USR_IOCTL_3 = 13'h102,
			CAL_STATUS  = 13'h107,
			CLK_RECOVERY = 13'h112,
			VREF_CTRL 	= 13'h114;




// asynchronous look-up table

always @(index, pwr, test_pattern, sel_chan) 
begin
	case (index)
		0: begin
			address <= PWR_MODE;
			data <= 8'h03;
			rw <= 1'b0;
		end

		1: begin
			address <= PWR_MODE;
			data <= 8'h00;
			rw <= 1'b0;
		end

		2: begin
			address <= SPI_CONF;
			data <= 8'h18;
			rw <= 1'b1;
		end

		3: begin
			address <= DEV_INDEX;
			data <= {6'd0, sel_chan};
			rw <= 1'b0;
		end


		4: begin
			address <= VREF_CTRL;
			data <= 8'h00;
			rw <= 1'b0;
		end

		
		5: begin
			address <= PWR_MODE;
			data <= 8'h00 | ~pwr;
			rw <= 1'b0;
		end
		

		6: begin
			address <= OUTPUT_MODE;
			data <= 8'h01; 
			rw <= 1'b0;
		end

		7: begin
			address <= TEST_MODE;
			if(test_pattern == 2'b00)
			begin
				data <= 8'h00;	//normal operation
			end
			else if(test_pattern == 2'b01)
			begin
				data <= 8'h44;	//alternating checkerboard
				//data <= 8'h02; // positive FS
			end
			else if(test_pattern == 2'b10)
			begin
				//data <= 8'h07;	//one/zero word toggle
				data <= 8'h03; //negative FS
			end
			else
			begin
				//data <= 8'h01;	//midscale short
				//data <= 8'h09; //one/zero bit toggle
				//data <= 8'h08; // user pattern single
				//data <= 8'h48; // user pattern alternate
				data <= 8'h0C; // Mixed frequency
			end
			rw <= 1'b0;
		end

		8: begin
			address <= VREF;
			data <= 8'h04;	// 2.0 Vpp input
			rw <= 1'b0;
		end

		9: begin
			address <= DDR_MODE;
			data <= 8'h30; //ddr 2-lane bytewise;
			rw <= 1'b0;
		end
		
		10:	begin
			address <= USR_PAT_1L;
			data <= 8'b1000_0101; //
			rw <= 1'b0;
		end

		11: begin
			address <= USR_PAT_1M;
			data <= 8'b1101_1111; //
			rw <= 1'b0;
		end
		
		12:	begin
			address <= USR_PAT_2L;
			data <= 8'b0110_1101; //
			rw <= 1'b0;
		end

		13:	begin
			address <= USR_PAT_2M;
			data <= 8'b0111_0110; //
			rw <= 1'b0;
		end

		default: begin
			address <= SPI_CONF;
			data <= 8'h18;
			rw <= 1'b1;
		end

	endcase
end

endmodule
