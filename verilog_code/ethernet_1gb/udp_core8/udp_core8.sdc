#SDC file for udp_core8_0.v

#**************************************************************
# Set False Path
#**************************************************************

set_false_path -from {*eth_1gb_wrapper_0|mac_config_0|finish_mac} -to {*}
set_false_path -from {*eth_1gb_wrapper_0|trc_config_0|finish_trc} -to {*}

# async reset for service fifo
set_false_path -from {*udp_core8_0|rx_wrapper8_0|rx_manager8_0|icmp_clear_fifo} -to {*}

# tx_busy flag for stopping rx
set_false_path -from {*udp_core8_0|tx_wrapper8_0|tx_manager8_0|tx_busy} -to {*}

# clock domain crossing for service fifo
set_false_path -from {*} -to {*udp_core8_0|tx_wrapper8_0|tx_manager8_0|response_data[*]}
set_false_path -from {*udp_core8_0|rx_wrapper8_0|rx_manager8_0|arp_to_tx_valid} -to {*}
set_false_path -from {*udp_core8_0|rx_wrapper8_0|rx_manager8_0|icmp_to_tx_valid} -to {*}
set_false_path -from {*udp_core8_0|rx_wrapper8_0|rx_manager8_0|icmp_checksum[*]} -to {*}

#**************************************************************
# Set Multicycle Path
#**************************************************************

# the following register are read after 2 clock cycles to ensure stability 

set_multicycle_path -setup -from {*udp_core8_0|tx_wrapper8_0|tx_manager8_0|encode_ip_packet_length[*]} -to {*} 2
set_multicycle_path -setup -from {*udp_core8_0|tx_wrapper8_0|tx_manager8_0|encode_ip_dst_ip[*]} -to {*} 2
set_multicycle_path -setup -from {*udp_core8_0|tx_wrapper8_0|tx_manager8_0|encode_arp_dst_ip[*]} -to {*} 2
set_multicycle_path -setup -from {*udp_core8_0|tx_wrapper8_0|tx_manager8_0|encode_arp_dst_mac[*]} -to {*} 2
set_multicycle_path -setup -from {*udp_core8_0|tx_wrapper8_0|tx_manager8_0|encode_frame_dst_mac[*]} -to {*} 2
set_multicycle_path -setup -from {*udp_core8_0|tx_wrapper8_0|tx_manager8_0|encode_frame_packet_type[*]} -to {*} 2
set_multicycle_path -setup -from {*udp_core8_0|tx_wrapper8_0|tx_manager8_0|encode_ip_protocol[*]} -to {*} 2
set_multicycle_path -setup -from {*udp_core8_0|tx_wrapper8_0|tx_manager8_0|encode_udp_src_port_0[*]} -to {*} 2
set_multicycle_path -setup -from {*udp_core8_0|tx_wrapper8_0|tx_manager8_0|encode_udp_dst_port_0[*]} -to {*} 2
set_multicycle_path -setup -from {*udp_core8_0|tx_wrapper8_0|tx_manager8_0|encode_udp_src_port_1[*]} -to {*} 2
set_multicycle_path -setup -from {*udp_core8_0|tx_wrapper8_0|tx_manager8_0|encode_udp_dst_port_1[*]} -to {*} 2
set_multicycle_path -setup -from {*udp_core8_0|tx_wrapper8_0|tx_manager8_0|encode_udp_packet_length[*]} -to {*} 3

set_multicycle_path -setup -from {*} -to {*udp_core8_0|tx_wrapper8_0|tx_manager8_0|encode_ip_packet_length[*]} 2
set_multicycle_path -setup -from {*} -to {*udp_core8_0|tx_wrapper8_0|tx_manager8_0|encode_frame_dst_mac[*]} 2
set_multicycle_path -setup -from {*} -to {*udp_core8_0|tx_wrapper8_0|tx_manager8_0|encode_ip_dst_ip[*]} 2
set_multicycle_path -setup -from {*} -to {*udp_core8_0|tx_wrapper8_0|tx_manager8_0|encode_udp_packet_length[*]} 2

set_multicycle_path -hold -from {*udp_core8_0|tx_wrapper8_0|tx_manager8_0|encode_ip_packet_length[*]} -to {*} 1
set_multicycle_path -hold -from {*udp_core8_0|tx_wrapper8_0|tx_manager8_0|encode_ip_dst_ip[*]} -to {*} 1
set_multicycle_path -hold -from {*udp_core8_0|tx_wrapper8_0|tx_manager8_0|encode_arp_dst_ip[*]} -to {*} 1
set_multicycle_path -hold -from {*udp_core8_0|tx_wrapper8_0|tx_manager8_0|encode_arp_dst_mac[*]} -to {*} 1
set_multicycle_path -hold -from {*udp_core8_0|tx_wrapper8_0|tx_manager8_0|encode_frame_dst_mac[*]} -to {*} 1
set_multicycle_path -hold -from {*udp_core8_0|tx_wrapper8_0|tx_manager8_0|encode_frame_packet_type[*]} -to {*} 1
set_multicycle_path -hold -from {*udp_core8_0|tx_wrapper8_0|tx_manager8_0|encode_ip_protocol[*]} -to {*} 1
set_multicycle_path -hold -from {*udp_core8_0|tx_wrapper8_0|tx_manager8_0|encode_udp_src_port_0[*]} -to {*} 1
set_multicycle_path -hold -from {*udp_core8_0|tx_wrapper8_0|tx_manager8_0|encode_udp_dst_port_0[*]} -to {*} 1
set_multicycle_path -hold -from {*udp_core8_0|tx_wrapper8_0|tx_manager8_0|encode_udp_src_port_1[*]} -to {*} 1
set_multicycle_path -hold -from {*udp_core8_0|tx_wrapper8_0|tx_manager8_0|encode_udp_dst_port_1[*]} -to {*} 1
set_multicycle_path -hold -from {*udp_core8_0|tx_wrapper8_0|tx_manager8_0|encode_udp_packet_length[*]} -to {*} 2

set_multicycle_path -hold -from {*} -to {*udp_core8_0|tx_wrapper8_0|tx_manager8_0|encode_ip_packet_length[*]} 1
set_multicycle_path -hold -from {*} -to {*udp_core8_0|tx_wrapper8_0|tx_manager8_0|encode_frame_dst_mac[*]} 1
set_multicycle_path -hold -from {*} -to {*udp_core8_0|tx_wrapper8_0|tx_manager8_0|encode_ip_dst_ip[*]} 1
set_multicycle_path -hold -from {*} -to {*udp_core8_0|tx_wrapper8_0|tx_manager8_0|encode_udp_packet_length[*]} 1

