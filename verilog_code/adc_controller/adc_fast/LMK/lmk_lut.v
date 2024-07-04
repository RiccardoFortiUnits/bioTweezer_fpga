module lmk_lut (
					input [3:0] index,
					
					output reg [7:0] address,
					output reg [7:0] data
					
);

localparam 	R0_VNDRID_BY1 = 8'd0,
				R1_VNDRID_BY0 = 8'd1,
				R2_PRODID = 8'd2,
				R3_REVID = 8'd3,
				R8_SLAVEADR = 8'd8,
				R9_EEREV = 8'd9,
				R10_DEV_CTL = 8'd10,
				R16_XO_CAPCTRL_BY1 = 8'd16,
				R17_XO_CAPCTRL_BY0 = 8'd17,
				R21_DIFFCTL = 8'd21,
				R22_OUTDIV_BY1 = 8'd22,
				R23_OUTDIV_BY0 = 8'd23,
				R25_PLL_NDIV_BY1 = 8'd25,
				R26_PLL_NDIV_BY0 = 8'd26,
				R27_PLL_FRACNUM_BY2 = 8'd27,
				R28_PLL_FRACNUM_BY1 = 8'd28,
				R29_PLL_FRACNUM_BY0 = 8'd29,
				R30_PLL_FRACDEN_BY2 = 8'd30,
				R31_PLL_FRACDEN_BY1 = 8'd31,
				R32_PLL_FRACDEN_BY0 = 8'd32,
				R33_PLL_MASHCTRL = 8'd33,
				R34_PLL_CTRL0 = 8'd34,
				R35_PLL_CTRL1 = 8'd35,
				R36_PLL_LF_R2 = 8'd36,
				R37_PLL_LF_C1 = 8'd37,
				R38_PLL_LF_R3 = 8'd38,
				R39_PLL_LF_C3 = 8'd39,
				R42_PLL_CALCTRL = 8'd42,
				R47_NVMSCRC = 8'd47,
				R48_NVMCNT = 8'd48,
				R49_NVMCTL = 8'd49,
				R50_NVMLCRC = 8'd50,
				R51_MEMADR = 8'd51,
				R52_NVMDAT = 8'd52,
				R53_RAMDAT = 8'd53,
				R56_NVMUNLK = 8'd56,
				R66_INT_LIVE = 8'd66,
				R72_SWRST = 8'd72;

always @ (index)
begin
	case(index)
		4'd1:
		begin
			address <= R21_DIFFCTL;
			data <= 8'b00000010;   // LVDS output	
		end

		4'd2:
		begin
			address <= R23_OUTDIV_BY0;
			//data <= 8'd25;   // output divider: 25 (200 MHz)
			//data <= 8'd17; // output divider: 17 (294 MHz)
			data <= 8'd50;  // output divider: 50 (100 MHz)
		end
			
		default:
		begin
			address <= 8'd0;
			data <= 8'd0;		
		end
	endcase
end





endmodule
