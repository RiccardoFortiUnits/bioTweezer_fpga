`include "rx_manager8.v"
`include "decoders/frame_decode8.v"
`include "decoders/arp_decode8.v"
`include "decoders/ip_decode_pri8.v"
`include "decoders/ip_decode_sec8.v"
`include "decoders/icmp_decode8.v"
`include "decoders/udp_decode8.v"
`include "decoders/udp_delayer8.v"

module rx_wrapper8 # (
    	parameter AVL_SIZE = 8, //in bits
			MAC_SIZE = 48,
			IP_SIZE = 32,
			BYTE_SIZE = 8)

(
    input rx_xcvr_clk,
    input rx_sync_rst,

    input [MAC_SIZE-1:0] 		local_mac,
    input [IP_SIZE-1:0] 		local_ip,
    input [2*BYTE_SIZE-1:0]     local_stream_1_port,
    input [2*BYTE_SIZE-1:0]     local_stream_2_port,

    input                   st_rx_startofpacket,
    input                   st_rx_endofpacket,
    input                   st_rx_valid,
    input [AVL_SIZE-1:0]    st_rx_data,
    output                  st_rx_ready,
    input                   st_rx_error,

	output [2*BYTE_SIZE+IP_SIZE+MAC_SIZE-1:0] arp_to_tx,
	output arp_to_tx_valid,

	output [2*BYTE_SIZE+IP_SIZE+MAC_SIZE-1:0] icmp_to_tx,
	output icmp_to_tx_valid,
	output [2*BYTE_SIZE-1:0] icmp_checksum,

	output icmp_fifo_run,
	output icmp_clear_fifo,

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

	input tx_busy



);

reg tx_busy1, tx_busy2;

always @(posedge rx_xcvr_clk)
begin
	tx_busy1 <= tx_busy;
	tx_busy2 <= tx_busy1;
end


wire reset_decoders;

wire [AVL_SIZE-1:0] data_to_decoders;

assign data_to_decoders = st_rx_data;

wire                    decode_frame_run;
wire [MAC_SIZE-1:0]     decode_frame_src_mac;
wire [MAC_SIZE-1:0]     decode_frame_dst_mac;
wire [2*BYTE_SIZE-1:0]  decode_frame_packet_type;


wire                    decode_arp_run;
wire [2*BYTE_SIZE-1:0]	decode_arp_operation;
wire [IP_SIZE-1:0]      decode_arp_src_ip;
wire [IP_SIZE-1:0]      decode_arp_dst_ip;
wire                    decode_arp_valid;

wire                    decode_ip_pri_run;
wire [2*BYTE_SIZE-1:0]  decode_ip_packet_length;
wire [BYTE_SIZE-1:0]    decode_ip_protocol;
wire [BYTE_SIZE/2-1:0]	            decode_ip_offset_count;
wire [BYTE_SIZE/2-1:0]			decode_ip_header_length;
wire 		            decode_ip_valid;


wire                decode_ip_sec_run;
wire [IP_SIZE-1:0]  decode_ip_src_ip;
wire [IP_SIZE-1:0]  decode_ip_dst_ip;


wire                    decode_icmp_run;
wire [BYTE_SIZE-1:0]    decode_icmp_type;
wire [BYTE_SIZE-1:0]    decode_icmp_code;
wire [2*BYTE_SIZE-1:0]  decode_icmp_checksum;


wire                    decode_udp_run;
wire [2*BYTE_SIZE-1:0]  decode_udp_dst_port;
wire [2*BYTE_SIZE-1:0]  decode_udp_src_port;
wire [2*BYTE_SIZE-1:0]  decode_udp_packet_length;


wire				reset_aligner;
wire				udp_aligner_run;

wire [2*BYTE_SIZE+IP_SIZE+MAC_SIZE-1:0] data_udp_status_fifo;
wire  dvalid_udp_status_fifo;

wire select_udp_port;
wire disable_data_fifo;

rx_manager8 rx_manager8_0 (

    .rx_xcvr_clk(rx_xcvr_clk),
    .rx_sync_rst(rx_sync_rst),

    .local_mac(local_mac),
    .local_ip(local_ip),
    .local_stream_1_port(local_stream_1_port),
    .local_stream_2_port(local_stream_2_port),


    .st_rx_startofpacket(st_rx_startofpacket),
    .st_rx_endofpacket(st_rx_endofpacket),
    .st_rx_valid(st_rx_valid),
    .st_rx_ready(st_rx_ready),
    .st_rx_error(st_rx_error),


	//-----DECODER SECTION
	
	.reset_decoders(reset_decoders),

	//frame decoder
	.decode_frame_run(decode_frame_run),
	.decode_frame_src_mac(decode_frame_src_mac),
	.decode_frame_dst_mac(decode_frame_dst_mac),
	.decode_frame_packet_type(decode_frame_packet_type),
	
	//arp decoder
	.decode_arp_run(decode_arp_run),
	.decode_arp_valid(decode_arp_valid),
	.decode_arp_src_ip(decode_arp_src_ip),
	.decode_arp_dst_ip(decode_arp_dst_ip),
	.decode_arp_operation(decode_arp_operation),
	
	//ip decoder
	.decode_ip_pri_run(decode_ip_pri_run),
	.decode_ip_valid(decode_ip_valid),
	.decode_ip_offset_count(decode_ip_offset_count),
	.decode_ip_protocol(decode_ip_protocol),
	.decode_ip_packet_length(decode_ip_packet_length),
	.decode_ip_header_length(decode_ip_header_length),
	
	.decode_ip_sec_run(decode_ip_sec_run),
	.decode_ip_src_ip(decode_ip_src_ip),
	.decode_ip_dst_ip(decode_ip_dst_ip),
	
	//icmp decoder
	.decode_icmp_run(decode_icmp_run),
	.decode_icmp_type(decode_icmp_type),
	.decode_icmp_code(decode_icmp_code),
	.decode_icmp_checksum(decode_icmp_checksum),

	//udp decoder
	.decode_udp_run(decode_udp_run),
	.decode_udp_src_port(decode_udp_src_port),
	.decode_udp_dst_port(decode_udp_dst_port),
	.decode_udp_packet_length(decode_udp_packet_length),

	.arp_to_tx(arp_to_tx),
	.arp_to_tx_valid(arp_to_tx_valid),

	.icmp_to_tx(icmp_to_tx),
	.icmp_to_tx_valid(icmp_to_tx_valid),
	.icmp_checksum(icmp_checksum),

	.icmp_fifo_run(icmp_fifo_run),
	.icmp_clear_fifo(icmp_clear_fifo),

    .reset_aligner(reset_aligner),
    .udp_aligner_run(udp_aligner_run),

	.data_udp_status_fifo(data_udp_status_fifo),
	.dvalid_udp_status_fifo(dvalid_udp_status_fifo),

	.select_udp_port(select_udp_port),
	.disable_data_fifo(disable_data_fifo),
	.tx_busy(tx_busy2)


);


frame_decode8 frame_decode8_0(

	.clk(rx_xcvr_clk),
	.sync_reset(reset_decoders),
	
	.data_in(data_to_decoders),
	.data_in_valid(decode_frame_run),
	
	.source_mac(decode_frame_src_mac),
	.dest_mac(decode_frame_dst_mac),
	.packet_type(decode_frame_packet_type)

);


arp_decode8 arp_decode8_0 (

	.clk(rx_xcvr_clk),
	.sync_reset(reset_decoders),
	
	.data_in(data_to_decoders),
	.data_in_valid(decode_arp_run),
	
	.hardware_type(),
	.protocol_type(),
	.hardware_len(),
	.protocol_len(),
	.operation(decode_arp_operation),
	.sender_hardware_address(),
	.sender_protocol_address(decode_arp_src_ip),
	.target_hardware_address(),
	.target_protocol_address(decode_arp_dst_ip),
	
	.decode_valid(decode_arp_valid)

	);


ip_decode_pri8 ip_decode_pri8_0(

	.clk(rx_xcvr_clk),
	.sync_reset(reset_decoders),
	
	.data_in(data_to_decoders),
	.data_in_valid(decode_ip_pri_run),

	.headerLength(decode_ip_header_length),
	.headerVersion(),
	.dscp(),
	.totalLength(decode_ip_packet_length),
	.idCode(),
	.flags(),
	.fragmentOffset(),
	.timeToLive(),
	.protocol(decode_ip_protocol),
	.checkSum(),
	.offset_count(decode_ip_offset_count),
	
	.ip_header_valid(decode_ip_valid)

);


ip_decode_sec8 ip_decode_sec8_0(

	.clk(rx_xcvr_clk),
	.sync_reset(reset_decoders),
	
	.data_in(data_to_decoders),
	.data_in_valid(decode_ip_sec_run),

	.src_ip(decode_ip_src_ip),
	.dst_ip(decode_ip_dst_ip)
);


icmp_decode8 icmp_decode8_0(

	.clk(rx_xcvr_clk),
	.sync_reset(reset_decoders),
	
	.data_in(data_to_decoders),
	.data_in_valid(decode_icmp_run),
	
	.icmp_type(decode_icmp_type),
	.code(decode_icmp_code),
	.checksum(decode_icmp_checksum)

);


udp_decode8 udp_decode8_0(

	.clk(rx_xcvr_clk),
	.sync_reset(reset_decoders),
	
	.data_in(data_to_decoders),
	.data_in_valid(decode_udp_run),

	.src_port(decode_udp_src_port),
	.dst_port(decode_udp_dst_port),
	.checksum(),
	.length(decode_udp_packet_length)

);

wire [AVL_SIZE-1:0] data_to_udp_fifo;
wire dvalid_udp_fifo;

udp_delayer8 udp_delayer8_0(

	.clk(rx_xcvr_clk),
	.sync_reset(reset_aligner),
	
	.dvalid_in(udp_aligner_run),
 	.data_in(data_to_decoders),

    .dvalid_out(dvalid_udp_fifo),
	.data_out(data_to_udp_fifo)

);


wire dvalid_udp_fifo_0;
wire [AVL_SIZE-1:0] data_to_udp_fifo_0;

assign dvalid_udp_fifo_0 = ((select_udp_port) ? 1'b0 : dvalid_udp_fifo) & !disable_data_fifo;
assign data_to_udp_fifo_0 = (select_udp_port) ? {{AVL_SIZE}{1'b0}} : data_to_udp_fifo;

wire dvalid_udp_status_fifo_0;
wire [2*BYTE_SIZE+IP_SIZE+MAC_SIZE-1:0] data_udp_status_fifo_0;

assign dvalid_udp_status_fifo_0 = (select_udp_port) ? 1'b0 : dvalid_udp_status_fifo;
assign data_udp_status_fifo_0 = (select_udp_port) ? {{2*BYTE_SIZE+IP_SIZE+MAC_SIZE}{1'b0}} : data_udp_status_fifo;

udp_fifo8 udp_rx_fifo8_0 (
	.aclr    (rx_sync_rst),    //   input,   width = 1,            .aclr
	
	.wrclk   (rx_xcvr_clk),   //   input,   width = 1,            .wrclk
	.wrreq   (dvalid_udp_fifo_0),   //   input,   width = 1,            .wrreq
	.wrfull  (),   //  output,   width = 1,            .wrfull
	.data    (data_to_udp_fifo_0),    //   input,  width = 8,  fifo_input.datain
	
	.rdclk   (rdclk_udp_rxfifo_0),   //   input,   width = 1,            .rdclk
	.rdreq   (rdreq_data_udp_rxfifo_0),   //   input,   width = 1,            .rdreq
	.q       (data_from_udp_rxfifo_0),       //  output,  width = 8, fifo_output.dataout
	.rdempty (rdempty_data_udp_rxfifo_0) //  output,   width = 1,            .rdempty
);

udp_fifo_status8 udp_rx_fifo_status8_0 (
	.aclr    (rx_sync_rst),    //   input,   width = 1,            .aclr

	.wrclk   (rx_xcvr_clk),   //   input,   width = 1,            .wrclk
	.data    (data_udp_status_fifo_0),    //   input,  width = 96,  fifo_input.datain
	.wrreq   (dvalid_udp_status_fifo_0),   //   input,   width = 1,            .wrreq
	.wrfull  (),   //  output,   width = 1,            .wrfull

	.rdclk   (rdclk_udp_rxfifo_0),   //   input,   width = 1,            .rdclk
	.rdreq   (rdreq_status_udp_rxfifo_0),   //   input,   width = 1,            .rdreq
	.q       (status_from_udp_rxfifo_0),       //  output,  width = 96, fifo_output.dataout
	.rdempty (rdempty_status_udp_rxfifo_0) //  output,   width = 1,            .rdempty
);

wire dvalid_udp_fifo_1;
wire [AVL_SIZE-1:0] data_to_udp_fifo_1;

assign dvalid_udp_fifo_1 = ((select_udp_port) ? dvalid_udp_fifo : 1'b0) & !disable_data_fifo;
assign data_to_udp_fifo_1 = (select_udp_port) ? data_to_udp_fifo : {{AVL_SIZE}{1'b0}};

wire dvalid_udp_status_fifo_1;
wire [2*BYTE_SIZE+IP_SIZE+MAC_SIZE-1:0] data_udp_status_fifo_1;

assign dvalid_udp_status_fifo_1 = (select_udp_port) ? dvalid_udp_status_fifo : 1'b0;
assign data_udp_status_fifo_1 = (select_udp_port) ? data_udp_status_fifo : {{2*BYTE_SIZE+IP_SIZE+MAC_SIZE}{1'b0}};

udp_fifo8 udp_rx_fifo8_1 (
	.aclr    (rx_sync_rst),    //   input,   width = 1,            .aclr
	
	.wrclk   (rx_xcvr_clk),   //   input,   width = 1,            .wrclk
	.wrreq   (dvalid_udp_fifo_1),   //   input,   width = 1,            .wrreq
	.wrfull  (),   //  output,   width = 1,            .wrfull
	.data    (data_to_udp_fifo_1),    //   input,  width = 8,  fifo_input.datain
	
	.rdclk   (rdclk_udp_rxfifo_1),   //   input,   width = 1,            .rdclk
	.rdreq   (rdreq_data_udp_rxfifo_1),   //   input,   width = 1,            .rdreq
	.q       (data_from_udp_rxfifo_1),       //  output,  width = 8, fifo_output.dataout
	.rdempty (rdempty_data_udp_rxfifo_1) //  output,   width = 1,            .rdempty
);

udp_fifo_status8 udp_rx_fifo_status8_1 (
	.aclr    (rx_sync_rst),    //   input,   width = 1,            .aclr

	.wrclk   (rx_xcvr_clk),   //   input,   width = 1,            .wrclk
	.data    (data_udp_status_fifo_1),    //   input,  width = 96,  fifo_input.datain
	.wrreq   (dvalid_udp_status_fifo_1),   //   input,   width = 1,            .wrreq
	.wrfull  (),   //  output,   width = 1,            .wrfull

	.rdclk   (rdclk_udp_rxfifo_1),   //   input,   width = 1,            .rdclk
	.rdreq   (rdreq_status_udp_rxfifo_1),   //   input,   width = 1,            .rdreq
	.q       (status_from_udp_rxfifo_1),       //  output,  width = 96, fifo_output.dataout
	.rdempty (rdempty_status_udp_rxfifo_1) //  output,   width = 1,            .rdempty
);

endmodule


