`include "dec_comm8_port1.v"
`include "dec_comm8_port2.v"
`include "dec_comm8_port3.v"
`include "dec_comm8_port4.v"
`include "meta_decoder.v"
`include "../ethernet_1gb/eth_1gb_wrapper.v"

module network_wrapper #(
    parameter MAC_BOARD_1 = 48'h02_00_00_00_0C_E0,  //MAC
    IP_BOARD_1 = {8'd192, 8'd168, 8'd1, 8'd12},     //IP
    PORT_1 = 2047,
    PORT_2 = 2048,
    LOCKIN_NUMBER = 32
) (
    input   clock_100,  //100 MHz clock input
    input   ref_clk_125,  //125 MHz clock input for ethernet
    input   reset,
    input   start_mac_trc_config,   //input to start the configuration

    input   sfp_rx_0,       
    output  sfp_tx_0,

    // configuration status outputs
    output  led_link,
    output  trc_configured,
    output  mac_configured,
    output  rx_xcvr_clk,  //125 MHz clock output for synchronization with the ethernet wrapper
    
    // GENERAL PARAMETERS //
	 output pi_enable_cmd,
    output pi_reset_cmd,
	 
    output [25:0] pi_kp_coefficient,
    output        pi_kp_coefficient_update_cmd,
    output [25:0] pi_ti_coefficient,
    output        pi_ti_coefficient_update_cmd,
    output [25:0] pi_setpoint,
    output        pi_setpoint_update_cmd,
    output [16:0] pi_limit_HI,
    output [16:0] pi_limit_LO,
    
    output        pi_rdreq_output_fifo,
    input  [15:0] pi_rddata_output_fifo, 
    input         pi_rdempty_output_fifo,
	 
    output        x_rdreq_fifo,
    input  [15:0] x_rddata_fifo, 
    input         x_rdempty_fifo,
    output        y_rdreq_fifo,
    input  [15:0] y_rddata_fifo, 
    input         y_rdempty_fifo,
    output        z_rdreq_fifo,
    input  [15:0] z_rddata_fifo, 
    input         z_rdempty_fifo,
	 
    output        xSquare_rdreq_fifo,
    input  [15:0] xSquare_rddata_fifo, 
    input         xSquare_rdempty_fifo,
    output        ySquare_rdreq_fifo,
    input  [15:0] ySquare_rddata_fifo, 
    input         ySquare_rdempty_fifo,
    output        zSquare_rdreq_fifo,
    input  [15:0] zSquare_rddata_fifo, 
    input         zSquare_rdempty_fifo,
	 
	 
    // DACs and ADC status
    input  DAC_running,
	 input DAC_stopped,
    input  ADC_ready,
	 
	 input [7:0] SW,
	 input [3:0] KEY
	 
	 ,output[3:0] led

);

//////////// ETHERNET - UDP core ////////////////

wire [7:0]	         rx_fifo_data0;
wire		         rx_fifo_data_read0;
wire [95:0]	         rx_fifo_status0;
wire		         rx_fifo_status_empty0;
wire		         rx_fifo_status_read0;
wire [7:0]	         tx_fifo_data0;
wire		         tx_fifo_data_write0;
wire		         tx_fifo_data_full0;
wire [95:0]	         tx_fifo_status0;
wire		         tx_fifo_status_write0;
wire		         tx_fifo_status_full0;

wire [7:0]	         rx_fifo_data1;
wire		         rx_fifo_data_read1;
wire                 rx_fifo_data_empty1;
wire [95:0]	         rx_fifo_status1;
wire		         rx_fifo_status_empty1;
wire		         rx_fifo_status_read1;
wire [7:0]	         tx_fifo_data1;
wire		         tx_fifo_data_write1;
wire		         tx_fifo_data_full1;
wire [95:0]	         tx_fifo_status1;
wire		         tx_fifo_status_write1;
wire		         tx_fifo_status_full1;

eth_1gb_wrapper eth_1gb_wrapper_0 (

    .csr_clk(clock_100),          //100 MHz clock for configuration
    .ref_clk(ref_clk_125),        //125 MHz reference clock

    .reset(reset),
    .start_mac_trc_config(start_mac_trc_config),

    .MAC_BOARD(MAC_BOARD_1),
    .IP_BOARD(IP_BOARD_1),
    .PORT_1(PORT_1),
    .PORT_2(PORT_2),   

    .led_link(led_link),
    .led_activity(),
    
    .finish_trc(trc_configured),
    .finish_mac(mac_configured),
    // output clocks
    .tx_xcvr_clk(),
    .rx_xcvr_clk(rx_xcvr_clk),

    // RX udp fifo for port 1 and 2
    .rdclk_udp_rxfifo_0(rx_xcvr_clk),	
	.rdreq_data_udp_rxfifo_0(rx_fifo_data_read0),
	.data_from_udp_rxfifo_0(rx_fifo_data0),
	.rdempty_data_udp_rxfifo_0(),
	.rdreq_status_udp_rxfifo_0(rx_fifo_status_read0),
	.status_from_udp_rxfifo_0(rx_fifo_status0),
	.rdempty_status_udp_rxfifo_0(rx_fifo_status_empty0),

    .rdclk_udp_rxfifo_1(rx_xcvr_clk),	
	.rdreq_data_udp_rxfifo_1(rx_fifo_data_read1),
	.data_from_udp_rxfifo_1(rx_fifo_data1),
	.rdempty_data_udp_rxfifo_1(rx_fifo_data_empty1),
	.rdreq_status_udp_rxfifo_1(rx_fifo_status_read1),
	.status_from_udp_rxfifo_1(rx_fifo_status1),
	.rdempty_status_udp_rxfifo_1(rx_fifo_status_empty1),

    // TX udp fifo for port 1, 2, e and 4
    .wrclk_udp_txfifo_0(rx_xcvr_clk),
    .wrreq_data_udp_txfifo_0(tx_fifo_data_write0),
    .data_to_udp_txfifo_0(tx_fifo_data0),
    .wrfull_data_udp_txfifo_0(tx_fifo_data_full0),
    .wrusedw_data_udp_txfifo_0(),
    .wrreq_status_udp_txfifo_0(tx_fifo_status_write0),
	.status_to_udp_txfifo_0(tx_fifo_status0),
    .wrfull_status_udp_txfifo_0(tx_fifo_status_full0),
    .wrusedw_status_udp_txfifo_0(),

    .wrclk_udp_txfifo_1(rx_xcvr_clk),
    .wrreq_data_udp_txfifo_1(tx_fifo_data_write1),
    .data_to_udp_txfifo_1(tx_fifo_data1),
    .wrfull_data_udp_txfifo_1(tx_fifo_data_full1),
    .wrusedw_data_udp_txfifo_1(),
    .wrreq_status_udp_txfifo_1(tx_fifo_status_write1),
	.status_to_udp_txfifo_1(tx_fifo_status1),
    .wrfull_status_udp_txfifo_1(tx_fifo_status_full1),
    .wrusedw_status_udp_txfifo_1(),

    //diff pair to SFP module
	.tx_serial_data(sfp_tx_0),
	.rx_serial_data(sfp_rx_0)
);

///////////// DECODERS ///////////////
//Synchronize mac_configured to the decoder clock domain (always high when configured)
wire mac_configured_125; //used to reset the decoders until the MAC is configured
sync_edge_det sync_edge_det_mac_configured(
    .clk(rx_xcvr_clk),
    .signal_in(mac_configured),
    .data_out(mac_configured_125)
);

/// DECODER 1 /// used to receive the commands from the client
wire [47:0] client_mac; //MAC of the client
wire [31:0] client_ip; //IP of the client

wire [31:0] received_data;

wire wipe_settings;
wire received_control_param_valid, received_pi_enable_cmd_valid, received_pi_reset_cmd_valid;

wire control_param_written;

wire control_param_ack, control_param_nak, control_param_err;
wire pi_enable_cmd_ack, pi_enable_cmd_nak, pi_enable_cmd_err;
wire pi_reset_cmd_ack,  pi_reset_cmd_nak,  pi_reset_cmd_err;

new_dec_comm8_port1 dec_comm8_1 
(
    .clk(rx_xcvr_clk),
    .reset(~mac_configured_125),

    .source_mac(client_mac),
    .source_ip(client_ip),

    // rx fifo interface from 1gb eth
    .rx_fifo_data(rx_fifo_data0),
    .rx_fifo_data_read(rx_fifo_data_read0),
    .rx_fifo_status(rx_fifo_status0),
    .rx_fifo_status_empty(rx_fifo_status_empty0),
    .rx_fifo_status_read(rx_fifo_status_read0),

    // tx fifo interface to 1gb eth (for ack)
    .tx_fifo_data(tx_fifo_data0),
    .tx_fifo_status(tx_fifo_status0),
    .tx_fifo_data_write(tx_fifo_data_write0),
    .tx_fifo_status_write(tx_fifo_status_write0),
    .tx_fifo_data_full(tx_fifo_data_full0),
    .tx_fifo_status_full(tx_fifo_status_full0),

	 // to/from parameter decoders
     .received_data(received_data),
     .received_control_param_valid(received_control_param_valid),
     .received_pi_enable_comm_valid(received_pi_enable_cmd_valid),
     .received_pi_reset_comm_valid(received_pi_reset_cmd_valid),
     .wipe_settings(wipe_settings),
     .control_param_written(control_param_written),
     .control_param_ack(control_param_ack),
     .control_param_nak(control_param_nak),
     .control_param_err(control_param_err),
     .pi_enable_comm_ack(pi_enable_cmd_ack),
     .pi_enable_comm_nak(pi_enable_cmd_nak),
     .pi_enable_comm_err(pi_enable_cmd_err),
     .pi_reset_comm_ack(pi_reset_cmd_ack),
     .pi_reset_comm_nak(pi_reset_cmd_nak),
     .pi_reset_comm_err(pi_reset_cmd_err),
	 
	 // Connection status
	 //.conn_timeout_n(...),
	 
    // DACs and ADC status
    .DAC_running(DAC_running),
    .DAC_stopped(DAC_stopped),
    .ADC_ready(ADC_ready)
	 
);
assign led[0] = pi_enable_cmd;
assign led[1] = pi_enable_cmd_ack;
assign led[2] = mac_configured;
assign led[3] = (~mac_configured_125) | wipe_settings;

generic_param_decoder pi_enable_decoder(
	.clk 	             (rx_xcvr_clk),
	.reset             (~mac_configured_125),
	.received_data     (received_data),
	.data_valid        (received_pi_enable_cmd_valid),
	.wipe_settings     (wipe_settings),
	.param             (pi_enable_cmd),
	.ack               (pi_enable_cmd_ack),
	.nak               (pi_enable_cmd_nak),
	.err               (pi_enable_cmd_err)
);
generic_param_decoder pi_reset_decoder(
	.clk 	             (rx_xcvr_clk),
	.reset             (~mac_configured_125),
	.received_data     (received_data),
	.data_valid        (received_pi_reset_cmd_valid),
	.wipe_settings     (wipe_settings),
	.param	          (pi_reset_cmd),
	.ack               (pi_reset_cmd_ack),
	.nak               (pi_reset_cmd_nak),
	.err               (pi_reset_cmd_err)
);

control_param_decoder #(
	.signalBitSize	(16),
	.signalFracSize(15),
	.coeffBitSize	(26),
	.coeffFracSize	(25)
)control_param_decoder (
    .clk(rx_xcvr_clk),
    .reset(!mac_configured_125),    
    .DAC_stopped(DAC_stopped),

    .received_data(received_data),
    .received_control_param_valid(received_control_param_valid),

    .wipe_settings(wipe_settings),

    .control_data(control_data),

    .ack(control_param_ack),
    .nak(control_param_nak),
    .err(control_param_err),

    .pi_kp_coefficient(pi_kp_coefficient),
    .pi_kp_coefficient_update_cmd(pi_kp_coefficient_update_cmd),
    .pi_ti_coefficient(pi_ti_coefficient),
    .pi_ti_coefficient_update_cmd(pi_ti_coefficient_update_cmd),
    .pi_setpoint(pi_setpoint),
    .pi_setpoint_update_cmd(pi_setpoint_update_cmd),
    .pi_limit_HI(pi_limit_HI),
    .pi_limit_LO(pi_limit_LO),

    .control_param_written(control_param_written)
);

//
//reg prevKey;
//always @(posedge(rx_xcvr_clk))begin
//	prevKey <= KEY[0];
//end
//assign pi_rdempty_output_fifo = KEY[0] & !prevKey;
//assign ray_rdempty_fifo = KEY[0] & !prevKey;
//assign pi_rddata_output_fifo = {8'h63,{2{~SW[3:0]}}};
//assign ray_rddata_fifo = {8'h21,{2{SW[7:4]}}};

//
/// DECODER 2 /// used to receive the waveform from the client and to sent the current in FAST mode
wire wfm_written; //1 if the WFM has been written
wire current_rdreq_fifo_dec2; //RDREQ for the current FIFO in fast mode
new_dec_comm8_port2 #(
    .FIFO_LENGTH(16),
    .nOfFifos(7)
)dec_comm8_2(
    .clk                      (rx_xcvr_clk),
    .reset                    (~mac_configured_125),
    .tx_fifo_data             (tx_fifo_data1),
    .tx_fifo_status           (tx_fifo_status1),
    .tx_fifo_data_write       (tx_fifo_data_write1),
    .tx_fifo_status_write     (tx_fifo_status_write1),
    .tx_fifo_data_full        (tx_fifo_data_full1),
    .tx_fifo_status_full      (tx_fifo_status_full1),
    .destination_mac          (client_mac),
    .destination_ip           (client_ip),
	 .rdreq_fifo({zSquare_rdreq_fifo, ySquare_rdreq_fifo, xSquare_rdreq_fifo, z_rdreq_fifo, y_rdreq_fifo, x_rdreq_fifo, pi_rdreq_output_fifo}),
	 .rddata_fifo({zSquare_rddata_fifo, ySquare_rddata_fifo, xSquare_rddata_fifo, z_rddata_fifo, y_rddata_fifo, x_rddata_fifo, pi_rddata_output_fifo}),
	 .rdempty_fifo({zSquare_rdempty_fifo, ySquare_rdempty_fifo, xSquare_rdempty_fifo, z_rdempty_fifo, y_rdempty_fifo, x_rdempty_fifo, pi_rdempty_output_fifo})
);
  
endmodule