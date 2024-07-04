module stretcher_edge_det (
    input clk_a,
    input clk_b,
    input data_in_a,    
    output data_out_b
);

wire data_stretched_a;

stretcher stretcher_start(
    .clk(clk_a),
    .signal_in(data_in_a),
    .signal_out(data_stretched_a)
);

sync_edge_det sync_edge_det_start(
    .clk(clk_b),
    .signal_in(data_stretched_a),
    .rising(data_out_b)
);
    
endmodule