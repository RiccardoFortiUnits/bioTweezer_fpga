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
    PORT_3 = 2049,
    PORT_4 = 2050
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
    
    //MODE selection
    output  mode_nCont_disc,
    output  mode_nRaw_dem,

    //parameters
    output [31:0]   frequency_initial,
    output [31:0]   frequency_final,
    output [63:0]   frequency_step,
    output [31:0]   step_counter,
    output [15:0]   wfm_amplitude,
    output [2:0]   gain,    
    output [15:0]   dem_delay,

    //fifo parameters
    input           fifo_rd_clk,
    input           fifo_rd_ack,
    output [195:0]  fifo_rd_data,
    output          fifo_rd_empty,

    //acq mode commands
    output  start_fifo_cmd,
    output  start_dac_cmd,
    output  stop_dac_cmd,

    // DACs and ADC status
    input  DAC_running,
    input  ADC_ready,

    // acq FIFO
	output acq_rdreq_fifo_108,
	input [107:0] acq_rddata_fifo_108,
	input acq_rdempty_fifo_108
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

wire [7:0]	         tx_fifo_data2;
wire		         tx_fifo_data_write2;
wire		         tx_fifo_data_full2;
wire [95:0]	         tx_fifo_status2;
wire		         tx_fifo_status_write2;
wire		         tx_fifo_status_full2;

wire [7:0]	         tx_fifo_data3;
wire		         tx_fifo_data_write3;
wire		         tx_fifo_data_full3;
wire [95:0]	         tx_fifo_status3;
wire		         tx_fifo_status_write3;
wire		         tx_fifo_status_full3;

eth_1gb_wrapper eth_1gb_wrapper_0 (

    .csr_clk(clock_100),          //100 MHz clock for configuration
    .ref_clk(ref_clk_125),        //125 MHz reference clock

    .reset(reset),
    .start_mac_trc_config(start_mac_trc_config),

    .MAC_BOARD(MAC_BOARD_1),
    .IP_BOARD(IP_BOARD_1),
    .PORT_1(PORT_1),
    .PORT_2(PORT_2),
    .PORT_3(PORT_3),
    .PORT_4(PORT_4),    

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

    .wrclk_udp_txfifo_2(rx_xcvr_clk),
    .wrreq_data_udp_txfifo_2(tx_fifo_data_write2),
    .data_to_udp_txfifo_2(tx_fifo_data2),
    .wrfull_data_udp_txfifo_2(tx_fifo_data_full2),
    .wrusedw_data_udp_txfifo_2(),
    .wrreq_status_udp_txfifo_2(tx_fifo_status_write2),
	.status_to_udp_txfifo_2(tx_fifo_status2),
    .wrfull_status_udp_txfifo_2(tx_fifo_status_full2),
    .wrusedw_status_udp_txfifo_2(),

    .wrclk_udp_txfifo_3(rx_xcvr_clk),
    .wrreq_data_udp_txfifo_3(tx_fifo_data_write3),
    .data_to_udp_txfifo_3(tx_fifo_data3),
    .wrfull_data_udp_txfifo_3(tx_fifo_data_full3),
    .wrusedw_data_udp_txfifo_3(),
    .wrreq_status_udp_txfifo_3(tx_fifo_status_write3),
	.status_to_udp_txfifo_3(tx_fifo_status3),
    .wrfull_status_udp_txfifo_3(tx_fifo_status_full3),
    .wrusedw_status_udp_txfifo_3(),
    
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

dec_comm8_port1 dec_comm8_1 
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

    .mode_nCont_disc(mode_nCont_disc),
    .mode_nRaw_dem(mode_nRaw_dem),

    .frequency_initial(frequency_initial),
    .frequency_final(frequency_final),
    .frequency_step(frequency_step),
    .step_counter(step_counter),
    .wfm_amplitude(wfm_amplitude),
    .gain(gain),
    .dem_delay(dem_delay),

    //fifo parameters
    .fifo_rd_clk(fifo_rd_clk),
    .fifo_rd_ack(fifo_rd_ack),
    .fifo_rd_data(fifo_rd_data),
    .fifo_rd_empty(fifo_rd_empty),

    .start_fifo_cmd(start_fifo_cmd),
    .start_dac_cmd(start_dac_cmd),
    .stop_dac_cmd(stop_dac_cmd),
    // DACs and ADC status
    .DAC_running(DAC_running),
    .ADC_ready(ADC_ready)
);


/// DECODER 2 /// used to receive the waveform from the client and to sent the current in FAST mode
wire wfm_written; //1 if the WFM has been written
wire current_rdreq_fifo_dec2; //RDREQ for the current FIFO in fast mode
dec_comm8_port2 dec_comm8_2 
(
    .clk(rx_xcvr_clk),
    .reset(~mac_configured_125),

    .source_mac(client_mac),
    .source_ip(client_ip),

    // rx fifo interface from 1gb eth
    .rx_fifo_data(rx_fifo_data1),
    .rx_fifo_data_read(rx_fifo_data_read1),
    .rx_fifo_status(rx_fifo_status1),
    .rx_fifo_status_empty(rx_fifo_status_empty1),
    .rx_fifo_status_read(rx_fifo_status_read1),

    // tx fifo interface to 1gb eth (for ack)
    .tx_fifo_data(tx_fifo_data1),
    .tx_fifo_status(tx_fifo_status1),
    .tx_fifo_data_write(tx_fifo_data_write1),
    .tx_fifo_status_write(tx_fifo_status_write1),
    .tx_fifo_data_full(tx_fifo_data_full1),
    .tx_fifo_status_full(tx_fifo_status_full1),

    .destination_mac(client_mac),
    .destination_ip(client_ip),

    .mode_nCont_disc(mode_nCont_disc),
    .mode_nRaw_dem(mode_nRaw_dem),

    .acq_rdreq_fifo_108(acq_rdreq_fifo_108),
	.acq_rddata_fifo_108(acq_rddata_fifo_108),
	.acq_rdempty_fifo_108(acq_rdempty_fifo_108)  
);
    
endmodule