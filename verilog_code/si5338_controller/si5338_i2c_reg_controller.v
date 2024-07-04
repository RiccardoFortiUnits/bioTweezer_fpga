
`define REG_NUM 10  
`define DEVICE_SLAVE_ID 7'b1110000

//`include "edge_detector.v"

module si5338_i2c_reg_controller(

input                         iCLK,
input                         iRST_n,
input                         iENABLE,

input                         iI2C_CONTROLLER_STATE,
input                         iI2C_CONTROLLER_CONFIG_DONE,


output        [6:0]           oSLAVE_ADDR,
output        [7:0]       	   oBYTE_ADDR,
output        [7:0]           oBYTE_DATA ,
output                        oWR_CMD,
output                        oStart,
input                         iI2C_READ_DATA_RDY,
input         [7:0]           iI2C_READ_DATA,
output                        oONE_CLK_CONFIG_DONE,
output	  reg                  oController_Ready

);

//=============================================================================
// PARAMETER declarations
//=============================================================================
parameter write_cmd = 1'b1;
parameter read_cmd = 1'b0;      
parameter NOT_LAST = 1'b0;
parameter LAST_REG = 1'b1;
//===========================================================================
// PORT declarations
//===========================================================================




//=============================================================================
// REG/WIRE declarations
//=============================================================================
reg   [7:0] i2c_reg_state;
wire  [6:0] slave_addr = `DEVICE_SLAVE_ID;
reg   [24:0] 	i2c_ctrl_data;// end_reg_instruction ,  slave_addr(7bit) + byte_addr(8bit) + byte_data(8bit)+ wr_cmd (1bit) = 24bit

wire        access_next_i2c_reg_cmd;
wire        i2c_controller_config_done;
wire        access_i2c_reg_start;

//wire        oONE_CLK_CONFIG_DONE;
//reg	        oController_Ready;

assign  oSLAVE_ADDR = i2c_ctrl_data[23:17];
assign  oBYTE_ADDR  = i2c_ctrl_data[16:9];
assign  oBYTE_DATA  = i2c_ctrl_data[8:1];
assign  oWR_CMD     = i2c_ctrl_data[0];
assign  oStart      = access_next_i2c_reg_cmd;

//=============    wire   all  reg  =========================

// wire	[7:0]	REG_0006,REG_0027,REG_0028,REG_0029,REG_0030,REG_0031,REG_0032,REG_0033,REG_0034,REG_0035,REG_0036,REG_0037,REG_0038,REG_0039,REG_0040,REG_0041,REG_0042,REG_0045,REG_0046,REG_0047,REG_0048,REG_0049,REG_0050,REG_0051,REG_0052,REG_0053,REG_0054,REG_0055,REG_0056,REG_0057,REG_0058,REG_0059,REG_0060,REG_0061,REG_0062,REG_0063,REG_0064,REG_0065,REG_0066,REG_0067,REG_0068,REG_0069,REG_0070,REG_0071,REG_0072,REG_0073,REG_0074,REG_0075,REG_0076,REG_0077,REG_0078,REG_0079,REG_0080,REG_0081,REG_0082,REG_0083,REG_0084,REG_0085,REG_0086,REG_0087,REG_0088,REG_0089,REG_0090,REG_0091,REG_0092,REG_0093,REG_0094,REG_0095,REG_0097, REG_0098,REG_0099,REG_0100,REG_0101,REG_0102,REG_0103,REG_0104,REG_0105,REG_0106;


//=============    wire   all  reg  end =========================

//=============    wire   all  reg  address value ===============

localparam 	REG_ADDR_PAGE	=	8'hFF	, // set to 0 for addresses 0-254, 1 for 256-347
			REG_ADDR_0006	=	8'd6	, // Interrupt mask
			REG_ADDR_0027	=	8'd27	, // I2C conf
			REG_ADDR_0028	=	8'd28	, // Input mux
			REG_ADDR_0029	=	8'd29	, // Input mux
			REG_ADDR_0030	=	8'd30	, // Input mux
			REG_ADDR_0031	=	8'd31	, // Output conf
			REG_ADDR_0032	=	8'd32	, // Output conf
			REG_ADDR_0033	=	8'd33	, // Output conf
			REG_ADDR_0034	=	8'd34	, // Output conf
			REG_ADDR_0035	=	8'd35	, // Output conf
			REG_ADDR_0036	=	8'd36	, // Output conf
			REG_ADDR_0037	=	8'd37	, // Output conf
			REG_ADDR_0038	=	8'd38	, // Output conf
			REG_ADDR_0039	=	8'd39	, // Output conf
			REG_ADDR_0040	=	8'd40	, // Output driver trim
			REG_ADDR_0041	=	8'd41	, // Output driver trim
			REG_ADDR_0042	=	8'd42	, // Output driver trim
			REG_ADDR_0047	=	8'd47	, // Input conf
			REG_ADDR_0048	=	8'd48	, // PLL conf
			REG_ADDR_0049	=	8'd49	, // PLL conf
			REG_ADDR_0050	=	8'd50	, // PLL conf
			REG_ADDR_0051	=	8'd51	, // PLL conf
			REG_ADDR_0052	=	8'd52	, // MS0 freq conf
			REG_ADDR_0053	=	8'd53	, // MS0 freq conf
			REG_ADDR_0054	=	8'd54	, // MS0 freq conf
			REG_ADDR_0055	=	8'd55	, // MS0 freq conf
			REG_ADDR_0056	=	8'd56	, // MS0 freq conf
			REG_ADDR_0057	=	8'd57	, // MS0 freq conf
			REG_ADDR_0058	=	8'd58	, // MS0 freq conf
			REG_ADDR_0059	=	8'd59	, // MS0 freq conf
			REG_ADDR_0060	=	8'd60	, // MS0 freq conf
			REG_ADDR_0061	=	8'd61	, // MS0 freq conf
			REG_ADDR_0062	=	8'd62	, // MS0 freq conf
			REG_ADDR_0063	=	8'd63	, // MS1 freq conf
			REG_ADDR_0064	=	8'd64	, // MS1 freq conf
			REG_ADDR_0065	=	8'd65	, // MS1 freq conf
			REG_ADDR_0066	=	8'd66	, // MS1 freq conf
			REG_ADDR_0067	=	8'd67	, // MS1 freq conf
			REG_ADDR_0068	=	8'd68	, // MS1 freq conf
			REG_ADDR_0069	=	8'd69	, // MS1 freq conf
			REG_ADDR_0070	=	8'd70	, // MS1 freq conf
			REG_ADDR_0071	=	8'd71	, // MS1 freq conf
			REG_ADDR_0072	=	8'd72	, // MS1 freq conf
			REG_ADDR_0073	=	8'd73	, // MS1 freq conf
			REG_ADDR_0074	=	8'd74	, // MS2 freq conf
			REG_ADDR_0075	=	8'd75	, // MS2 freq conf
			REG_ADDR_0076	=	8'd76	, // MS2 freq conf
			REG_ADDR_0077	=	8'd77	, // MS2 freq conf
			REG_ADDR_0078	=	8'd78	, // MS2 freq conf
			REG_ADDR_0079	=	8'd79	, // MS2 freq conf
			REG_ADDR_0080	=	8'd80	, // MS2 freq conf
			REG_ADDR_0081	=	8'd81	, // MS2 freq conf
			REG_ADDR_0082	=	8'd82	, // MS2 freq conf
			REG_ADDR_0083	=	8'd83	, // MS2 freq conf
			REG_ADDR_0084	=	8'd84	, // MS2 freq conf
			REG_ADDR_0085	=	8'd85	, // MS3 freq conf
			REG_ADDR_0086	=	8'd86	, // MS3 freq conf
			REG_ADDR_0087	=	8'd87	, // MS3 freq conf
			REG_ADDR_0088	=	8'd88	, // MS3 freq conf
			REG_ADDR_0089	=	8'd89	, // MS3 freq conf
			REG_ADDR_0090	=	8'd90	, // MS3 freq conf
			REG_ADDR_0091	=	8'd91	, // MS3 freq conf
			REG_ADDR_0092	=	8'd92	, // MS3 freq conf
			REG_ADDR_0093	=	8'd93	, // MS3 freq conf
			REG_ADDR_0094	=	8'd94	, // MS3 freq conf
			REG_ADDR_0095	=	8'd95	, // MS3 freq conf
			REG_ADDR_0097	=	8'd97	, // MSN fb conf
			REG_ADDR_0098	=	8'd98	, // MSN fb conf
			REG_ADDR_0099	=	8'd99	, // MSN fb conf
			REG_ADDR_0100	=	8'd100	, // MSN fb conf
			REG_ADDR_0101	=	8'd101	, // MSN fb conf
			REG_ADDR_0102	=	8'd102	, // MSN fb conf
			REG_ADDR_0103	=	8'd103	, // MSN fb conf
			REG_ADDR_0104	=	8'd104	, // MSN fb conf
			REG_ADDR_0105	=	8'd105	, // MSN fb conf
			REG_ADDR_0106	=	8'd106	; // MSN fb conf



/*
	wire	[7:0]	REG_ADDR_PAGE	=	8'hFF	; // set to 0 for addresses 0-254, 1 for 256-347

	wire	[7:0]	REG_ADDR_0006	=	8'd6	; // Interrupt mask
	wire	[7:0]	REG_ADDR_0027	=	8'd27	; // I2C conf
	wire	[7:0]	REG_ADDR_0028	=	8'd28	; // Input mux
	wire	[7:0]	REG_ADDR_0029	=	8'd29	; // Input mux
	wire	[7:0]	REG_ADDR_0030	=	8'd30	; // Input mux
	wire	[7:0]	REG_ADDR_0031	=	8'd31	; // Output conf
	wire	[7:0]	REG_ADDR_0032	=	8'd32	; // Output conf
	wire	[7:0]	REG_ADDR_0033	=	8'd33	; // Output conf
	wire	[7:0]	REG_ADDR_0034	=	8'd34	; // Output conf
	wire	[7:0]	REG_ADDR_0035	=	8'd35	; // Output conf
	wire	[7:0]	REG_ADDR_0036	=	8'd36	; // Output conf
	wire	[7:0]	REG_ADDR_0037	=	8'd37	; // Output conf
	wire	[7:0]	REG_ADDR_0038	=	8'd38	; // Output conf
	wire	[7:0]	REG_ADDR_0039	=	8'd39	; // Output conf
	wire	[7:0]	REG_ADDR_0040	=	8'd40	; // Output driver trim
	wire	[7:0]	REG_ADDR_0041	=	8'd41	; // Output driver trim
	wire	[7:0]	REG_ADDR_0042	=	8'd42	; // Output driver trim
	wire	[7:0]	REG_ADDR_0047	=	8'd47	; // Input conf
	wire	[7:0]	REG_ADDR_0048	=	8'd48	; // PLL conf
	wire	[7:0]	REG_ADDR_0049	=	8'd49	; // PLL conf
	wire	[7:0]	REG_ADDR_0050	=	8'd50	; // PLL conf
	wire	[7:0]	REG_ADDR_0051	=	8'd51	; // PLL conf
	wire	[7:0]	REG_ADDR_0052	=	8'd52	; // MS0 freq conf
	wire	[7:0]	REG_ADDR_0053	=	8'd53	; // MS0 freq conf
	wire	[7:0]	REG_ADDR_0054	=	8'd54	; // MS0 freq conf
	wire	[7:0]	REG_ADDR_0055	=	8'd55	; // MS0 freq conf
	wire	[7:0]	REG_ADDR_0056	=	8'd56	; // MS0 freq conf
	wire	[7:0]	REG_ADDR_0057	=	8'd57	; // MS0 freq conf
	wire	[7:0]	REG_ADDR_0058	=	8'd58	; // MS0 freq conf
	wire	[7:0]	REG_ADDR_0059	=	8'd59	; // MS0 freq conf
	wire	[7:0]	REG_ADDR_0060	=	8'd60	; // MS0 freq conf
	wire	[7:0]	REG_ADDR_0061	=	8'd61	; // MS0 freq conf
	wire	[7:0]	REG_ADDR_0062	=	8'd62	; // MS0 freq conf
	wire	[7:0]	REG_ADDR_0063	=	8'd63	; // MS1 freq conf
	wire	[7:0]	REG_ADDR_0064	=	8'd64	; // MS1 freq conf
	wire	[7:0]	REG_ADDR_0065	=	8'd65	; // MS1 freq conf
	wire	[7:0]	REG_ADDR_0066	=	8'd66	; // MS1 freq conf
	wire	[7:0]	REG_ADDR_0067	=	8'd67	; // MS1 freq conf
	wire	[7:0]	REG_ADDR_0068	=	8'd68	; // MS1 freq conf
	wire	[7:0]	REG_ADDR_0069	=	8'd69	; // MS1 freq conf
	wire	[7:0]	REG_ADDR_0070	=	8'd70	; // MS1 freq conf
	wire	[7:0]	REG_ADDR_0071	=	8'd71	; // MS1 freq conf
	wire	[7:0]	REG_ADDR_0072	=	8'd72	; // MS1 freq conf
	wire	[7:0]	REG_ADDR_0073	=	8'd73	; // MS1 freq conf
	wire	[7:0]	REG_ADDR_0074	=	8'd74	; // MS2 freq conf
	wire	[7:0]	REG_ADDR_0075	=	8'd75	; // MS2 freq conf
	wire	[7:0]	REG_ADDR_0076	=	8'd76	; // MS2 freq conf
	wire	[7:0]	REG_ADDR_0077	=	8'd77	; // MS2 freq conf
	wire	[7:0]	REG_ADDR_0078	=	8'd78	; // MS2 freq conf
	wire	[7:0]	REG_ADDR_0079	=	8'd79	; // MS2 freq conf
	wire	[7:0]	REG_ADDR_0080	=	8'd80	; // MS2 freq conf
	wire	[7:0]	REG_ADDR_0081	=	8'd81	; // MS2 freq conf
	wire	[7:0]	REG_ADDR_0082	=	8'd82	; // MS2 freq conf
	wire	[7:0]	REG_ADDR_0083	=	8'd83	; // MS2 freq conf
	wire	[7:0]	REG_ADDR_0084	=	8'd84	; // MS2 freq conf
	wire	[7:0]	REG_ADDR_0085	=	8'd85	; // MS3 freq conf
	wire	[7:0]	REG_ADDR_0086	=	8'd86	; // MS3 freq conf
	wire	[7:0]	REG_ADDR_0087	=	8'd87	; // MS3 freq conf
	wire	[7:0]	REG_ADDR_0088	=	8'd88	; // MS3 freq conf
	wire	[7:0]	REG_ADDR_0089	=	8'd89	; // MS3 freq conf
	wire	[7:0]	REG_ADDR_0090	=	8'd90	; // MS3 freq conf
	wire	[7:0]	REG_ADDR_0091	=	8'd91	; // MS3 freq conf
	wire	[7:0]	REG_ADDR_0092	=	8'd92	; // MS3 freq conf
	wire	[7:0]	REG_ADDR_0093	=	8'd93	; // MS3 freq conf
	wire	[7:0]	REG_ADDR_0094	=	8'd94	; // MS3 freq conf
	wire	[7:0]	REG_ADDR_0095	=	8'd95	; // MS3 freq conf
	wire	[7:0]	REG_ADDR_0097	=	8'd97	; // MSN fb conf
	wire	[7:0]	REG_ADDR_0098	=	8'd98	; // MSN fb conf
	wire	[7:0]	REG_ADDR_0099	=	8'd99	; // MSN fb conf
	wire	[7:0]	REG_ADDR_0100	=	8'd100	; // MSN fb conf
	wire	[7:0]	REG_ADDR_0101	=	8'd101	; // MSN fb conf
	wire	[7:0]	REG_ADDR_0102	=	8'd102	; // MSN fb conf
	wire	[7:0]	REG_ADDR_0103	=	8'd103	; // MSN fb conf
	wire	[7:0]	REG_ADDR_0104	=	8'd104	; // MSN fb conf
	wire	[7:0]	REG_ADDR_0105	=	8'd105	; // MSN fb conf
	wire	[7:0]	REG_ADDR_0106	=	8'd106	; // MSN fb conf

*/

//=============    wire   all  reg  address value  end ===============

//=============   assign all parameter value  ===============

localparam PLL_LOL_MASK = 0,
        LOS_FDBK_MASK = 1,
        LOS_CLKIN_MASK = 0,
        SYS_CAL_MASK = 0,
        I2C_1P8_SEL = 0,
 		I2C_ADDR = 7'b1110000;

localparam P2DIV_IN = 3'b100,
	 	P1DIV_IN = 5'b01010,
 		XTAL_FREQ = 2'b11;

localparam PFD_IN_REF = 3'b000,
	 	P1DIV = 3'b000;

localparam PFD_IN_FB = 3'b101,
	 	P2DIV = 3'b000;

localparam R0DIV_IN = 3'b110,
		R0DIV = 3'b000,
		MS0_PDN = 0,
 		DRV0_PDN = 0;

localparam R1DIV_IN = 3'b110,
		R1DIV = 3'b000,
 		MS1_PDN = 1,
 		DRV1_PDN = 1;

localparam R2DIV_IN = 3'b110,
		R2DIV = 3'b000,
 		MS2_PDN = 1,
 		DRV2_PDN = 1;

localparam R3DIV_IN = 3'b110,
		R3DIV = 3'b000,
 		MS3_PDN = 1,
 		DRV3_PDN = 1;

localparam DRV3_VDDO = 2'b00,
			DRV2_VDDO = 2'b10,
			DRV1_VDDO = 2'b00,
			DRV0_VDDO = 2'b10;

localparam DRV0_INV = 2'b00,
	 	DRV0_FMT = 3'b011,
 		DRV1_INV = 2'b00,
 		DRV1_FMT = 3'b011,
 		DRV2_INV = 2'b00,
 		DRV2_FMT = 3'b111,
 		DRV3_INV = 2'b00,
 		DRV3_FMT = 3'b011;

localparam DRV0_TRIM = 5'b10101,
	 	DRV1_TRIM = 5'b10111,
 		DRV2_TRIM = 5'b00111,
 		DRV3_TRIM = 5'b10111;

localparam  FCAL_OVRD = 18'd0;

localparam PFD_EXTFB = 0,
	 	PLL_KPHI = 7'b0111010;

localparam FCAL_OVRD_EN = 0,
	 	VCO_GAIN = 3'b000,
 		RSEL = 2'b00,
 		BWSEL = 2'b00;

localparam PLL_ENABLE = 2'b11,
	 	MSCAL = 6'b000100;

localparam MS3_HS = 0,
	 	MS2_HS = 0,
 		MS1_HS = 0,
 		MS0_HS = 0,
 		MS_PEC = 3'b111;

localparam MS0_FIDCT = 2'b00,
	 	MS0_FIDDIS = 1,
 		MS0_SSMODE = 2'b00,
 		MS0_PHIDCT = 2'b00;

localparam MS0_P1 = 18'd5888,
	 	MS0_P2 = 30'd0,
 		MS0_P3 = 30'd1;

localparam MS1_FIDCT = 2'b00,
	 	MS1_FIDDIS = 1,
 		MS1_SSMODE = 2'b00,
 		MS1_PHIDCT = 2'b00;

localparam MS1_P1 = 18'd12288, //WARNING: different setting between the device and Clockbuilder software (VCO running @2.6 GHz instead of 2.5)
	 	MS1_P2 = 30'd0,
 		MS1_P3 = 30'd1;

localparam MS2_FIDCT = 2'b00,
	 	MS2_FIDDIS = 1,
 		MS2_SSMODE = 2'b00,
 		MS2_PHIDCT = 2'b00;

localparam MS2_P1 = 18'd2150,  //optimal settings for achieving 125 MHz from the 2.6 GHz VCO
	 	MS2_P2 = 30'd32,
 		MS2_P3 = 30'd100;

localparam MS3_FIDCT = 2'b00,
	 	MS3_FIDDIS = 1,
 		MS3_SSMODE = 2'b00,
 		MS3_PHIDCT = 2'b00;

localparam MS3_P1 = 18'd5888,
	 	MS3_P2 = 30'd0,
 		MS3_P3 = 30'd1;

localparam MSN_P1 = 18'd5888,
	 	MSN_P2 = 30'd0,
 		MSN_P3 = 30'd1;

//=============   assign all parameter value end ===============


//=============   assign all parameter value to reg  ===============

localparam	REG_0006 = {3'b000, PLL_LOL_MASK, LOS_FDBK_MASK, LOS_CLKIN_MASK, 1'b0, SYS_CAL_MASK},
 		REG_0027 = {I2C_1P8_SEL, I2C_ADDR},
 		REG_0028 = {2'b0, P2DIV_IN[0], P1DIV_IN[2:0], XTAL_FREQ},
 		REG_0029 = {PFD_IN_REF, P1DIV_IN[4:3], P1DIV},
 		REG_0030 = {PFD_IN_FB, P2DIV_IN[2:1], P2DIV},
 		REG_0031 = {R0DIV_IN, R0DIV, MS0_PDN, DRV0_PDN},
 		REG_0032 = {R1DIV_IN, R1DIV, MS1_PDN, DRV1_PDN},
 		REG_0033 = {R2DIV_IN, R2DIV, MS2_PDN, DRV2_PDN},
 		REG_0034 = {R3DIV_IN, R3DIV, MS3_PDN, DRV3_PDN},
 		REG_0035 = {DRV3_VDDO, DRV2_VDDO, DRV1_VDDO, DRV0_VDDO},
 		REG_0036 = {3'b000, DRV0_INV, DRV0_FMT},
 		REG_0037 = {3'b000, DRV1_INV, DRV1_FMT},
 		REG_0038 = {3'b000, DRV2_INV, DRV2_FMT},
 		REG_0039 = {3'b000, DRV3_INV, DRV3_FMT},
 		REG_0040 = {DRV1_TRIM[2:0], DRV0_TRIM},
 		REG_0041 = {1'b0, DRV2_TRIM, DRV1_TRIM[4:3]},
 		REG_0042 = {3'b001, DRV3_TRIM},
 		REG_0045 = {FCAL_OVRD[7:0]},
 		REG_0046 = {FCAL_OVRD[15:8]},
 		REG_0047 = {6'b000101, FCAL_OVRD[17:16]},
 		REG_0048 = {PFD_EXTFB, PLL_KPHI},
 		REG_0049 = {FCAL_OVRD_EN, VCO_GAIN, RSEL, BWSEL},
 		REG_0050 = {PLL_ENABLE, MSCAL},
 		REG_0051 = {MS3_HS, MS2_HS, MS1_HS, MS0_HS, 1'b0, MS_PEC},
 		REG_0052 = {1'b0, MS0_FIDCT, MS0_FIDDIS, MS0_SSMODE, MS0_PHIDCT},
 		REG_0053 = {MS0_P1[7:0]},
 		REG_0054 = {MS0_P1[15:8]},
 		REG_0055 = {MS0_P2[5:0], MS0_P1[17:16]},
 		REG_0056 = {MS0_P2[13:6]},
 		REG_0057 = {MS0_P2[21:14]},
 		REG_0058 = {MS0_P2[29:22]},
 		REG_0059 = {MS0_P3[7:0]},
 		REG_0060 = {MS0_P3[15:8]},
 		REG_0061 = {MS0_P3[23:16]},
 		REG_0062 = {2'b00, MS0_P3[29:24]},
 		REG_0063 = {1'b0, MS1_FIDCT, MS1_FIDDIS, MS1_SSMODE, MS1_PHIDCT},
 		REG_0064 = {MS1_P1[7:0]},
 		REG_0065 = {MS1_P1[15:8]},
 		REG_0066 = {MS1_P2[5:0], MS1_P1[17:16]},
 		REG_0067 = {MS1_P2[13:6]},
 		REG_0068 = {MS1_P2[21:14]},
 		REG_0069 = {MS1_P2[29:22]},
 		REG_0070 = {MS1_P3[7:0]},
 		REG_0071 = {MS1_P3[15:8]},
 		REG_0072 = {MS1_P3[23:16]},
 		REG_0073 = {2'b00, MS1_P3[29:24]},
 		REG_0074 = {1'b0, MS2_FIDCT, MS2_FIDDIS, MS2_SSMODE, MS2_PHIDCT},
 		REG_0075 = {MS2_P1[7:0]},
 		REG_0076 = {MS2_P1[15:8]},
 		REG_0077 = {MS2_P2[5:0], MS2_P1[17:16]},
 		REG_0078 = {MS2_P2[13:6]},
 		REG_0079 = {MS2_P2[21:14]},
 		REG_0080 = {MS2_P2[29:22]},
 		REG_0081 = {MS2_P3[7:0]},
 		REG_0082 = {MS2_P3[15:8]},
 		REG_0083 = {MS2_P3[23:16]},
 		REG_0084 = {2'b00, MS2_P3[29:24]},
 		REG_0085 = {1'b0, MS3_FIDCT, MS3_FIDDIS, MS3_SSMODE, MS3_PHIDCT},
 		REG_0086 = {MS3_P1[7:0]},
 		REG_0087 = {MS3_P1[15:8]},
 		REG_0088 = {MS3_P2[5:0], MS3_P1[17:16]},
 		REG_0089 = {MS3_P2[13:6]},
 		REG_0090 = {MS3_P2[21:14]},
 		REG_0091 = {MS3_P2[29:22]},
 		REG_0092 = {MS3_P3[7:0]},
 		REG_0093 = {MS3_P3[15:8]},
 		REG_0094 = {MS3_P3[23:16]},
 		REG_0095 = {2'b00, MS3_P3[29:24]},
 		REG_0097 = {MSN_P1[7:0]},
 		REG_0098 = {MSN_P1[15:8]},
 		REG_0099 = {MSN_P2[5:0], MSN_P1[17:16]},
 		REG_0100 = {MSN_P2[13:6]},
 		REG_0101 = {MSN_P2[21:14]},
 		REG_0102 = {MSN_P2[29:22]},
 		REG_0103 = {MSN_P3[7:0]},
 		REG_0104 = {MSN_P3[15:8]},
 		REG_0105 = {MSN_P3[23:16]},
 		REG_0106 = {2'b10, MSN_P3[29:24]};

//=============================================================================
// Structural coding
//=============================================================================



//=====================================
//  State control
//=====================================
			
			
always@(posedge iCLK or negedge iRST_n)
	begin
		if (!iRST_n)
			begin
				i2c_reg_state <= 0;
			end
		else
			begin
				if (access_i2c_reg_start)
					i2c_reg_state <= 1'b1;
				else if (i2c_controller_config_done)
					i2c_reg_state <= i2c_reg_state+1;
				else if (i2c_reg_state == (`REG_NUM+1))
					i2c_reg_state <= 0;	
			end
	end
//=====================================
//  i2c bus address & data control 
//=====================================	



always@(*)
  begin
    i2c_ctrl_data = 0;
    case (i2c_reg_state)
        0	:	i2c_ctrl_data	=	{	NOT_LAST	,	slave_addr	,	8'd0	,	8'd0	,	read_cmd	}	;	// location 0 never used
//        1	:	i2c_ctrl_data	=	{	NOT_LAST	,	slave_addr	,  REG_ADDR_0065,  8'd0, read_cmd };
        1	:	i2c_ctrl_data	=	{	NOT_LAST	,	slave_addr	,  REG_ADDR_0075,  REG_0075, write_cmd };
        2	:	i2c_ctrl_data	=	{	NOT_LAST	,	slave_addr	,  REG_ADDR_0076,  REG_0076, write_cmd };
        3	:	i2c_ctrl_data	=	{	NOT_LAST	,	slave_addr	,  REG_ADDR_0077,  REG_0077, write_cmd };
        4	:	i2c_ctrl_data	=	{	NOT_LAST	,	slave_addr	,  REG_ADDR_0078,  REG_0078, write_cmd };
        5	:	i2c_ctrl_data	=	{	NOT_LAST	,	slave_addr	,  REG_ADDR_0079,  REG_0079, write_cmd };
        6	:	i2c_ctrl_data	=	{	NOT_LAST	,	slave_addr	,  REG_ADDR_0080,  REG_0080, write_cmd };
        7	:	i2c_ctrl_data	=	{	NOT_LAST	,	slave_addr	,  REG_ADDR_0081,  REG_0081, write_cmd };
        8	:	i2c_ctrl_data	=	{	NOT_LAST	,	slave_addr	,  REG_ADDR_0082,  REG_0082, write_cmd };
        9	:	i2c_ctrl_data	=	{	NOT_LAST	,	slave_addr	,  REG_ADDR_0083,  REG_0083, write_cmd };
        10	:	i2c_ctrl_data	=	{	NOT_LAST	,	slave_addr	,  REG_ADDR_0084,  REG_0084, write_cmd };
		default: i2c_ctrl_data	= 	{	NOT_LAST	,	slave_addr	,	8'd0	,	8'd0	,	read_cmd	}	;


    endcase	
  end 



edge_detector u1(
	.iCLK(iCLK),
	.iRST_n(iRST_n),
	.iIn(iI2C_CONTROLLER_CONFIG_DONE),
	.oFallING_EDGE(i2c_controller_config_done),
	.oRISING_EDGE()
);


always@(posedge iCLK or negedge iRST_n)
begin
	if (!iRST_n)
	begin
		oController_Ready <= 1'b1;
	end
	else if (i2c_reg_state == `REG_NUM+1)	
	begin
		oController_Ready <= 1'b1;
	end
	else if (i2c_reg_state >0)
	begin
		oController_Ready <= 1'b0;
	end
end


assign oONE_CLK_CONFIG_DONE = (i2c_reg_state == 0) ? 1'b1 : 1'b0;
assign access_next_i2c_reg_cmd = ((iI2C_CONTROLLER_STATE == 1'b0)&&
                                  ((i2c_reg_state <= `REG_NUM) && (i2c_reg_state > 0))
                                 ) ? 1'b1 : 1'b0;
assign access_i2c_reg_start = ((iENABLE == 1'b1)&&(iI2C_CONTROLLER_STATE == 1'b0)) ? 1'b1 : 1'b0;
		
endmodule 