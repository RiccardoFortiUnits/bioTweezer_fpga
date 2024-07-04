module mac_config_LUT(

	input [7:0]			index,
	input [47:0] 		mac_address,
	output reg [7:0]	address,
	output reg [31:0]	data,
	output reg wr // 1 for write, 0 for read
);

	// The configuration parameters are tuned for 1000BASE-X
	// ping tested also with a copper adapter, and works.

	// registers addresses
	localparam		LINK_TIMER_1 = 8'h92,
					LINK_TIMER_2 = 8'h93,
					IF_MODE = 8'h94,
					CONTROL_PCS = 8'h80,
					COMMAND_CONFIG = 8'h02,
					RX_SECTION_EMPTY = 8'h07,
					RX_SECTION_FULL = 8'h08,
					TX_SECTION_EMPTY = 8'h09,
					TX_SECTION_FULL = 8'h0A,
					RX_ALMOST_EMPTY = 8'h0B,
					RX_ALMOST_FULL = 8'h0C,
					TX_ALMOST_EMPTY = 8'h0D,
					TX_ALMOST_FULL = 8'h0E,
					MAC_0 = 8'h03,
					MAC_1 = 8'h04,
					FRM_LENGTH = 8'h05,
					TX_IPG_LENGTH = 8'h17,
					PAUSE_QUANT = 8'h06;

	// command_config register bit positions 
	localparam		TX_ENA = 32'h0000_0001,
					RX_ENA = 32'h0000_0002,
					XON_GEN = 32'h0000_0004,
					ETH_SPEED = 32'h0000_0008,
					PROMIS_EN = 32'h0000_0010,
					PAD_EN = 32'h0000_0020,
					CRC_FWD = 32'h0000_0040,
					PAUSE_FWD = 32'h0000_0080,
					PAUSE_IGNORE = 32'h0000_0100,
					TX_ADDRESS_INS = 32'h0000_0200,
					HD_ENA = 32'h0000_0400,
					EXCESS_COL = 32'h0000_0800,
					LATE_COL = 32'h0000_1000,
					SW_RESET = 32'h0000_2000,
					MHASH_SEL = 32'h0000_4000,
					LOOP_ENA = 32'h0000_8000,
					MAGIC_ENA = 32'h0008_0000,
					SLEEP = 32'h0010_0000,
					WAKEUP = 32'h0020_0000,
					XOFF_GEN = 32'h0040_0000,
					CNTL_FRM_ENA = 32'h0080_0000,
					NO_LGTH_CHECK = 32'h0100_0000,
					ENA_10 = 32'h0200_0000,
					RX_ERR_DISC = 32'h0400_0000,
					DISABLE_READ_TIMEOUT = 32'h0800_0000,
					CNT_RESET = 32'h8000_0000;

	localparam 	STANDARD_FRAMES = 32'h0000_05EE,
				JUMBO_4K = 32'h0000_1000,
				JUMBO_8K = 32'h0000_2000;

	always @(*)
	begin
		case(index)
			//PCS registers - start offset 0x80
			//MAC registers - start offset 0x00
			
			//------------------------------------
			// Start of PCS configuration
			0 :
			begin
				address = LINK_TIMER_1;
				data = 32'h0000_12D0;	// 1000BASE-X
				wr = 1'b1;
			end
			
			1 : 
			begin
				address = LINK_TIMER_2;
				data = 32'h0000_0013;	// 1000BASE-X
				wr = 1'b1;
			end
			
			2 :
			begin
				address = IF_MODE;
				data = 32'h0000_0000;	// 1000BASE-X
				wr = 1'b1;
			end
			
			3 : 
			begin
				address = CONTROL_PCS;
				data = 32'h0000_1140;
				wr = 1'b1;
			end
			
			4 :
			begin	//reset PCS
				address = CONTROL_PCS;
				data = 32'h0000_9140;
				wr = 1'b1;
			end
			
			5 : 
			begin // check bit clearance
				address = CONTROL_PCS;
				data = 32'h0000_1140;
				wr = 1'b0;
			end
			
			6 : //dummy read
			begin
				address = IF_MODE;
				data = 32'h0000_0000;	// 1000BASE-X
				wr = 1'b0;
			end
			
			// end of PCS config, begin of MAC config
			//-------------------------------------------
			
			//-------------------------------------------
			// Start of MAC configuration
			7 : 
			begin	//disable TX & RX
				address = COMMAND_CONFIG;
				data = 32'd0 | PAD_EN | ETH_SPEED;
				wr = 1'b1;
			end
			
			8 : 
			begin	//check for disable TX & RX
				address = COMMAND_CONFIG;
				data = 32'd0 | PAD_EN | ETH_SPEED;
				wr = 1'b0;
			end
						///-----FIFO section
			9 : 
			begin
				address = RX_SECTION_EMPTY;
				data = 32'h0000_07F8;
				wr = 1'b1;
			end
			
			10 : 
			begin
				address = RX_SECTION_FULL;
				data = 32'h0000_0010;
				wr = 1'b1;
			end
			
			11 : 
			begin
				address = TX_SECTION_EMPTY;
				data = 32'h0000_07F8;
				wr = 1'b1;
			end
			
			12 : 
			begin
				address = TX_SECTION_FULL;
				data = 32'h0000_0020;
				wr = 1'b1;
			end
			
			13 : 
			begin
				address = RX_ALMOST_EMPTY;
				data = 32'h0000_0008;
				wr = 1'b1;
			end
			
			14 : 
			begin
				address = RX_ALMOST_FULL;
				data = 32'h0000_0008;
				wr = 1'b1;
			end
			
			15 : 
			begin
				address = TX_ALMOST_EMPTY;
				data = 32'h0000_0008;
				wr = 1'b1;
			end
			
			16 : 
			begin
				address = TX_ALMOST_FULL;
				data = 32'h0000_000A;
				wr = 1'b1;
			end
					// end of FIFO section
			17 : 
			begin
				address = MAC_0;
				data = {mac_address[23:16], mac_address[31:24], mac_address[39:32], mac_address[47:40]};
				wr = 1'b1;
			end
			
			18 : 
			begin
				address = MAC_1;
				data = {16'h00_00, mac_address[7:0], mac_address[15:8]};
				wr = 1'b1;
			end
			
			19 : 
			begin
				address = FRM_LENGTH;
				data = JUMBO_8K; //8192 - 2xjumbo frames 
				wr = 1'b1;
			end
			
			20 : 
			begin
				address = TX_IPG_LENGTH;
				data = 32'h0000_000C;
				wr = 1'b1;
			end
			
			21 : 
			begin
				address = PAUSE_QUANT;
				data = 32'h0000_000F;
				wr = 1'b1;
			end
					//end of parameters
					
					// MAC final configuration
			22 : 
			begin		// MAC final configuration
				address = COMMAND_CONFIG;
				data = 32'd0 | PAUSE_IGNORE | SW_RESET | PAD_EN;
				wr = 1'b1;
			end
			
			23 : 
			begin  //reset MAC
				address = COMMAND_CONFIG;
				data = 32'd0 | PAUSE_IGNORE | SW_RESET | PAD_EN | ETH_SPEED;
				wr = 1'b1;
			end
			
			24 : 
			begin //wait for reset bit clearance
				address = COMMAND_CONFIG;
				data = 32'd0 | PAUSE_IGNORE | PAD_EN | ETH_SPEED;
				wr = 1'b0;
			end
			
			25 :
			begin	// enable TX & RX
				address = COMMAND_CONFIG;
				data = 32'd0 | PAUSE_IGNORE | PAD_EN | ETH_SPEED | TX_ENA | RX_ENA;
				wr = 1'b1;
			end
			

			26 :
			begin	// wait for enabling TX & RX
				address = COMMAND_CONFIG;
				data = 32'd0 | PAUSE_IGNORE | PAD_EN | ETH_SPEED | TX_ENA | RX_ENA;
				wr = 1'b0;
			end
			
			default:
			begin
				address = COMMAND_CONFIG;
				data = 32'd0 | PAUSE_IGNORE | PAD_EN | ETH_SPEED | TX_ENA | RX_ENA;
				wr = 1'b0;
			end
						
		endcase
	end
endmodule
