`include "rx_wrapper8.v"
`include "tx_wrapper8.v"

module udp_core8 # (
	parameter AVL_SIZE = 8, //in bits
			MAC_SIZE = 48,
			IP_SIZE = 32,
			BYTE_SIZE = 8
	)

(

    input rx_xcvr_clk,
    input rx_sync_rst,

	input tx_xcvr_clk,
	input tx_sync_rst,

    input [MAC_SIZE-1:0] 		local_mac,
    input [IP_SIZE-1:0] 		local_ip,
    input [2*BYTE_SIZE-1:0]     local_stream_1_port,
    input [2*BYTE_SIZE-1:0]     local_stream_2_port,

`ifdef FOUR_TX_PORTS
    input [2*BYTE_SIZE-1:0]     local_stream_3_port,
    input [2*BYTE_SIZE-1:0]     local_stream_4_port,
`endif

    input                   st_rx_startofpacket,
    input                   st_rx_endofpacket,
    input                   st_rx_valid,
    input [AVL_SIZE-1:0]    st_rx_data,
    output                  st_rx_ready,
    input                   st_rx_error,

    output                  st_tx_startofpacket,
    output                  st_tx_endofpacket,
    output                  st_tx_valid,
    output [AVL_SIZE-1:0]   st_tx_data,
    input                   st_tx_ready,
    output                  st_tx_error,

    //rx udp fifo - user side
    //fifo 0
    input rdclk_udp_rxfifo_0,
	
	input rdreq_data_udp_rxfifo_0,
	output [AVL_SIZE-1:0] data_from_udp_rxfifo_0,
	output rdempty_data_udp_rxfifo_0,

	input rdreq_status_udp_rxfifo_0,
	output [2*BYTE_SIZE+MAC_SIZE+IP_SIZE-1:0] status_from_udp_rxfifo_0,
	output rdempty_status_udp_rxfifo_0,
    
    //fifo 1
    input rdclk_udp_rxfifo_1,
	
	input rdreq_data_udp_rxfifo_1,
	output [AVL_SIZE-1:0] data_from_udp_rxfifo_1,
	output rdempty_data_udp_rxfifo_1,

	input rdreq_status_udp_rxfifo_1,
	output [2*BYTE_SIZE+MAC_SIZE+IP_SIZE-1:0] status_from_udp_rxfifo_1,
	output rdempty_status_udp_rxfifo_1,

    //tx udp fifo - user side
    //fifo 0
	input wrclk_udp_txfifo_0,

    input wrreq_data_udp_txfifo_0,
    input [AVL_SIZE-1:0] data_to_udp_txfifo_0,
    output wrfull_data_udp_txfifo_0,
    output [12:0] wrusedw_data_udp_txfifo_0, 
 
    input wrreq_status_udp_txfifo_0,
	input [2*BYTE_SIZE+MAC_SIZE+IP_SIZE-1:0] status_to_udp_txfifo_0,
    output wrfull_status_udp_txfifo_0,
    output [7:0] wrusedw_status_udp_txfifo_0,

    //fifo 1
	input wrclk_udp_txfifo_1,

    input wrreq_data_udp_txfifo_1,
    input [AVL_SIZE-1:0] data_to_udp_txfifo_1,
    output wrfull_data_udp_txfifo_1,
    output [12:0] wrusedw_data_udp_txfifo_1,

    input wrreq_status_udp_txfifo_1,
	input [2*BYTE_SIZE+MAC_SIZE+IP_SIZE-1:0] status_to_udp_txfifo_1,
    output wrfull_status_udp_txfifo_1,
    output [7:0] wrusedw_status_udp_txfifo_1

`ifdef FOUR_TX_PORTS
    ,
	input wrclk_udp_txfifo_2,

    input wrreq_data_udp_txfifo_2,
    input [AVL_SIZE-1:0] data_to_udp_txfifo_2,
    output wrfull_data_udp_txfifo_2,
    output [12:0] wrusedw_data_udp_txfifo_2, 
 
    input wrreq_status_udp_txfifo_2,
	input [2*BYTE_SIZE+MAC_SIZE+IP_SIZE-1:0] status_to_udp_txfifo_2,
    output wrfull_status_udp_txfifo_2,
    output [7:0] wrusedw_status_udp_txfifo_2,

    //fifo 1
	input wrclk_udp_txfifo_3,

    input wrreq_data_udp_txfifo_3,
    input [AVL_SIZE-1:0] data_to_udp_txfifo_3,
    output wrfull_data_udp_txfifo_3,
    output [12:0] wrusedw_data_udp_txfifo_3,

    input wrreq_status_udp_txfifo_3,
	input [2*BYTE_SIZE+MAC_SIZE+IP_SIZE-1:0] status_to_udp_txfifo_3,
    output wrfull_status_udp_txfifo_3,
    output [7:0] wrusedw_status_udp_txfifo_3

`endif

);


wire [2*BYTE_SIZE+IP_SIZE+MAC_SIZE-1:0] arp_from_tx;
wire arp_from_rx_valid;

wire [2*BYTE_SIZE+IP_SIZE+MAC_SIZE-1:0] icmp_from_tx;
wire icmp_from_rx_valid;
wire [2*BYTE_SIZE-1:0] icmp_checksum;

wire icmp_fifo_run;
wire icmp_clear_fifo;

wire tx_busy;

rx_wrapper8 rx_wrapper8_0 (

    .rx_xcvr_clk(rx_xcvr_clk),
    .rx_sync_rst(rx_sync_rst),

    .local_mac(local_mac),
    .local_ip(local_ip),
    .local_stream_1_port(local_stream_1_port),
    .local_stream_2_port(local_stream_2_port),

    .st_rx_startofpacket(st_rx_startofpacket),
    .st_rx_endofpacket(st_rx_endofpacket),
    .st_rx_data(st_rx_data),
    .st_rx_valid(st_rx_valid),
    .st_rx_ready(st_rx_ready),
	.st_rx_error(st_rx_error),

    .arp_to_tx(arp_from_tx),
    .arp_to_tx_valid(arp_from_rx_valid),

    .icmp_to_tx(icmp_from_tx),
    .icmp_to_tx_valid(icmp_from_rx_valid),
    .icmp_fifo_run(icmp_fifo_run),
    .icmp_clear_fifo(icmp_clear_fifo),
    .icmp_checksum(icmp_checksum),

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

    .tx_busy(tx_busy)

);

wire icmp_fifo_empty;
wire icmp_fifo_rdreq;
wire [AVL_SIZE-1:0] icmp_fifo_data;
wire [10:0] icmp_fifo_rdusedw;


tx_wrapper8 tx_wrapper8_0 (

    .tx_xcvr_clk(tx_xcvr_clk),
    .tx_sync_rst(tx_sync_rst),

    .local_mac(local_mac),
    .local_ip(local_ip),
    .local_stream_1_port(local_stream_1_port),
    .local_stream_2_port(local_stream_2_port),
`ifdef FOUR_TX_PORTS
    .local_stream_3_port(local_stream_3_port),
    .local_stream_4_port(local_stream_4_port),
`endif
    .st_tx_startofpacket(st_tx_startofpacket),
    .st_tx_endofpacket(st_tx_endofpacket),
    .st_tx_data(st_tx_data),
    .st_tx_valid(st_tx_valid),
    .st_tx_ready(st_tx_ready),
	.st_tx_error(st_tx_error),

    .arp_from_rx(arp_from_tx),
    .arp_from_rx_valid(arp_from_rx_valid),

    .icmp_from_rx(icmp_from_tx),
    .icmp_from_rx_valid(icmp_from_rx_valid),
    .icmp_checksum(icmp_checksum),

    .icmp_fifo_rdreq(icmp_fifo_rdreq),
    .icmp_fifo_data(icmp_fifo_data),
    .icmp_fifo_empty(icmp_fifo_empty),
    .icmp_fifo_rdusedw(icmp_fifo_rdusedw),

    .tx_busy(tx_busy),

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



icmp_fifo8 icmp_fifo8_0 (
    .aclr    (icmp_clear_fifo),    //   input,   width = 1,            .aclr

    .wrclk   (rx_xcvr_clk),   //   input,   width = 1,            .wrclk
    .wrreq   (icmp_fifo_run),   //   input,   width = 1,            .wrreq
    .wrfull  (),   //  output,   width = 1,            .wrfull
    .data    (st_rx_data),    //   input,  width = 8,  fifo_input.datain

    .rdclk   (tx_xcvr_clk),   //   input,   width = 1,            .rdclk
    .rdreq   (icmp_fifo_rdreq),   //   input,   width = 1,            .rdreq
    .q       (icmp_fifo_data),       //  output,  width = 8, fifo_output.dataout
    .rdusedw (icmp_fifo_rdusedw), //  output,  width = 11,            .rdusedw
    .rdempty (icmp_fifo_empty) //  output,   width = 1,            .rdempty
);


endmodule



