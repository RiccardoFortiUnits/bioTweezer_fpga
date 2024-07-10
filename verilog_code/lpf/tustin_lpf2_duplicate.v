//Implementation registering the average of the sum to improve timing and moving accumulation register to infer accumulator
//fmax > 250 MHz
//latency 3

//when multiplier is 0 the alpha input is actually long clog2(MULTIPLIER_BITS) and is the number of shifts.
//eg alpha=1 is equal to a coefficient 0.5, alpha=3 is equal to a coeff 0.125 ... 2^(-alpha)
//when multiplier is 0 latency is equal to 4 (to achieve fmax > 200 MHz)
module tustin_lpf2_duplicate #(
    parameter   INPUT_BITS = 26, //assumed in Q1.INPUTBITS-1
                MULTIPLIER_BITS = 27, //same as coeff
                OUTPUT_BITS = 32 //assumed in Q1.OUTPUTBITS-1 
) (
    input                               clk,
    input                               rst,
    input signed[INPUT_BITS -1 : 0]     in,
    input                               in_valid,
    input signed [MULTIPLIER_BITS -1 : 0]    alpha,
    output signed [OUTPUT_BITS-1 : 0]   out,
    output                              out_valid  
);

localparam  LATENCY = 3;

wire signed [INPUT_BITS -1 : 0] out_feedback;
reg signed [MULTIPLIER_BITS -1 : 0] alpha_reg; //register for the coefficient (only with multiplier)
reg signed [INPUT_BITS -1 : 0] in_reg, in_reg1, in_reg2; //input register
reg signed [INPUT_BITS - 1 : 0] average_reg; //register for the average (inside the DSP)
reg signed [(INPUT_BITS + MULTIPLIER_BITS) : 0] acc_reg, acc_double; //double register for the accumulation (inside the DSP)
reg signed [INPUT_BITS -1 : 0] out_del; //used for the feedback of the output

always @(posedge clk  or posedge rst) begin
    if (rst) begin
        in_reg <= 0;
        in_reg1 <= 0;
        in_reg2 <= 0;
    end
    else if (in_valid) begin
        in_reg <= in;
        in_reg1 <= in_reg;
        in_reg2 <= in_reg1;        
    end
end

wire signed [INPUT_BITS : 0] input_sum = {in_reg[INPUT_BITS-1], in_reg} + {in_reg2[INPUT_BITS-1], in_reg2}; //sum the sample and the two old version Q2.25
wire signed [INPUT_BITS - 1 : 0] input_average = input_sum[INPUT_BITS : 1]; //divide by two Q1.25

wire signed [INPUT_BITS : 0] diff = {average_reg[INPUT_BITS-1], average_reg} - {out_del[INPUT_BITS-1], out_del}; //subtract feedback Q2.25
wire signed [(INPUT_BITS + MULTIPLIER_BITS) : 0] mult = diff * alpha_reg;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        alpha_reg <= 0;
        average_reg <= 0;
        out_del <= 0;
    end
    else if (in_valid) begin
        alpha_reg <= alpha;
        average_reg <= input_average;
        out_del <= out_feedback; 
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        acc_reg <= 0;
        acc_double <= 0;
    end
    else if (in_valid) begin 
        acc_reg <= acc_double + mult;
        acc_double <= acc_reg; 
    end
end

assign out = acc_reg[(INPUT_BITS + MULTIPLIER_BITS) -2 -: OUTPUT_BITS];
assign out_feedback = acc_reg[(INPUT_BITS + MULTIPLIER_BITS) -2 -: INPUT_BITS];


reg [LATENCY:0] valid_lat;

always @(posedge clk  or posedge rst) begin
    if (rst) begin
        valid_lat <= 0;
    end
    else if (in_valid) begin
        valid_lat <= {valid_lat[LATENCY-1 : 0], in_valid};   
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