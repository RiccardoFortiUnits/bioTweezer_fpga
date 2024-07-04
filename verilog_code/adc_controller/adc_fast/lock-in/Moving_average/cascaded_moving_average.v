module cascaded_moving_average #(
    parameter MAX_DECIMATION = 1024,
	INPUT_DATA_BITS = 32,
    OUTPUT_DATA_BITS = 64,
    MAX_CASCADED_MAs = 3,
    SIGNED = 1
) (
    input   clock,
    input   reset,
    output  ready,

    input [INPUT_DATA_BITS-1:0]    	data_in,
    input               			data_in_valid,

    input [$clog2(MAX_DECIMATION)-1:0] 		length_moving_average,
    input [$clog2(MAX_CASCADED_MAs)-1:0] 	order_rolloff,          

    output [OUTPUT_DATA_BITS-1:0]    	data_out,
    output               				data_out_valid
);

localparam EXTRA_BITS = OUTPUT_DATA_BITS - INPUT_DATA_BITS;

assign ready = &single_ready;
wire [MAX_CASCADED_MAs-1 : 0] single_ready;

wire [OUTPUT_DATA_BITS-1:0] data_in_extended;

generate
    if (SIGNED == 1) begin
		assign data_in_extended = {{EXTRA_BITS{data_in[INPUT_DATA_BITS-1]}},data_in};
    end
    else begin
        assign data_in_extended = {{EXTRA_BITS{1'b0}},data_in};
    end
endgenerate

wire [OUTPUT_DATA_BITS-1:0] data_out_single_ma [0:MAX_CASCADED_MAs];
wire data_out_valid_single_ma [0:MAX_CASCADED_MAs];

assign data_out_single_ma[0] = data_in_extended; 
assign data_out_valid_single_ma[0] = data_in_valid; 

genvar i;
generate
	for (i = 1; i <= MAX_CASCADED_MAs; i = i + 1) begin : cascade
        moving_average #(
            .MAX_DECIMATION(MAX_DECIMATION),
            .DATA_BITS(OUTPUT_DATA_BITS)
        ) MA (
            .clock(clock),
            .reset(reset),
            .ready(single_ready[i-1]),
            .data_in(data_out_single_ma[i-1]),
            .data_in_valid(data_in_valid),
            .length(length_moving_average),
            .data_out(data_out_single_ma[i]),
            .data_out_valid(data_out_valid_single_ma[i])
        );
	end
endgenerate
	
assign data_out = data_out_single_ma[order_rolloff];
assign data_out_valid = data_out_valid_single_ma[order_rolloff];

endmodule