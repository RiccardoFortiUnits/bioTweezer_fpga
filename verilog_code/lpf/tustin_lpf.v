//fmax 134 MHz limited by the sum + difference + multiplication
//latency 2
module tustin_lpf #(
    parameter   INPUT_BITS = 26, //assumed in Q1.INPUTBITS-1
                MULTIPLY_BITS = 27, //same as coeff
                OUTPUT_BITS = 32, //assumed in Q1.OUTPUTBITS-1
                LATENCY = 2
) (
    input                               clk,
    input                               rst,
    input signed[INPUT_BITS -1 : 0]     in,
    input                               in_valid,
    input signed [MULTIPLY_BITS -1 : 0] alpha,
    output signed [OUTPUT_BITS-1 : 0]   out,
    output                              out_valid  
);

reg signed [MULTIPLY_BITS -1 : 0] alpha_reg;

always @(posedge clk ) begin
    if (rst) begin
        alpha_reg <= 0;
    end
    else begin
        alpha_reg <= alpha;   
    end
end

reg signed [INPUT_BITS -1 : 0] in_temp, in_temp1, in_temp2;

reg signed [2*MULTIPLY_BITS -1 : 0] mult;

wire signed [2*MULTIPLY_BITS -1 : 0] acc;
reg signed [2*MULTIPLY_BITS -1 : 0] acc1, acc2;

reg signed [INPUT_BITS -1 : 0] out_temp;

always @(posedge clk ) begin
    if (rst) begin
        in_temp <= 0;
        in_temp1 <= 0;
        in_temp2 <= 0;
    end
    else if (in_valid) begin
        in_temp <= in;
        in_temp1 <= in_temp;
        in_temp2 <= in_temp1;        
    end
end

wire signed [INPUT_BITS : 0] input_sum = {in_temp[INPUT_BITS-1], in_temp} + {in_temp2[INPUT_BITS-1], in_temp2}; //sum the sample and the two old version Q2.25
wire signed [INPUT_BITS - 1 : 0] input_average = input_sum[INPUT_BITS : 1]; //divide by two Q1.25

wire signed [INPUT_BITS : 0] diff = {input_average[INPUT_BITS-1], input_average} - {out_temp[INPUT_BITS-1], out_temp}; //subtract feedback Q2.25

always @(posedge clk ) begin
    if (rst) begin
        mult <= 0;
    end
    else if (in_valid) begin
        mult <= diff * alpha_reg;
    end
end

assign acc = mult + acc2;

always @(posedge clk ) begin
    if (rst) begin
        acc1 <= 0;
        acc2 <= 0;
    end
    else if (in_valid) begin
        acc1 <= acc;
        acc2 <= acc1; 
    end
end

assign out = acc[2*MULTIPLY_BITS -3 -: OUTPUT_BITS];

always @(posedge clk ) begin
    if (rst) begin
        out_temp <= 0;
    end
    else if (in_valid) begin
        out_temp <= out[OUTPUT_BITS-1 -: INPUT_BITS];   
    end
end

reg [LATENCY-1:0] valid_lat;

always @(posedge clk ) begin
    if (rst) begin
        valid_lat <= 0;
    end
    else if (in_valid) begin
        valid_lat <= {valid_lat[LATENCY-2 : 0], in_valid};   
    end
end

assign out_valid = valid_lat[LATENCY-1] & in_valid;


// real in_real,alpha_real,input_average_real,diff_real,mult_real,acc_real,out_real;

// always @* begin
//     in_real = (in*(2.0**-25));
//     alpha_real = (alpha*(2.0**-26));
//     input_average_real = (input_average*(2.0**-25));
//     diff_real = (diff*(2.0**-25));
//     mult_real = (mult*(2.0**-51));
//     acc_real = (acc*(2.0**-51));
//     out_real = (out*(2.0**-31));    
// end

endmodule