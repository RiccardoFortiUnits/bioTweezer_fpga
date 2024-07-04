module clock_synchronizer (
    input   clk_125,
    input   clk_50,

    input   start_dac_cmd_125,
    output  start_dac_cmd_50,
    input   start_fifo_cmd_125,
    output  start_fifo_cmd_50,
    input   stop_dac_cmd_125,
    output  stop_dac_cmd_50,

    input   DAC_running_50,
    output  DAC_running_125,
    output  DAC_running_50_fb,
    input   ADC_ready_50,
    output  ADC_ready_125
);

//This module is used to synchronize commands from the decoders to the DAC/ADC/lockin section.
//The commands that need to be synchronized are only the one changing at runtime (e.g. phase):
//when the phase is changed the meta decoder change the phase and raises the flag "update_phase_cmd" at the same time,
//this module (or better the single stretcher_edge_det) stretches the pulse at 125 MHz by 4 and uses a double 50MHz reg and
//the final rising edge to get a "update_phase_cmd" @50MHz. This is used as an enable to register the value
//(e.g. the phase) in the  module in which it's used. The delay between the data change and the enable pulse
//is used to guarantee the correct domain crossing

stretcher_edge_det stretcher_edge_det_start_fifo(
    .clk_a(clk_125),  
    .clk_b(clk_50),
    .data_in_a(start_fifo_cmd_125),
    .data_out_b(start_fifo_cmd_50)
);

stretcher_edge_det stretcher_edge_det_start(
    .clk_a(clk_125),  
    .clk_b(clk_50),
    .data_in_a(start_dac_cmd_125),
    .data_out_b(start_dac_cmd_50)
);

stretcher_edge_det stretcher_edge_det_stop(
    .clk_a(clk_125),  
    .clk_b(clk_50),
    .data_in_a(stop_dac_cmd_125),
    .data_out_b(stop_dac_cmd_50)
);

// CROSSING SLOW SIGNALS FROM 50MHz to 125MHz

sync_edge_det sync_edge_det_DAC_running(
    .clk(clk_125),
    .signal_in(DAC_running_50),
    .data_out(DAC_running_125)
);
sync_edge_det sync_edge_det_DAC_running_fb(
    .clk(clk_50),
    .signal_in(DAC_running_125),
    .data_out(DAC_running_50_fb)
);

sync_edge_det sync_edge_det_ADC_ready(
    .clk(clk_125),
    .signal_in(ADC_ready_50),
    .data_out(ADC_ready_125)
);


endmodule