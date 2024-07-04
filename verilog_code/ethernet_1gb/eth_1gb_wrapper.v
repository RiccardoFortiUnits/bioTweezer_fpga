`define FOUR_TX_PORTS

`include "xcvr_reset_synchronizer.v"
`include "mac_config/mac_config.v"
`include "trc_config/trc_config.v"
`include "udp_core8/udp_core8.v"

module eth_1gb_wrapper #(
    parameter AVL_SIZE = 8, //in bits
			MAC_SIZE = 48,
			IP_SIZE = 32,
			BYTE_SIZE = 8
	)

(

    input csr_clk,          //100 MHz clock for configuration
    input ref_clk,          //125 MHz reference clock

    input reset,

    input start_mac_trc_config,
    output      finish_trc,
    output 		finish_mac,
    //diagnostic leds
    output      led_link,
    output      led_activity,

    output      tx_xcvr_clk,
    output      rx_xcvr_clk,

    input [MAC_SIZE-1:0]    MAC_BOARD,
    input [IP_SIZE-1:0]     IP_BOARD,
    input [2*BYTE_SIZE-1:0] PORT_1,
    input [2*BYTE_SIZE-1:0] PORT_2,
`ifdef FOUR_TX_PORTS
    input [2*BYTE_SIZE-1:0] PORT_3,
    input [2*BYTE_SIZE-1:0] PORT_4,
`endif 

    //rx udp fifo - user side
    input rdclk_udp_rxfifo_0,
	
	input rdreq_data_udp_rxfifo_0,
	output [AVL_SIZE-1:0] data_from_udp_rxfifo_0,
	output rdempty_data_udp_rxfifo_0,

	input rdreq_status_udp_rxfifo_0,
	output [2*BYTE_SIZE+MAC_SIZE+IP_SIZE-1:0] status_from_udp_rxfifo_0,
	output rdempty_status_udp_rxfifo_0,

    input rdclk_udp_rxfifo_1,
	
	input rdreq_data_udp_rxfifo_1,
	output [AVL_SIZE-1:0] data_from_udp_rxfifo_1,
	output rdempty_data_udp_rxfifo_1,

	input rdreq_status_udp_rxfifo_1,
	output [2*BYTE_SIZE+MAC_SIZE+IP_SIZE-1:0] status_from_udp_rxfifo_1,
	output rdempty_status_udp_rxfifo_1,

    //tx udp fifo - user side
	input wrclk_udp_txfifo_0,

    input wrreq_data_udp_txfifo_0,
    input [AVL_SIZE-1:0] data_to_udp_txfifo_0,
    output wrfull_data_udp_txfifo_0,
    output [12:0] wrusedw_data_udp_txfifo_0,

    input wrreq_status_udp_txfifo_0,
	input [2*BYTE_SIZE+MAC_SIZE+IP_SIZE-1:0] status_to_udp_txfifo_0,
    output wrfull_status_udp_txfifo_0,
    output [7:0] wrusedw_status_udp_txfifo_0,

	input wrclk_udp_txfifo_1,

    input wrreq_data_udp_txfifo_1,
    input [AVL_SIZE-1:0] data_to_udp_txfifo_1,
    output wrfull_data_udp_txfifo_1,
    output [12:0] wrusedw_data_udp_txfifo_1,

    input wrreq_status_udp_txfifo_1,
	input [2*BYTE_SIZE+MAC_SIZE+IP_SIZE-1:0] status_to_udp_txfifo_1,
    output wrfull_status_udp_txfifo_1,
    output [7:0] wrusedw_status_udp_txfifo_1,

`ifdef FOUR_TX_PORTS
	input wrclk_udp_txfifo_2,

    input wrreq_data_udp_txfifo_2,
    input [AVL_SIZE-1:0] data_to_udp_txfifo_2,
    output wrfull_data_udp_txfifo_2,
    output [12:0] wrusedw_data_udp_txfifo_2,

    input wrreq_status_udp_txfifo_2,
	input [2*BYTE_SIZE+MAC_SIZE+IP_SIZE-1:0] status_to_udp_txfifo_2,
    output wrfull_status_udp_txfifo_2,
    output [7:0] wrusedw_status_udp_txfifo_2,

	input wrclk_udp_txfifo_3,

    input wrreq_data_udp_txfifo_3,
    input [AVL_SIZE-1:0] data_to_udp_txfifo_3,
    output wrfull_data_udp_txfifo_3,
    output [12:0] wrusedw_data_udp_txfifo_3,

    input wrreq_status_udp_txfifo_3,
	input [2*BYTE_SIZE+MAC_SIZE+IP_SIZE-1:0] status_to_udp_txfifo_3,
    output wrfull_status_udp_txfifo_3,
    output [7:0] wrusedw_status_udp_txfifo_3,
`endif 

	output 		tx_serial_data,
	input 		rx_serial_data

);


// TRC CONFIGURATION ENTITY

//wire finish_trc;

wire			trc_mgmt_read;
wire			trc_mgmt_write;
wire			trc_mgmt_waitrequest;
wire [31:0]	trc_mgmt_readdata;
wire [31:0]	trc_mgmt_writedata;
wire [7:0]	trc_mgmt_address;

reg start_1, start_2;

always @(posedge csr_clk ) begin
    start_2 <= start_1;
    start_1 <= start_mac_trc_config;
end
        

trc_config trc_config_0(
       // user signals
       .clock(csr_clk),
       .reset(reset),
       .start(start_2),
       .finish_trc(finish_trc),
       // signals to Transceiver Reconfiguration Controller
       .avl_busy(trc_mgmt_waitrequest),
       .avl_readdata(trc_mgmt_readdata),
       .avl_read_req(trc_mgmt_read),
       .avl_write_req(trc_mgmt_write),
       .avl_address(trc_mgmt_address),
       .avl_writedata(trc_mgmt_writedata)
       
);



// TRANSCEIVER RECONFIGURATION CONTROLLER

wire [139:0]	reconfig_to_xcvr;
wire [91:0]		reconfig_from_xcvr;

xcvr_rst xcvr_rst_0(
        // user signals
        .reconfig_busy(),             				//      reconfig_busy.reconfig_busy
        .mgmt_clk_clk(csr_clk),             				//       mgmt_clk_clk.clk
        .mgmt_rst_reset(reset),            					//     mgmt_rst_reset.reset
        // signals to TRC configurator
        .reconfig_mgmt_address(trc_mgmt_address),     		//      reconfig_mgmt.address [6:0]
        .reconfig_mgmt_read(trc_mgmt_read),        			//                   .read
        .reconfig_mgmt_readdata(trc_mgmt_readdata),    		//                   .readdata
        .reconfig_mgmt_waitrequest(trc_mgmt_waitrequest), 	//                   .waitrequest [31:0]
        .reconfig_mgmt_write(trc_mgmt_write),      			//                   .write
        .reconfig_mgmt_writedata(trc_mgmt_writedata),   	//                   .writedata [31:0]
        // signals to MAC
        .reconfig_to_xcvr(reconfig_to_xcvr),             //   ch0_1_to_xcvr.reconfig_to_xcvr
        .reconfig_from_xcvr(reconfig_from_xcvr)           // ch0_1_from_xcvr.reconfig_from_xcvr
    );




//----------------------------------------------------------

//MAC configuration
wire            mac_csr_read;
wire            mac_csr_write;
wire [31:0]     mac_csr_readdata;
wire [31:0]     mac_csr_writedata;
wire            mac_csr_waitrequest;
wire [7:0]      mac_csr_address;


mac_config 	mac_config_0(
    // user signals
    .clock          (csr_clk),
    .reset          (reset),
    .start          (finish_trc),
    .finish_mac     (finish_mac),
    .mac_address    (MAC_BOARD),	
    // signals to MAC control port
    .avl_busy       (mac_csr_waitrequest),
    .avl_readdata   (mac_csr_readdata),
    .avl_address    (mac_csr_address),
    .avl_writedata  (mac_csr_writedata),
    .avl_read_req   (mac_csr_read),
    .avl_write_req  (mac_csr_write)
        
);	

// avalon_st rx interface
wire 		        avalon_st_rx_startofpacket;
wire 		        avalon_st_rx_endofpacket;
wire 		        avalon_st_rx_valid;
wire [AVL_SIZE-1:0]	avalon_st_rx_data;
wire		        avalon_st_rx_ready;
wire [4:0]	        avalon_st_rx_error;

//avalon_st tx interface
wire 		        avalon_st_tx_startofpacket;
wire 		        avalon_st_tx_endofpacket;
wire 		        avalon_st_tx_valid;
wire [AVL_SIZE-1:0]	avalon_st_tx_data;
wire 		        avalon_st_tx_error;
wire 		        avalon_st_tx_ready;


tse_core tse_core_0 (
    .ref_clk              (ref_clk),              //   input,   width = 1,         pcs_ref_clk_clock_connection.clk
    .reset                (reset),                //   input,   width = 1,                     reset_connection.reset

    .clk                  (csr_clk),                  //   input,   width = 1,        control_port_clock_connection.clk
    .reg_data_out         (mac_csr_readdata),         //  output,  width = 32,                         control_port.readdata
    .reg_rd               (mac_csr_read),               //   input,   width = 1,                                     .read
    .reg_data_in          (mac_csr_writedata),          //   input,  width = 32,                                     .writedata
    .reg_wr               (mac_csr_write),               //   input,   width = 1,                                     .write
    .reg_busy             (mac_csr_waitrequest),             //  output,   width = 1,                                     .waitrequest
    .reg_addr             (mac_csr_address),             //   input,   width = 8,                                     .address
    
    .mac_rx_clk_0         (rx_xcvr_clk),         //  output,   width = 1,            mac_rx_clock_connection_0.clk
    .data_rx_sop_0        (avalon_st_rx_startofpacket),        //  output,   width = 1,                                     .startofpacket
    .data_rx_eop_0        (avalon_st_rx_endofpacket),        //  output,   width = 1,                                     .endofpacket
    .data_rx_data_0       (avalon_st_rx_data),       //  output,   width = 8,                            receive_0.data
    .data_rx_error_0      (avalon_st_rx_error),      //  output,   width = 5,                                     .error
    .data_rx_ready_0      (avalon_st_rx_ready),      //   input,   width = 1,                                     .ready
    .data_rx_valid_0      (avalon_st_rx_valid),      //  output,   width = 1,                                     .valid

    .rx_afull_clk         (csr_clk),         //   input,   width = 1, receive_fifo_status_clock_connection.clk
    .rx_afull_data        (2'b00),        //   input,   width = 2,                  receive_fifo_status.data
    .rx_afull_valid       (1'b1),       //   input,   width = 1,                                     .valid
    .rx_afull_channel     (1'b0),     //   input,   width = 1,                                     .channel
    
    .mac_tx_clk_0         (tx_xcvr_clk),         //  output,   width = 1,            mac_tx_clock_connection_0.clk
    .data_tx_sop_0        (avalon_st_tx_startofpacket),        //   input,   width = 1,                                     .startofpacket
    .data_tx_eop_0        (avalon_st_tx_endofpacket),        //   input,   width = 1,                                     .endofpacket
    .data_tx_data_0       (avalon_st_tx_data),       //   input,   width = 8,                           transmit_0.data
    .data_tx_error_0      (avalon_st_tx_error),      //   input,   width = 1,                                     .error
    .data_tx_ready_0      (avalon_st_tx_ready),      //  output,   width = 1,                                     .ready
    .data_tx_valid_0      (avalon_st_tx_valid),      //   input,   width = 1,                                     .valid

    .pkt_class_data_0     (),     //  output,   width = 5,                receive_packet_type_0.data
    .pkt_class_valid_0    (),    //  output,   width = 1,                                     .valid
    .tx_crc_fwd_0         (1'b0),         //   input,   width = 1,                mac_misc_connection_0.export
    
    .led_crs_0            (led_activity),            //  output,   width = 1,              status_led_connection_0.crs
    .led_link_0           (led_link),           //  output,   width = 1,                                     .link
    .led_panel_link_0     (),     //  output,   width = 1,                                     .panel_link
    .led_col_0            (),            //  output,   width = 1,                                     .col
    .led_an_0             (),             //  output,   width = 1,                                     .an
    .led_char_err_0       (),       //  output,   width = 1,                                     .char_err
    .led_disp_err_0       (),       //  output,   width = 1,                                     .disp_err

    .reconfig_togxb_0(reconfig_to_xcvr),   //                                     .reconfig_togxb
	.reconfig_fromgxb_0(reconfig_from_xcvr), //                                     .reconfig_fromgxb

    .rx_recovclkout_0     (),      //  output,   width = 1,          serdes_control_connection_0.export
    
    .rxp_0                (rx_serial_data),                //   input,   width = 1,                  serial_connection_0.rxp
    .txp_0                (tx_serial_data)                //  output,   width = 1,                                     .txp
);

 wire tx_reset;
 wire rx_reset;

    // Clock and reset
xcvr_reset_synchronizer #(
        .DEPTH      (2),
        .ASYNC_RESET(1)
    ) tx_rst_sync (
        .clk        (tx_xcvr_clk),
        .reset_in   (reset),
        .reset_out  (tx_reset)
    );

    // Clock and reset
xcvr_reset_synchronizer #(
        .DEPTH      (2),
        .ASYNC_RESET(1)
    ) rx_rst_sync (
        .clk        (rx_xcvr_clk),
        .reset_in   (reset),
        .reset_out  (rx_reset)
    );	


udp_core8 udp_core8_0 (

    .rx_xcvr_clk(rx_xcvr_clk),
    .rx_sync_rst(rx_reset),

    .tx_xcvr_clk(tx_xcvr_clk),
    .tx_sync_rst(tx_reset),

    .local_mac(MAC_BOARD),
    .local_ip(IP_BOARD),
    .local_stream_1_port(PORT_1),
    .local_stream_2_port(PORT_2),
`ifdef FOUR_TX_PORTS
    .local_stream_3_port(PORT_3),
    .local_stream_4_port(PORT_4),
`endif 

    .st_rx_startofpacket(avalon_st_rx_startofpacket),
    .st_rx_endofpacket(avalon_st_rx_endofpacket),
    .st_rx_valid(avalon_st_rx_valid),
    .st_rx_data(avalon_st_rx_data),
    .st_rx_ready(avalon_st_rx_ready),
    .st_rx_error(),

    .st_tx_startofpacket(avalon_st_tx_startofpacket),
    .st_tx_endofpacket(avalon_st_tx_endofpacket),
    .st_tx_valid(avalon_st_tx_valid),
    .st_tx_data(avalon_st_tx_data),
    .st_tx_ready(avalon_st_tx_ready),
    .st_tx_error(),

    .rdclk_udp_rxfifo_0(rdclk_udp_rxfifo_0),
	
	.rdreq_data_udp_rxfifo_0(rdreq_data_udp_rxfifo_0),
	.data_from_udp_rxfifo_0(data_from_udp_rxfifo_0),
	.rdempty_data_udp_rxfifo_0(rdempty_data_udp_rxfifo_0),

	.rdreq_status_udp_rxfifo_0(rdreq_status_udp_rxfifo_0),
	.status_from_udp_rxfifo_0(status_from_udp_rxfifo_0),
	.rdempty_status_udp_rxfifo_0(rdempty_status_udp_rxfifo_0),

    .rdclk_udp_rxfifo_1(rdclk_udp_rxfifo_1),
	
	.rdreq_data_udp_rxfifo_1(rdreq_data_udp_rxfifo_1),
	.data_from_udp_rxfifo_1(data_from_udp_rxfifo_1),
	.rdempty_data_udp_rxfifo_1(rdempty_data_udp_rxfifo_1),

	.rdreq_status_udp_rxfifo_1(rdreq_status_udp_rxfifo_1),
	.status_from_udp_rxfifo_1(status_from_udp_rxfifo_1),
	.rdempty_status_udp_rxfifo_1(rdempty_status_udp_rxfifo_1),

    .wrclk_udp_txfifo_0(wrclk_udp_txfifo_0),

    .wrreq_data_udp_txfifo_0(wrreq_data_udp_txfifo_0),
    .data_to_udp_txfifo_0(data_to_udp_txfifo_0),
    .wrfull_data_udp_txfifo_0(wrfull_data_udp_txfifo_0),
    .wrusedw_data_udp_txfifo_0(wrusedw_data_udp_txfifo_0), 

    .wrreq_status_udp_txfifo_0(wrreq_status_udp_txfifo_0),
	.status_to_udp_txfifo_0(status_to_udp_txfifo_0),
    .wrfull_status_udp_txfifo_0(wrfull_status_udp_txfifo_0),
    .wrusedw_status_udp_txfifo_0(wrusedw_status_udp_txfifo_0),

    .wrclk_udp_txfifo_1(wrclk_udp_txfifo_1),

    .wrreq_data_udp_txfifo_1(wrreq_data_udp_txfifo_1),
    .data_to_udp_txfifo_1(data_to_udp_txfifo_1),
    .wrfull_data_udp_txfifo_1(wrfull_data_udp_txfifo_1),
    .wrusedw_data_udp_txfifo_1(wrusedw_data_udp_txfifo_1),

    .wrreq_status_udp_txfifo_1(wrreq_status_udp_txfifo_1),
	.status_to_udp_txfifo_1(status_to_udp_txfifo_1),
    .wrfull_status_udp_txfifo_1(wrfull_status_udp_txfifo_1),
    .wrusedw_status_udp_txfifo_1(wrusedw_status_udp_txfifo_1)

`ifdef FOUR_TX_PORTS
    ,
    .wrclk_udp_txfifo_2(wrclk_udp_txfifo_2),

    .wrreq_data_udp_txfifo_2(wrreq_data_udp_txfifo_2),
    .data_to_udp_txfifo_2(data_to_udp_txfifo_2),
    .wrfull_data_udp_txfifo_2(wrfull_data_udp_txfifo_2),
    .wrusedw_data_udp_txfifo_2(wrusedw_data_udp_txfifo_2), 

    .wrreq_status_udp_txfifo_2(wrreq_status_udp_txfifo_2),
	.status_to_udp_txfifo_2(status_to_udp_txfifo_2),
    .wrfull_status_udp_txfifo_2(wrfull_status_udp_txfifo_2),
    .wrusedw_status_udp_txfifo_2(wrusedw_status_udp_txfifo_2),

    .wrclk_udp_txfifo_3(wrclk_udp_txfifo_3),

    .wrreq_data_udp_txfifo_3(wrreq_data_udp_txfifo_3),
    .data_to_udp_txfifo_3(data_to_udp_txfifo_3),
    .wrfull_data_udp_txfifo_3(wrfull_data_udp_txfifo_3),
    .wrusedw_data_udp_txfifo_3(wrusedw_data_udp_txfifo_3),

    .wrreq_status_udp_txfifo_3(wrreq_status_udp_txfifo_3),
	.status_to_udp_txfifo_3(status_to_udp_txfifo_3),
    .wrfull_status_udp_txfifo_3(wrfull_status_udp_txfifo_3),
    .wrusedw_status_udp_txfifo_3(wrusedw_status_udp_txfifo_3)

`endif 

);

endmodule
