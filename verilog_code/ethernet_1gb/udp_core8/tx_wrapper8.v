`include "tx_manager8.v"
`include "encoders/frame_encode8.v"
`include "encoders/arp_encode8.v"
`include "encoders/ip_encode8.v"
`include "encoders/icmp_encode8.v"
`include "encoders/udp_encode8.v"


module tx_wrapper8 # (
    	parameter AVL_SIZE = 8, //in bits
			MAC_SIZE = 48,
			IP_SIZE = 32,
			BYTE_SIZE = 8)

(
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

    output                   st_tx_startofpacket,
    output                   st_tx_endofpacket,
    output                   st_tx_valid,
    output [AVL_SIZE-1:0]    st_tx_data,
    input                  st_tx_ready,
    output                   st_tx_error,

	input [2*BYTE_SIZE+IP_SIZE+MAC_SIZE-1:0] arp_from_rx,
	input arp_from_rx_valid,

	input [2*BYTE_SIZE+IP_SIZE+MAC_SIZE-1:0] icmp_from_rx,
	input icmp_from_rx_valid,

	output icmp_fifo_rdreq,
    input [AVL_SIZE-1:0] icmp_fifo_data,
    input icmp_fifo_empty,
	input [10:0] icmp_fifo_rdusedw,
	input [2*BYTE_SIZE-1:0] icmp_checksum,

	output tx_busy,

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

reg arp_from_rx_valid_1;
reg arp_from_rx_valid_2;
reg arp_from_rx_valid_3;
reg edge_arp_from_rx;

//synchronization of CDC
always @ (posedge tx_xcvr_clk)
begin
	arp_from_rx_valid_1 <= arp_from_rx_valid;
	arp_from_rx_valid_2 <= arp_from_rx_valid_1;
	arp_from_rx_valid_3 <= arp_from_rx_valid_2;

	if( (arp_from_rx_valid_3 == 0) && (arp_from_rx_valid_2 == 1) )
		edge_arp_from_rx <= 1'b1;
	else
		edge_arp_from_rx <= 1'b0;

end

reg icmp_from_rx_valid_1;
reg icmp_from_rx_valid_2;
reg icmp_from_rx_valid_3;
reg edge_icmp_from_rx;

always @ (posedge tx_xcvr_clk)
begin
	icmp_from_rx_valid_1 <= icmp_from_rx_valid;
	icmp_from_rx_valid_2 <= icmp_from_rx_valid_1;
	icmp_from_rx_valid_3 <= icmp_from_rx_valid_2;

	if( (icmp_from_rx_valid_3 == 0) && (icmp_from_rx_valid_2 == 1) )
		edge_icmp_from_rx <= 1'b1;
	else
		edge_icmp_from_rx <= 1'b0;

end


wire		reset_encoders;
wire		encode_run;

wire [AVL_SIZE-1:0]     data_from_frame;
wire [AVL_SIZE-1:0]	    data_to_frame;
wire [MAC_SIZE-1:0]	    encode_frame_dst_mac;
wire [MAC_SIZE-1:0]	    encode_frame_src_mac;
wire [2*BYTE_SIZE-1:0]	encode_frame_packet_type;

wire [AVL_SIZE-1:0]	    data_from_arp;
wire [MAC_SIZE-1:0]	    encode_arp_src_mac;
wire [IP_SIZE-1:0]	    encode_arp_src_ip;
wire [MAC_SIZE-1:0]	    encode_arp_dst_mac;
wire [IP_SIZE-1:0]	    encode_arp_dst_ip;

wire [AVL_SIZE-1:0]	    data_from_ip;
wire [AVL_SIZE-1:0]	    data_to_ip;
wire [2*BYTE_SIZE-1:0]  encode_ip_packet_length;
wire [BYTE_SIZE-1:0]	encode_ip_protocol;
wire [IP_SIZE-1:0]	    encode_ip_dst_ip;
wire [IP_SIZE-1:0]      encode_ip_src_ip;	

wire [AVL_SIZE-1:0]	    data_from_icmp;
wire [AVL_SIZE-1:0]	    data_to_icmp;
wire [BYTE_SIZE-1:0]	encode_icmp_type;
wire [BYTE_SIZE-1:0]	encode_icmp_code;
wire [2*BYTE_SIZE-1:0]	encode_icmp_checksum;

wire [AVL_SIZE-1:0]	    data_from_udp;
wire [AVL_SIZE-1:0]	    data_to_udp;
wire [2*BYTE_SIZE-1:0]	encode_udp_dst_port_0;
wire [2*BYTE_SIZE-1:0]	encode_udp_src_port_0;
wire [2*BYTE_SIZE-1:0]	encode_udp_packet_length;

wire [2*BYTE_SIZE-1:0]	encode_udp_dst_port_1;
wire [2*BYTE_SIZE-1:0]	encode_udp_src_port_1;

`ifdef FOUR_TX_PORTS
wire [2*BYTE_SIZE-1:0]	encode_udp_dst_port_2;
wire [2*BYTE_SIZE-1:0]	encode_udp_src_port_2;
wire [2*BYTE_SIZE-1:0]	encode_udp_dst_port_3;
wire [2*BYTE_SIZE-1:0]	encode_udp_src_port_3;
`endif 

wire encode_arp_n_ip;
wire encode_udp_n_icmp; 

assign data_to_frame = (encode_arp_n_ip == 1'b1) ? data_from_arp : data_from_ip; 

assign data_to_ip = (encode_udp_n_icmp == 1'b1) ? data_from_udp : data_from_icmp; 


assign st_tx_data = data_from_frame;

reg rdempty_data_udp_fifo;
wire rdreq_data_udp_fifo;

`ifdef FOUR_TX_PORTS
wire [1:0] sel_tx_fifo;
`else
wire sel_tx_fifo;
`endif 

wire rdempty_status_udp_fifo_0;
wire rdreq_status_udp_fifo_0;
wire [2*BYTE_SIZE+MAC_SIZE+IP_SIZE-1:0] status_from_udp_fifo_0;

wire rdempty_status_udp_fifo_1;
wire rdreq_status_udp_fifo_1;
wire [2*BYTE_SIZE+MAC_SIZE+IP_SIZE-1:0] status_from_udp_fifo_1;

`ifdef FOUR_TX_PORTS
wire rdempty_status_udp_fifo_2;
wire rdreq_status_udp_fifo_2;
wire [2*BYTE_SIZE+MAC_SIZE+IP_SIZE-1:0] status_from_udp_fifo_2;

wire rdempty_status_udp_fifo_3;
wire rdreq_status_udp_fifo_3;
wire [2*BYTE_SIZE+MAC_SIZE+IP_SIZE-1:0] status_from_udp_fifo_3;
`endif 


tx_manager8 tx_manager8_0 (


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
    .st_tx_valid(st_tx_valid),
    .st_tx_ready(st_tx_ready),
    .st_tx_error(st_tx_error),

    .reset_encoders(reset_encoders),
    .encode_run(encode_run),
    .encode_arp_n_ip(encode_arp_n_ip),
    .encode_udp_n_icmp(encode_udp_n_icmp),

    //frame encoder
	.encode_frame_src_mac(encode_frame_src_mac),
	.encode_frame_dst_mac(encode_frame_dst_mac),
	.encode_frame_packet_type(encode_frame_packet_type),
	
	//arp encoder
	.encode_arp_src_mac(encode_arp_src_mac),
	.encode_arp_dst_mac(encode_arp_dst_mac),
	.encode_arp_src_ip(encode_arp_src_ip),
	.encode_arp_dst_ip(encode_arp_dst_ip),
	
	//ip encoder
	.encode_ip_protocol(encode_ip_protocol),
	.encode_ip_src_ip(encode_ip_src_ip),
	.encode_ip_dst_ip(encode_ip_dst_ip),
	.encode_ip_packet_length(encode_ip_packet_length),
	
	//icmp encoder
	.encode_icmp_code(encode_icmp_code),
	.encode_icmp_type(encode_icmp_type),
	.encode_icmp_checksum(encode_icmp_checksum),
	
	//udp encoder
	.encode_udp_src_port_0(encode_udp_src_port_0),
	.encode_udp_dst_port_0(encode_udp_dst_port_0),

	.encode_udp_src_port_1(encode_udp_src_port_1),
	.encode_udp_dst_port_1(encode_udp_dst_port_1),

`ifdef FOUR_TX_PORTS
	.encode_udp_src_port_2(encode_udp_src_port_2),
	.encode_udp_dst_port_2(encode_udp_dst_port_2),
	.encode_udp_src_port_3(encode_udp_src_port_3),
	.encode_udp_dst_port_3(encode_udp_dst_port_3),
`endif

	.encode_udp_packet_length(encode_udp_packet_length),

	.arp_from_rx(arp_from_rx),
	.arp_from_rx_valid(edge_arp_from_rx),

	.icmp_from_rx(icmp_from_rx),
	.icmp_from_rx_valid(edge_icmp_from_rx),
	.icmp_checksum(icmp_checksum),

	.icmp_fifo_rdreq(icmp_fifo_rdreq),
    .icmp_fifo_empty(icmp_fifo_empty),
	.icmp_fifo_rdusedw(icmp_fifo_rdusedw),

	.tx_busy(tx_busy),

	.rdempty_data_udp_fifo(rdempty_data_udp_fifo),
	.rdreq_data_udp_fifo(rdreq_data_udp_fifo),

	.sel_tx_fifo(sel_tx_fifo),

	.rdempty_status_udp_fifo_0(rdempty_status_udp_fifo_0),
	.rdreq_status_udp_fifo_0(rdreq_status_udp_fifo_0),
	.status_from_udp_fifo_0(status_from_udp_fifo_0),

	.rdempty_status_udp_fifo_1(rdempty_status_udp_fifo_1),
	.rdreq_status_udp_fifo_1(rdreq_status_udp_fifo_1),
	.status_from_udp_fifo_1(status_from_udp_fifo_1)

`ifdef FOUR_TX_PORTS
	,
	.rdempty_status_udp_fifo_2(rdempty_status_udp_fifo_2),
	.rdreq_status_udp_fifo_2(rdreq_status_udp_fifo_2),
	.status_from_udp_fifo_2(status_from_udp_fifo_2),

	.rdempty_status_udp_fifo_3(rdempty_status_udp_fifo_3),
	.rdreq_status_udp_fifo_3(rdreq_status_udp_fifo_3),
	.status_from_udp_fifo_3(status_from_udp_fifo_3)
`endif

);




frame_encode8 frame_encode8_0(
	.clk(tx_xcvr_clk),
	.sync_reset(reset_encoders),
	
	.run(encode_run),
	.data_in(data_to_frame),
	.data_out(data_from_frame),
	
	.source_mac(encode_frame_src_mac),
	.dest_mac(encode_frame_dst_mac),
	.packet_type(encode_frame_packet_type)
);




arp_encode8 arp_encode8_0 (
	.clk(tx_xcvr_clk),
	.sync_reset(reset_encoders),
	
	.run(encode_run),
	
	.data_in(8'd0),		//no input data/carry for arp encoder

	.data_out(data_from_arp),
	
	.sender_hardware_address(encode_arp_src_mac),
	.sender_protocol_address(encode_arp_src_ip),
	.target_hardware_address(encode_arp_dst_mac),
	.target_protocol_address(encode_arp_dst_ip)
);


ip_encode8 ip_encode8_0 (
	.clk(tx_xcvr_clk),
	.sync_reset(reset_encoders),
	
	.run(encode_run),
	
	.data_in(data_to_ip),

	.data_out(data_from_ip),
	
	.packet_length(encode_ip_packet_length),
	.protocol(encode_ip_protocol),
	.src_ip(encode_ip_src_ip),
	.dst_ip(encode_ip_dst_ip)
);



icmp_encode8 icmp_encode8_0 (
	.clk(tx_xcvr_clk),
	.sync_reset(reset_encoders),
	
	.run(encode_run),
	
	.data_in(icmp_fifo_data),

	.data_out(data_from_icmp),
	
	.icmp_type(encode_icmp_type),
	.code(encode_icmp_code),
	.checksum(encode_icmp_checksum)

);

reg [2*BYTE_SIZE-1:0] encode_udp_src_port;
reg [2*BYTE_SIZE-1:0] encode_udp_dst_port;

`ifdef FOUR_TX_PORTS 

always @ (*)
begin
	if(sel_tx_fifo == 2'b11)
	begin
		encode_udp_src_port = encode_udp_src_port_3;
		encode_udp_dst_port = encode_udp_dst_port_3;
	end
	else if (sel_tx_fifo == 2'b10)
	begin
		encode_udp_src_port = encode_udp_src_port_2;
		encode_udp_dst_port = encode_udp_dst_port_2;
	end
	else if (sel_tx_fifo == 2'b01)
	begin
		encode_udp_src_port = encode_udp_src_port_1;
		encode_udp_dst_port = encode_udp_dst_port_1;
	end
	else
	begin
		encode_udp_src_port = encode_udp_src_port_0;
		encode_udp_dst_port = encode_udp_dst_port_0;
	end
end

`else 

always @ (*)
begin
	if(sel_tx_fifo)
	begin
		encode_udp_src_port = encode_udp_src_port_1;
		encode_udp_dst_port = encode_udp_dst_port_1;
	end
	else
	begin
		encode_udp_src_port = encode_udp_src_port_0;
		encode_udp_dst_port = encode_udp_dst_port_0;
	end
end

`endif 

udp_encode8 udp_encode_0 (
	.clk(tx_xcvr_clk),
	.sync_reset(reset_encoders),
	
	.run(encode_run),
	
	.data_in(data_to_udp),

	.data_out(data_from_udp),
	
	.src_port(encode_udp_src_port),
	.dst_port(encode_udp_dst_port),
	.packet_length(encode_udp_packet_length),
	.checksum(16'h0000)
);

reg [AVL_SIZE-1:0] data_from_udp_fifo;

assign data_to_udp = data_from_udp_fifo;

reg rdreq_data_udp_fifo_0;
wire rdempty_data_udp_fifo_0;
wire [AVL_SIZE-1:0] data_from_udp_fifo_0;

reg rdreq_data_udp_fifo_1;
wire rdempty_data_udp_fifo_1;
wire [AVL_SIZE-1:0] data_from_udp_fifo_1;

`ifdef FOUR_TX_PORTS

reg rdreq_data_udp_fifo_2;
wire rdempty_data_udp_fifo_2;
wire [AVL_SIZE-1:0] data_from_udp_fifo_2;

reg rdreq_data_udp_fifo_3;
wire rdempty_data_udp_fifo_3;
wire [AVL_SIZE-1:0] data_from_udp_fifo_3;

always @ (*)
begin
	if(sel_tx_fifo == 2'b11)
	begin
		rdempty_data_udp_fifo = rdempty_data_udp_fifo_3;
		rdreq_data_udp_fifo_3 = rdreq_data_udp_fifo;
		rdreq_data_udp_fifo_2 = 1'b0;
		rdreq_data_udp_fifo_1 = 1'b0;
		rdreq_data_udp_fifo_0 = 1'b0;
		data_from_udp_fifo = data_from_udp_fifo_3;
	end
	else if (sel_tx_fifo == 2'b10)
	begin
		rdempty_data_udp_fifo = rdempty_data_udp_fifo_2;
		rdreq_data_udp_fifo_3 = 1'b0;
		rdreq_data_udp_fifo_2 = rdreq_data_udp_fifo;
		rdreq_data_udp_fifo_1 = 1'b0;
		rdreq_data_udp_fifo_0 = 1'b0;
		data_from_udp_fifo = data_from_udp_fifo_2;
	end
	else if (sel_tx_fifo == 2'b01)
	begin
		rdempty_data_udp_fifo = rdempty_data_udp_fifo_1;
		rdreq_data_udp_fifo_3 = 1'b0;
		rdreq_data_udp_fifo_2 = 1'b0;
		rdreq_data_udp_fifo_1 = rdreq_data_udp_fifo;
		rdreq_data_udp_fifo_0 = 1'b0;
		data_from_udp_fifo = data_from_udp_fifo_1;
	end
	else
	begin
		rdempty_data_udp_fifo = rdempty_data_udp_fifo_0;
		rdreq_data_udp_fifo_3 = 1'b0;
		rdreq_data_udp_fifo_2 = 1'b0;
		rdreq_data_udp_fifo_1 = 1'b0;
		rdreq_data_udp_fifo_0 = rdreq_data_udp_fifo;
		data_from_udp_fifo = data_from_udp_fifo_0;
	end
end

`else 

always @ (*)
begin
	if(sel_tx_fifo)
	begin
		rdempty_data_udp_fifo = rdempty_data_udp_fifo_1;
		rdreq_data_udp_fifo_1 = rdreq_data_udp_fifo;
		rdreq_data_udp_fifo_0 = 1'b0;
		data_from_udp_fifo = data_from_udp_fifo_1;
	end
	else
	begin
		rdempty_data_udp_fifo = rdempty_data_udp_fifo_0;
		rdreq_data_udp_fifo_1 = 1'b0;
		rdreq_data_udp_fifo_0 = rdreq_data_udp_fifo;
		data_from_udp_fifo = data_from_udp_fifo_0;
	end
end

`endif 

udp_fifo8 udp_tx_fifo8_0 (
	.aclr    (tx_sync_rst),    //   input,   width = 1,            .aclr
	
	.wrclk   (wrclk_udp_txfifo_0),   //   input,   width = 1,            .wrclk
	.wrreq   (wrreq_data_udp_txfifo_0),   //   input,   width = 1,            .wrreq
	.wrfull  (wrfull_data_udp_txfifo_0),   //  output,   width = 1,            .wrfull
	.data    (data_to_udp_txfifo_0),    //   input,  width = 32,  fifo_input.datain
	.wrusedw (wrusedw_data_udp_txfifo_0), //            output, width = 13 (8192 wd)	.wrusedw 
	
	.rdclk   (tx_xcvr_clk),   //   input,   width = 1,            .rdclk
	.rdreq   (rdreq_data_udp_fifo_0),   //   input,   width = 1,            .rdreq
	.q       (data_from_udp_fifo_0),       //  output,  width = 32, fifo_output.dataout
	.rdempty (rdempty_data_udp_fifo_0) //  output,   width = 1,            .rdempty
);

udp_fifo_status8 udp_tx_fifo_status8_0 (
	.aclr    (tx_sync_rst),    //   input,   width = 1,            .aclr

	.wrclk   (wrclk_udp_txfifo_0),   //   input,   width = 1,            .wrclk
	.data    (status_to_udp_txfifo_0),    //   input,  width = 96,  fifo_input.datain
	.wrreq   (wrreq_status_udp_txfifo_0),   //   input,   width = 1,            .wrreq
	.wrfull  (wrfull_status_udp_txfifo_0),   //  output,   width = 1,            .wrfull
	.wrusedw (wrusedw_status_udp_txfifo_0), //            output, width = 8 (256 wd)	.wrusedw 

	.rdclk   (tx_xcvr_clk),   //   input,   width = 1,            .rdclk
	.rdreq   (rdreq_status_udp_fifo_0),   //   input,   width = 1,            .rdreq
	.q       (status_from_udp_fifo_0),       //  output,  width = 96, fifo_output.dataout
	.rdempty (rdempty_status_udp_fifo_0) //  output,   width = 1,            .rdempty
);


udp_fifo8 udp_tx_fifo8_1 (
	.aclr    (tx_sync_rst),    //   input,   width = 1,            .aclr
	
	.wrclk   (wrclk_udp_txfifo_1),   //   input,   width = 1,            .wrclk
	.wrreq   (wrreq_data_udp_txfifo_1),   //   input,   width = 1,            .wrreq
	.wrfull  (wrfull_data_udp_txfifo_1),   //  output,   width = 1,            .wrfull
	.data    (data_to_udp_txfifo_1),    //   input,  width = 32,  fifo_input.datain
	.wrusedw (wrusedw_data_udp_txfifo_1), //            output, width = 13 (8192 wd)	.wrusedw 
	
	.rdclk   (tx_xcvr_clk),   //   input,   width = 1,            .rdclk
	.rdreq   (rdreq_data_udp_fifo_1),   //   input,   width = 1,            .rdreq
	.q       (data_from_udp_fifo_1),       //  output,  width = 32, fifo_output.dataout
	.rdempty (rdempty_data_udp_fifo_1) //  output,   width = 1,            .rdempty
);

udp_fifo_status8 udp_tx_fifo_status8_1 (
	.aclr    (tx_sync_rst),    //   input,   width = 1,            .aclr

	.wrclk   (wrclk_udp_txfifo_1),   //   input,   width = 1,            .wrclk
	.data    (status_to_udp_txfifo_1),    //   input,  width = 96,  fifo_input.datain
	.wrreq   (wrreq_status_udp_txfifo_1),   //   input,   width = 1,            .wrreq
	.wrfull  (wrfull_status_udp_txfifo_1),   //  output,   width = 1,            .wrfull
	.wrusedw (wrusedw_status_udp_txfifo_1), //            output, width = 8 (256 wd)	.wrusedw 

	.rdclk   (tx_xcvr_clk),   //   input,   width = 1,            .rdclk
	.rdreq   (rdreq_status_udp_fifo_1),   //   input,   width = 1,            .rdreq
	.q       (status_from_udp_fifo_1),       //  output,  width = 96, fifo_output.dataout
	.rdempty (rdempty_status_udp_fifo_1) //  output,   width = 1,            .rdempty
);

`ifdef FOUR_TX_PORTS 

udp_fifo8 udp_tx_fifo8_2 (
	.aclr    (tx_sync_rst),    //   input,   width = 1,            .aclr
	
	.wrclk   (wrclk_udp_txfifo_2),   //   input,   width = 1,            .wrclk
	.wrreq   (wrreq_data_udp_txfifo_2),   //   input,   width = 1,            .wrreq
	.wrfull  (wrfull_data_udp_txfifo_2),   //  output,   width = 1,            .wrfull
	.data    (data_to_udp_txfifo_2),    //   input,  width = 32,  fifo_input.datain
	.wrusedw (wrusedw_data_udp_txfifo_2), //            output, width = 13 (8192 wd)	.wrusedw 
	
	.rdclk   (tx_xcvr_clk),   //   input,   width = 1,            .rdclk
	.rdreq   (rdreq_data_udp_fifo_2),   //   input,   width = 1,            .rdreq
	.q       (data_from_udp_fifo_2),       //  output,  width = 32, fifo_output.dataout
	.rdempty (rdempty_data_udp_fifo_2) //  output,   width = 1,            .rdempty
);

udp_fifo_status8 udp_tx_fifo_status8_2 (
	.aclr    (tx_sync_rst),    //   input,   width = 1,            .aclr

	.wrclk   (wrclk_udp_txfifo_2),   //   input,   width = 1,            .wrclk
	.data    (status_to_udp_txfifo_2),    //   input,  width = 96,  fifo_input.datain
	.wrreq   (wrreq_status_udp_txfifo_2),   //   input,   width = 1,            .wrreq
	.wrfull  (wrfull_status_udp_txfifo_2),   //  output,   width = 1,            .wrfull
	.wrusedw (wrusedw_status_udp_txfifo_2), //            output, width = 8 (256 wd)	.wrusedw 

	.rdclk   (tx_xcvr_clk),   //   input,   width = 1,            .rdclk
	.rdreq   (rdreq_status_udp_fifo_2),   //   input,   width = 1,            .rdreq
	.q       (status_from_udp_fifo_2),       //  output,  width = 96, fifo_output.dataout
	.rdempty (rdempty_status_udp_fifo_2) //  output,   width = 1,            .rdempty
);

udp_fifo8 udp_tx_fifo8_3 (
	.aclr    (tx_sync_rst),    //   input,   width = 1,            .aclr
	
	.wrclk   (wrclk_udp_txfifo_3),   //   input,   width = 1,            .wrclk
	.wrreq   (wrreq_data_udp_txfifo_3),   //   input,   width = 1,            .wrreq
	.wrfull  (wrfull_data_udp_txfifo_3),   //  output,   width = 1,            .wrfull
	.data    (data_to_udp_txfifo_3),    //   input,  width = 32,  fifo_input.datain
	.wrusedw (wrusedw_data_udp_txfifo_3), //            output, width = 13 (8192 wd)	.wrusedw 
	
	.rdclk   (tx_xcvr_clk),   //   input,   width = 1,            .rdclk
	.rdreq   (rdreq_data_udp_fifo_3),   //   input,   width = 1,            .rdreq
	.q       (data_from_udp_fifo_3),       //  output,  width = 32, fifo_output.dataout
	.rdempty (rdempty_data_udp_fifo_3) //  output,   width = 1,            .rdempty
);

udp_fifo_status8 udp_tx_fifo_status8_3 (
	.aclr    (tx_sync_rst),    //   input,   width = 1,            .aclr

	.wrclk   (wrclk_udp_txfifo_3),   //   input,   width = 1,            .wrclk
	.data    (status_to_udp_txfifo_3),    //   input,  width = 96,  fifo_input.datain
	.wrreq   (wrreq_status_udp_txfifo_3),   //   input,   width = 1,            .wrreq
	.wrfull  (wrfull_status_udp_txfifo_3),   //  output,   width = 1,            .wrfull
	.wrusedw (wrusedw_status_udp_txfifo_3), //            output, width = 8 (256 wd)	.wrusedw 

	.rdclk   (tx_xcvr_clk),   //   input,   width = 1,            .rdclk
	.rdreq   (rdreq_status_udp_fifo_3),   //   input,   width = 1,            .rdreq
	.q       (status_from_udp_fifo_3),       //  output,  width = 96, fifo_output.dataout
	.rdempty (rdempty_status_udp_fifo_3) //  output,   width = 1,            .rdempty
);

`endif

endmodule
