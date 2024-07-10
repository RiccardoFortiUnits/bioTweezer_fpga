#**************************************************************
# This .sdc file is created by Terasic Tool.
# Users are recommended to modify this file to match users logic.
#**************************************************************

#**************************************************************
# Create Clock
#**************************************************************
create_clock -period 8.000ns [get_ports REFCLK_125]
create_clock -period 8.000ns [get_ports CLOCK_125_p]
create_clock -period 20.000ns [get_ports CLOCK_50_B5B]
create_clock -period 20.000ns [get_ports CLOCK_50_B6A]
create_clock -period 20.000ns [get_ports CLOCK_50_B7A]
create_clock -period 20.000ns [get_ports CLOCK_50_B8A]
create_clock -period 10.000ns [get_ports adc_fclk]


#**************************************************************
# Create Generated Clock
#**************************************************************

derive_pll_clocks -use_net_name

set main_clk "ADC_FAST_wrapper:ADC_FAST_wrapper_0|adc_lvds:adc_lvds_0|altlvds_rx:ALTLVDS_RX_component|adc_lvds_lvds_rx1:auto_generated|wire_pll_sclk_outclk"
#set ADC_outclock_50 ADC_FAST_wrapper:ADC_FAST_wrapper_0|pll_adc:pll_adc_outclock_50|pll_adc_0002:pll_adc_inst|altera_pll:altera_pll_i|outclk_wire[0]
# DAC SPI clock

#create_generated_clock -name ADC_outclock_50 -source [get_pins {ADC_FAST_wrapper_0|ADC_outclock_50|clk}] -divide_by 2 [get_pins {ADC_FAST_wrapper_0|ADC_outclock_50|q}]

create_generated_clock -name sclk_DAC -source [get_pins {DAC_wrapper_0|dacs_ad5541a_0|sclk|clk}] -divide_by 2 [get_pins {DAC_wrapper_0|dacs_ad5541a_0|sclk|q}]
create_generated_clock -name sclk_DAC_port -source [get_pins {DAC_wrapper_0|dacs_ad5541a_0|sclk|q}]  [get_ports {DAC_SCK}]

create_generated_clock -name sclk_ADC -source [get_pins {ADC_FAST_wrapper_0|ADC_configurator_0|ADC_spi_interface_1|clock_5|clk}]   -divide_by 10 -phase 180 [get_pins {ADC_FAST_wrapper_0|ADC_configurator_0|ADC_spi_interface_1|clock_5|q}]
create_generated_clock -name sclk_ADC_port -source [get_pins {ADC_FAST_wrapper_0|ADC_configurator_0|ADC_spi_interface_1|clock_5|q}] [get_ports {adc_spi_sclk}]


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************
derive_clock_uncertainty



#**************************************************************
# Set Input Delay
#**************************************************************
# jtag interface
#set_input_delay -clock altera_reserved_tck -clock_fall 3 [get_ports altera_reserved_tdi]
#set_input_delay -clock altera_reserved_tck -clock_fall 3 [get_ports altera_reserved_tms]
#set_output_delay -clock altera_reserved_tck -clock_fall 3 [get_ports altera_reserved_tdo]

#**************************************************************
# Set Output Delay
#**************************************************************

#DAC SPI lines  
set_output_delay -clock sclk_DAC_port 0.0 [get_ports {DAC_CS_N[*]}]
#set_output_delay -clock sclk_DAC_port 0.0 [get_ports {DAC_SDO[*]}]

#ADC SPI lines
#set_input_delay -clock sclk_ADC_port 0.0 [get_ports {adc_spi_sdio}]
#set_output_delay -clock sclk_ADC_port 0.0 [get_ports {adc_spi_sdio}]
#set_output_delay -clock sclk_ADC_port 0.0 [get_ports {adc_spi_csb}]

#DAC SPI lines  
set_output_delay -clock sclk_DAC_port -max 15ns [get_ports {DAC_SDO[*]}]
set_output_delay -clock sclk_DAC_port -min -4ns [get_ports {DAC_SDO[*]}]
set_multicycle_path -setup -start 1 -from [get_clocks ADC_FAST_wrapper:ADC_FAST_wrapper_0|pll_adc:pll_adc_outclock_50|pll_adc_0002:pll_adc_inst|altera_pll:altera_pll_i|outclk_wire[0]] -to [get_clocks sclk_DAC_port]
set_multicycle_path -hold -start 1 -from [get_clocks ADC_FAST_wrapper:ADC_FAST_wrapper_0|pll_adc:pll_adc_outclock_50|pll_adc_0002:pll_adc_inst|altera_pll:altera_pll_i|outclk_wire[0]] -to [get_clocks sclk_DAC_port]

#ADC SPI lines
######## FAST ADC SPI lines ############
set adc_spi_tds 2
set adc_spi_tdh 2
set_multicycle_path  -setup -start 2 -from [get_clocks {CLOCK_50_B7A}] -through [get_nets {ADC_FAST_wrapper_0|ADC_configurator_0|ADC_spi_interface_1|data_tx}] -to [get_clocks {sclk_ADC_port}]
set_multicycle_path  -hold -start 9 -from [get_clocks {CLOCK_50_B7A}] -through [get_nets {ADC_FAST_wrapper_0|ADC_configurator_0|ADC_spi_interface_1|data_tx}] -to [get_clocks {sclk_ADC_port}]
set_multicycle_path  -setup -start 5 -from [get_clocks {CLOCK_50_B7A}] -through [get_nets {ADC_FAST_wrapper_0|ADC_configurator_0|ADC_spi_interface_1|write}] -to [get_clocks {sclk_ADC_port}]
set_multicycle_path  -hold -start 7 -from [get_clocks {CLOCK_50_B7A}] -through [get_nets {ADC_FAST_wrapper_0|ADC_configurator_0|ADC_spi_interface_1|write}] -to [get_clocks {sclk_ADC_port}]
set_output_delay -clock sclk_ADC_port -max [expr ($adc_spi_tds)]  [get_ports {adc_spi_sdio}]
set_output_delay -clock sclk_ADC_port -min [expr (-$adc_spi_tdh)] [get_ports {adc_spi_sdio}]
set_input_delay -clock sclk_ADC_port 0.0 [get_ports {adc_spi_sdio}]
set_output_delay -clock sclk_ADC_port 0.0 [get_ports {adc_spi_csb}]


#**************************************************************
# Set Clock Groups
#**************************************************************

set_clock_groups -asynchronous \
                -group { \
                        CLOCK_50_B5B \
                        } \
                -group { \
                        CLOCK_50_B6A \
                        } \
                -group { \
                        CLOCK_50_B8A \
                        } \
                -group { \
                        CLOCK_50_B7A \
                        pll:pll_0|pll_0002:pll_inst|altera_pll:altera_pll_i|general[0].gpll~FRACTIONAL_PLL_O_VCOPH0 \
                        pll:pll_0|pll_0002:pll_inst|altera_pll:altera_pll_i|outclk_wire[0] \
                        } \
                -group { \
                        adc_fclk \
                        sclk_DAC \
			ADC_FAST_wrapper:ADC_FAST_wrapper_0|pll_adc:pll_adc_outclock_50|pll_adc_0002:pll_adc_inst|altera_pll:altera_pll_i|outclk_wire[0] \
			ADC_FAST_wrapper:ADC_FAST_wrapper_0|pll_adc:pll_adc_outclock_50|pll_adc_0002:pll_adc_inst|altera_pll:altera_pll_i|outclk_wire[1] \
                        ADC_FAST_wrapper:ADC_FAST_wrapper_0|adc_lvds:adc_lvds_0|altlvds_rx:ALTLVDS_RX_component|adc_lvds_lvds_rx:auto_generated|wire_pll_sclk_outclk \
                        } \
                -group { \
                        REFCLK_125 \
                        network_wrapper:network_wrapper_0|eth_1gb_wrapper:eth_1gb_wrapper_0|tse_core:tse_core_0|tse_core_0002:tse_core_inst|altera_xcvr_custom:i_custom_phyip_0|av_xcvr_custom_nr:A5|av_xcvr_custom_native:transceiver_core|av_xcvr_native:gen.av_xcvr_native_insts[0].gen_bonded_group.av_xcvr_native_inst|av_pma:inst_av_pma|av_rx_pma:av_rx_pma|rx_pmas[0].rx_pma.wire_refclk_to_cdr \
                        network_wrapper:network_wrapper_0|eth_1gb_wrapper:eth_1gb_wrapper_0|tse_core:tse_core_0|tse_core_0002:tse_core_inst|altera_xcvr_custom:i_custom_phyip_0|av_xcvr_custom_nr:A5|av_xcvr_custom_native:transceiver_core|av_xcvr_plls:gen.av_xcvr_native_insts[0].gen_tx_plls.gen_tx_plls.tx_plls|outclk[0] \
                        network_wrapper:network_wrapper_0|eth_1gb_wrapper:eth_1gb_wrapper_0|tse_core:tse_core_0|tse_core_0002:tse_core_inst|altera_xcvr_custom:i_custom_phyip_0|av_xcvr_custom_nr:A5|av_xcvr_custom_native:transceiver_core|av_xcvr_native:gen.av_xcvr_native_insts[0].gen_bonded_group.av_xcvr_native_inst|av_pma:inst_av_pma|av_tx_pma:av_tx_pma|av_tx_pma_ch:tx_pma_insts[0].av_tx_pma_ch_inst|tx_pma_ch.cpulse_from_cgb \
                        network_wrapper:network_wrapper_0|eth_1gb_wrapper:eth_1gb_wrapper_0|tse_core:tse_core_0|tse_core_0002:tse_core_inst|altera_xcvr_custom:i_custom_phyip_0|av_xcvr_custom_nr:A5|av_xcvr_custom_native:transceiver_core|av_xcvr_native:gen.av_xcvr_native_insts[0].gen_bonded_group.av_xcvr_native_inst|av_pma:inst_av_pma|av_tx_pma:av_tx_pma|av_tx_pma_ch:tx_pma_insts[0].av_tx_pma_ch_inst|tx_pma_ch.hclk_from_cgb \
                        network_wrapper:network_wrapper_0|eth_1gb_wrapper:eth_1gb_wrapper_0|tse_core:tse_core_0|tse_core_0002:tse_core_inst|altera_xcvr_custom:i_custom_phyip_0|av_xcvr_custom_nr:A5|av_xcvr_custom_native:transceiver_core|av_xcvr_native:gen.av_xcvr_native_insts[0].gen_bonded_group.av_xcvr_native_inst|av_pma:inst_av_pma|av_tx_pma:av_tx_pma|av_tx_pma_ch:tx_pma_insts[0].av_tx_pma_ch_inst|tx_pma_ch.lfclk_from_cgb \
                        network_wrapper_0|eth_1gb_wrapper_0|tse_core_0|tse_core_inst|i_custom_phyip_0|A5|transceiver_core|gen.av_xcvr_native_insts[0].gen_bonded_group.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_8g_rx_pcs|wys|txpmaclk \
                        network_wrapper_0|eth_1gb_wrapper_0|tse_core_0|tse_core_inst|i_custom_phyip_0|A5|transceiver_core|gen.av_xcvr_native_insts[0].gen_bonded_group.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_8g_tx_pcs|wys|txpmalocalclk \
                        network_wrapper:network_wrapper_0|eth_1gb_wrapper:eth_1gb_wrapper_0|tse_core:tse_core_0|tse_core_0002:tse_core_inst|altera_xcvr_custom:i_custom_phyip_0|av_xcvr_custom_nr:A5|av_xcvr_custom_native:transceiver_core|av_xcvr_native:gen.av_xcvr_native_insts[0].gen_bonded_group.av_xcvr_native_inst|av_pma:inst_av_pma|av_tx_pma:av_tx_pma|av_tx_pma_ch:tx_pma_insts[0].av_tx_pma_ch_inst|tx_pma_ch.pclk_from_cgb[0] \
                        network_wrapper:network_wrapper_0|eth_1gb_wrapper:eth_1gb_wrapper_0|tse_core:tse_core_0|tse_core_0002:tse_core_inst|altera_xcvr_custom:i_custom_phyip_0|av_xcvr_custom_nr:A5|av_xcvr_custom_native:transceiver_core|av_xcvr_native:gen.av_xcvr_native_insts[0].gen_bonded_group.av_xcvr_native_inst|av_pma:inst_av_pma|av_tx_pma:av_tx_pma|av_tx_pma_ch:tx_pma_insts[0].av_tx_pma_ch_inst|tx_pma_ch.pclk_from_cgb[1] \
                        network_wrapper:network_wrapper_0|eth_1gb_wrapper:eth_1gb_wrapper_0|tse_core:tse_core_0|tse_core_0002:tse_core_inst|altera_xcvr_custom:i_custom_phyip_0|av_xcvr_custom_nr:A5|av_xcvr_custom_native:transceiver_core|av_xcvr_native:gen.av_xcvr_native_insts[0].gen_bonded_group.av_xcvr_native_inst|av_pma:inst_av_pma|av_tx_pma:av_tx_pma|av_tx_pma_ch:tx_pma_insts[0].av_tx_pma_ch_inst|tx_pma_ch.pclk_from_cgb[2] \
                        } \

# -group { \
                        REFCLK_125 \
                        eth_1gb_wrapper:eth_1gb_wrapper_0|tse_core:tse_core_0|tse_core_0002:tse_core_inst|altera_xcvr_custom:i_custom_phyip_0|av_xcvr_custom_nr:A5|av_xcvr_custom_native:transceiver_core|av_xcvr_native:gen.av_xcvr_native_insts[0].gen_bonded_group.av_xcvr_native_inst|av_pma:inst_av_pma|av_rx_pma:av_rx_pma|rx_pmas[0].rx_pma.wire_refclk_to_cdr \
                        eth_1gb_wrapper:eth_1gb_wrapper_0|tse_core:tse_core_0|tse_core_0002:tse_core_inst|altera_xcvr_custom:i_custom_phyip_0|av_xcvr_custom_nr:A5|av_xcvr_custom_native:transceiver_core|av_xcvr_plls:gen.av_xcvr_native_insts[0].gen_tx_plls.gen_tx_plls.tx_plls|outclk[0] \
                        eth_1gb_wrapper:eth_1gb_wrapper_0|tse_core:tse_core_0|tse_core_0002:tse_core_inst|altera_xcvr_custom:i_custom_phyip_0|av_xcvr_custom_nr:A5|av_xcvr_custom_native:transceiver_core|av_xcvr_native:gen.av_xcvr_native_insts[0].gen_bonded_group.av_xcvr_native_inst|av_pma:inst_av_pma|av_tx_pma:av_tx_pma|av_tx_pma_ch:tx_pma_insts[0].av_tx_pma_ch_inst|tx_pma_ch.cpulse_from_cgb \
                        eth_1gb_wrapper:eth_1gb_wrapper_0|tse_core:tse_core_0|tse_core_0002:tse_core_inst|altera_xcvr_custom:i_custom_phyip_0|av_xcvr_custom_nr:A5|av_xcvr_custom_native:transceiver_core|av_xcvr_native:gen.av_xcvr_native_insts[0].gen_bonded_group.av_xcvr_native_inst|av_pma:inst_av_pma|av_tx_pma:av_tx_pma|av_tx_pma_ch:tx_pma_insts[0].av_tx_pma_ch_inst|tx_pma_ch.hclk_from_cgb \
                        eth_1gb_wrapper:eth_1gb_wrapper_0|tse_core:tse_core_0|tse_core_0002:tse_core_inst|altera_xcvr_custom:i_custom_phyip_0|av_xcvr_custom_nr:A5|av_xcvr_custom_native:transceiver_core|av_xcvr_native:gen.av_xcvr_native_insts[0].gen_bonded_group.av_xcvr_native_inst|av_pma:inst_av_pma|av_tx_pma:av_tx_pma|av_tx_pma_ch:tx_pma_insts[0].av_tx_pma_ch_inst|tx_pma_ch.lfclk_from_cgb \
                        eth_1gb_wrapper_0|tse_core_0|tse_core_inst|i_custom_phyip_0|A5|transceiver_core|gen.av_xcvr_native_insts[0].gen_bonded_group.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_8g_rx_pcs|wys|txpmaclk \
                        eth_1gb_wrapper_0|tse_core_0|tse_core_inst|i_custom_phyip_0|A5|transceiver_core|gen.av_xcvr_native_insts[0].gen_bonded_group.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_8g_tx_pcs|wys|txpmalocalclk \
                        eth_1gb_wrapper:eth_1gb_wrapper_0|tse_core:tse_core_0|tse_core_0002:tse_core_inst|altera_xcvr_custom:i_custom_phyip_0|av_xcvr_custom_nr:A5|av_xcvr_custom_native:transceiver_core|av_xcvr_native:gen.av_xcvr_native_insts[0].gen_bonded_group.av_xcvr_native_inst|av_pma:inst_av_pma|av_tx_pma:av_tx_pma|av_tx_pma_ch:tx_pma_insts[0].av_tx_pma_ch_inst|tx_pma_ch.pclk_from_cgb[0] \
                        eth_1gb_wrapper:eth_1gb_wrapper_0|tse_core:tse_core_0|tse_core_0002:tse_core_inst|altera_xcvr_custom:i_custom_phyip_0|av_xcvr_custom_nr:A5|av_xcvr_custom_native:transceiver_core|av_xcvr_native:gen.av_xcvr_native_insts[0].gen_bonded_group.av_xcvr_native_inst|av_pma:inst_av_pma|av_tx_pma:av_tx_pma|av_tx_pma_ch:tx_pma_insts[0].av_tx_pma_ch_inst|tx_pma_ch.pclk_from_cgb[1] \
                        eth_1gb_wrapper:eth_1gb_wrapper_0|tse_core:tse_core_0|tse_core_0002:tse_core_inst|altera_xcvr_custom:i_custom_phyip_0|av_xcvr_custom_nr:A5|av_xcvr_custom_native:transceiver_core|av_xcvr_native:gen.av_xcvr_native_insts[0].gen_bonded_group.av_xcvr_native_inst|av_pma:inst_av_pma|av_tx_pma:av_tx_pma|av_tx_pma_ch:tx_pma_insts[0].av_tx_pma_ch_inst|tx_pma_ch.pclk_from_cgb[2] \
                        } \
                
#-group { \
                        altera_reserved_tck \
                        } \
#**************************************************************
# Set False Path
#**************************************************************

#false path from initial boot reset 
set_false_path -from {initial_reset_0|delay_reset_n}
set_false_path -from {initial_reset_0|start_config} 

# FPGA IO port constraints
set_false_path -from [get_ports {CPU_RESET_n}] -to *
set_false_path -from [get_ports {SW[*]}] -to *
set_false_path -from * -to [get_ports {LEDG[*]}]
set_false_path -from * -to [get_ports {LEDR[*]}]


#**************************************************************
# Set Multicycle Path
#**************************************************************

# Decoder timing
set_multicycle_path  -setup -start 2 -from {network_wrapper:network_wrapper_0|dec_comm8_port1:dec_comm8_1|received_cmd*}
set_multicycle_path  -hold -start 1 -from {network_wrapper:network_wrapper_0|dec_comm8_port1:dec_comm8_1|received_cmd*}
set_multicycle_path  -setup -start 2 -from {network_wrapper:network_wrapper_0|dec_comm8_port1:dec_comm8_1|received_data*}
set_multicycle_path  -hold -start 1 -from {network_wrapper:network_wrapper_0|dec_comm8_port1:dec_comm8_1|received_data*}


#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************



#**************************************************************
# Set Load
#**************************************************************



