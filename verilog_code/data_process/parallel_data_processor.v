module parallel_data_processor #(
    parameter LOCKIN_NUMBER = 32,	//Max delay length
    parameter NCO_BANKS = 1 //each bank has 8 NCO
) (
    input   	clk_adc,
    input   	clk_adc_fast,
    input       clk_udp,
    input   	reset,
    input       filter_order, //0 for order 1, 1 for order 2

    input [8*LOCKIN_NUMBER - 1 : 0] lockin_config,

    input [63:0]            input_data,

    input signed [26:0]     alpha,

    input [NCOs-1 : 0]      ADC_acquire,
    input [NCOs-1 : 0]      XY_acquire,
    input [NCOs*64-1 : 0]   NCOs_wfm,

    output [107:0]   acq_rddata_fifo_108,
    output          acq_rdempty_fifo_108,
    input           acq_rdreq_fifo_108
);

reg [8*LOCKIN_NUMBER - 1 : 0] lockin_config_reg1, lockin_config_reg2;
reg [26:0] alpha_reg1, alpha_reg2;
// CDC for lockin_config and alpha from the 125 MHz 
always @(posedge clk_adc ) begin
    lockin_config_reg1 <= lockin_config;
    lockin_config_reg2 <= lockin_config_reg1;
    alpha_reg1 <= alpha;
    alpha_reg2 <= alpha_reg1;
end

localparam  NCO_CHANNELS = 8,
            MULTIPLIER_BITS = 27,
            LOCKIN_latency = 3,
            LOCKIN2_latency = 5,
            NCOs = NCO_CHANNELS * NCO_BANKS;


//unpack NCO streams
wire [63:0] NCOs_wfm_unpack [NCOs-1:0];
genvar j;
generate
    for (j = 0; j < NCOs ; j = j+1) begin : loop_NCOs
        assign NCOs_wfm_unpack[j] = NCOs_wfm[(j+1)*64 - 1 -: 64];
    end
endgenerate
//unpack ADC streams
wire [15:0] ADC_data_unpack [3:0];
genvar h;
generate
    for (h = 0; h < 4 ; h = h+1) begin : loop_ADCs
        assign ADC_data_unpack[h] = input_data[(h+1)*16 - 1 -: 16];
    end
endgenerate


wire [3:0] lockin_nco_select [LOCKIN_NUMBER-1:0]; //up to 16 NCO, 4 bit addressing
wire [1:0] lockin_input_select [LOCKIN_NUMBER-1:0]; //4 inputs, 2 bit addressing
wire lockin_enable [LOCKIN_NUMBER-1:0]; //1 bit enable

reg [63:0] lockin_nco_wfm [LOCKIN_NUMBER-1:0];
reg [15:0] lockin_input [LOCKIN_NUMBER-1:0];
reg [LOCKIN_NUMBER-1:0] lockin_input_acquire;
reg [LOCKIN_NUMBER-1:0] lockin_store_freq;
reg [LOCKIN_NUMBER-1:0] lockin_output_acquire;


wire [31:0] X_reg [LOCKIN_NUMBER-1:0];
wire [31:0] Y_reg [LOCKIN_NUMBER-1:0];
wire [31:0] freq_reg [LOCKIN_NUMBER-1:0];
wire [LOCKIN_NUMBER-1:0] lockin_output_valid;
reg [LOCKIN_NUMBER-1:0] lockin_output_read;

genvar i;
generate
    for (i = 0; i < LOCKIN_NUMBER ; i = i+1) begin : loop_lockins
        // extract the multiplexing controls for each lockin
        assign lockin_nco_select[i] = lockin_config_reg2[i*8 + 4 - 1 -: 4];
        assign lockin_input_select[i] = lockin_config_reg2[i*8 + 6 - 1 -: 2];
        assign lockin_enable[i] = lockin_config_reg2[i*8 + 8 - 1];
        // do the multiplexing for each lockin
        always @(posedge clk_adc ) begin
            lockin_nco_wfm[i] <= NCOs_wfm_unpack[lockin_nco_select[i]];
            lockin_input[i] <= ADC_data_unpack[lockin_input_select[i]];
            lockin_input_acquire[i] <= ADC_acquire[lockin_nco_select[i]] && lockin_enable[i];
            lockin_output_acquire[i] <= XY_acquire[lockin_nco_select[i]] && lockin_enable[i];
        end         
        // lockins
        lockin_ch #(.LOCKIN_latency(LOCKIN_latency), .LOCKIN2_latency(LOCKIN2_latency)) lockins(
            .clk_adc(clk_adc),
            .clk_adc_fast(clk_adc_fast),
            .reset(reset),
            .filter_order(filter_order),

            .lockin_nco_wfm(lockin_nco_wfm[i]), 
            .lockin_input(lockin_input[i]), 
            .lockin_input_acquire(lockin_input_acquire[i]), 
            .lockin_output_acquire(lockin_output_acquire[i]),

            .alpha(alpha_reg2),

            .X_reg(X_reg[i]),
            .Y_reg(Y_reg[i]),
            .freq_reg(freq_reg[i]),
            .lockin_output_valid(lockin_output_valid[i]),
            .lockin_output_read(lockin_output_read[i])
        );
    end
endgenerate

// round robin logic

reg [7 : 0] round_robin;
reg [103:0] data_to_udp;
reg write_to_udp;
wire udp_fifo_full;

always @(posedge clk_adc) begin
    if(reset) round_robin <= 0;
    else if (!udp_fifo_full) begin
        if (round_robin == (LOCKIN_NUMBER-1)) round_robin <= 0;
        else round_robin <= round_robin + 1'b1;
    end
end
always @(posedge clk_adc) begin
    if(reset) begin
        lockin_output_read <= 0;
        data_to_udp <= 104'd0;
        write_to_udp <= 0;
    end
    else if (!udp_fifo_full) begin
        if (lockin_output_valid[round_robin]) begin
            lockin_output_read <= 1'b1 << round_robin;
            data_to_udp <= {round_robin, freq_reg[round_robin], Y_reg[round_robin], X_reg[round_robin]};
            write_to_udp <= 1'b1;
        end
        else begin
            lockin_output_read <= 0;
            write_to_udp <= 1'b0;
        end
    end
    else begin
        lockin_output_read <= 0;
        write_to_udp <= 1'b0;
    end
end

// fifo for udp 

data_fifo fifo_to_udp (
	.wrclk(clk_adc),
	.data(data_to_udp),
	.wrreq(write_to_udp),
	.wrfull(udp_fifo_full),
	.rdclk(clk_udp),
	.q(acq_rddata_fifo_108),
	.rdreq(acq_rdreq_fifo_108),
	.rdempty(acq_rdempty_fifo_108)
);

endmodule