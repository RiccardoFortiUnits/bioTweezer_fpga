// ============================================================================
// Copyright (c) 2015 by Terasic Inc.
// ============================================================================
//
// Permission:
//
// Terasic grants permission to use and modify this code for use
// in synthesis for all Terasic Development Boards and Altera Development
// Kits made by Terasic. Other use of this code, including the selling
// ,duplication, or modification of any portion is strictly prohibited.
//
// Disclaimer:
//
// This VHDL/Verilog or C/C++ source code is intended as a design reference
// which illustrates how these types of functions can be implemented.
// It is the user's responsibility to verify their design for
// consistency and functionality through the use of formal
// verification methods. Terasic provides no warranty regarding the use
// or functionality of this code.
//
// ============================================================================
//
// Terasic Technologies Inc
//  9F., No.176, Sec.2, Gongdao 5th Rd, East Dist, Hsinchu City, 30070. Taiwan
// HsinChu County, Taiwan
// 302
//
// web: http://www.terasic.com/
// email: support@terasic.com
//
// ============================================================================
// Major Functions:
//  This code is using for configuring the output frequency of 
//  SI570 I2C Programable XO/VCXO
// ============================================================================
// Design Description:
// 
//
//
// ===========================================================================
// Revision History :
// ============================================================================
// Ver :| Author :| Mod. Date :| Changes Made:
// V1.0 :| Johnny Fan :| 15/01/20 :| Initial Version
// ============================================================================

`include "si5338_i2c_reg_controller.v"
`include "initial_config.v"
`include "edge_detector.v"
`include "clock_divider.v"
`include "i2c_bus_controller.v"

module si5338_controller(

input                   iCLK,  // 50 MHz input clock
input                   iRST_n,
input                   iStart,

output	               I2C_CLK,
inout	               I2C_DATA,


output                  oPLL_REG_CONFIG_DONE

);

//=============================================================================
// PARAMETER declarations
//=============================================================================



//=============================================================================
// REG/WIRE declarations
//=============================================================================

wire [6:0]  slave_addr;
wire [7:0]  byte_addr;
wire [7:0]  byte_data;
wire        wr_cmd;
wire [7:0]  oREAD_Data;
wire [3:0]  iFREQ_MODE;
wire        i2c_control_start;
wire 			    i2c_reg_control_start;
wire 			    i2c_bus_controller_state;
wire			     iINITIAL_ENABLE;
wire 			    system_start;
wire 			    i2c_system_clk;
wire			     i2c_controller_config_done;
wire			     oController_Ready;
wire			     initial_start;
wire 					i2c_read_data_rdy;
//=============================================================================
// Structural coding
//=============================================================================


si5338_i2c_reg_controller si5338_i2c_reg_controller_0(

.iCLK(iCLK),
.iRST_n(iRST_n),
.iENABLE(system_start),

.iI2C_CONTROLLER_STATE(i2c_bus_controller_state),
.iI2C_CONTROLLER_CONFIG_DONE(i2c_controller_config_done),
.oSLAVE_ADDR(slave_addr),
.oBYTE_ADDR(byte_addr),
.oBYTE_DATA(byte_data),
.oWR_CMD(wr_cmd),
.oStart(i2c_reg_control_start),
.iI2C_READ_DATA(oREAD_Data),
.iI2C_READ_DATA_RDY(i2c_read_data_rdy),
.oONE_CLK_CONFIG_DONE(oPLL_REG_CONFIG_DONE),
.oController_Ready(oController_Ready)
);


initial_config initial_config_0(

.iCLK(iCLK), // system   clock 50mhz 
.iRST_n(iRST_n), // system reset 
.oINITIAL_START(initial_start),
.iINITIAL_ENABLE(1'b1)
);


wire istart_rsing;

//assign system_start = iStart|initial_start;
//assign system_start = iStart;
assign system_start = istart_rsing|initial_start;


edge_detector edge_detector_0(

.iCLK(iCLK),
.iRST_n(iRST_n),
.iIn(iStart),
.oFallING_EDGE(),
.oRISING_EDGE(istart_rsing)
);


clock_divider clock_divider_0(
.iCLK(iCLK),
.iRST_n(iRST_n),
.oCLK_OUT(i2c_system_clk)
);


i2c_bus_controller i2c_bus_controller_0	(

	.iCLK(i2c_system_clk),
	.iRST_n(iRST_n),
	.iStart(i2c_reg_control_start),
	.iSlave_addr(slave_addr),
	.iWord_addr(byte_addr),
	.iSequential_read(1'b0),
	.iRead_length(8'd1),
	
	.i2c_clk(I2C_CLK),
	.i2c_data(I2C_DATA),
	.i2c_read_data(oREAD_Data),
	.i2c_read_data_rdy(i2c_read_data_rdy),
	.wr_data(byte_data),
	.wr_cmd(wr_cmd),
  .oSYSTEM_STATE(i2c_bus_controller_state),
	.oCONFIG_DONE(i2c_controller_config_done)

	
	);





endmodule 
