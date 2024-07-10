module dac_filter #(
    parameter   INPUT_BITS = 16, //assumed in Q1.INPUTBITS-1
                MULTIPLIER_BITS = 27, //same as coeff
                OUTPUT_BITS = 32, //assumed in Q1.OUTPUTBITS-1
                MULTIPLIER = 1
) (
    input                               clk,
    input                               rst,
    input signed [INPUT_BITS -1 : 0]    signal_in,
    input                               in_valid,
    input signed [MULTIPLIER_BITS -1 : 0]   alpha,
    output signed [15 : 0]   X_out,
    output signed [15 : 0]   Y_out,
    output                              out_valid  
);

reg signed [MULTIPLIER_BITS - 2 : 0] iir1_input, iir2_input,iir3_input,iir4_input;
reg mux;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        iir1_input <= 0;
        mux <= 1'b0;
    end
    else if (in_valid) begin
        if (mux == 0) begin
            iir1_input <= {signal_in, 10'd0};
            iir2_input <= iir1_out_reg[(OUTPUT_BITS-1) -: (MULTIPLIER_BITS-1)];
            iir3_input <= iir2_out_reg[(OUTPUT_BITS-1) -: (MULTIPLIER_BITS-1)];
            iir4_input <= iir3_out_reg[(OUTPUT_BITS-1) -: (MULTIPLIER_BITS-1)];
            mux <= 1'b1;
        end
        if (mux == 1) begin
            iir1_input <= iir1_out_reg[(OUTPUT_BITS-1) -: (MULTIPLIER_BITS-1)];
            iir2_input <= iir2_out_reg[(OUTPUT_BITS-1) -: (MULTIPLIER_BITS-1)];
            iir3_input <= iir3_out_reg[(OUTPUT_BITS-1) -: (MULTIPLIER_BITS-1)];
            iir4_input <= iir4_out_reg[(OUTPUT_BITS-1) -: (MULTIPLIER_BITS-1)];
            mux <= 1'b0;
        end
    end
end



wire signed [OUTPUT_BITS - 1 : 0] iir1_out,iir2_out,iir3_out,iir4_out;
wire iir1_out_valid, iir2_out_valid, iir3_out_valid, iir4_out_valid;


reg signed [OUTPUT_BITS - 1 : 0] iir1_out_reg_temp,iir2_out_reg_temp,iir3_out_reg_temp,iir4_out_reg_temp;
reg signed [OUTPUT_BITS - 1 : 0] iir1_out_reg,iir2_out_reg,iir3_out_reg,iir4_out_reg;


// //USING THE SAME IMPLEMENTATION AS THE LOCKINS

// tustin_lpf2_duplicate #(
//     .INPUT_BITS(MULTIPLIER_BITS-1), //assumed in Q1.INPUTBITS-1
//     .MULTIPLIER_BITS(MULTIPLIER_BITS), //same as coeff
//     .OUTPUT_BITS(OUTPUT_BITS) //assumed in Q1.OUTPUTBITS-1                
//     //.MULTIPLIER(MULTIPLIER) //one for using multipliers, zero to use alpha as a shift
// ) lpf1 (
//     .clk(clk),
//     .rst(rst),
//     .in(iir1_input),
//     .in_valid(1'b1),
//     .alpha(alpha),
//     .out(iir1_out),
//     .out_valid (iir1_out_valid)
// );

// tustin_lpf2_duplicate #(
//     .INPUT_BITS(MULTIPLIER_BITS-1), //assumed in Q1.INPUTBITS-1
//     .MULTIPLIER_BITS(MULTIPLIER_BITS), //same as coeff
//     .OUTPUT_BITS(OUTPUT_BITS) //assumed in Q1.OUTPUTBITS-1                
//     //.MULTIPLIER(MULTIPLIER) //one for using multipliers, zero to use alpha as a shift
// ) lpf2 (
//     .clk(clk),
//     .rst(rst),
//     .in(iir2_input),
//     .in_valid(1'b1),
//     .alpha(alpha),
//     .out(iir2_out),
//     .out_valid (iir2_out_valid)
// );

// tustin_lpf2_duplicate #(
//     .INPUT_BITS(MULTIPLIER_BITS-1), //assumed in Q1.INPUTBITS-1
//     .MULTIPLIER_BITS(MULTIPLIER_BITS), //same as coeff
//     .OUTPUT_BITS(OUTPUT_BITS) //assumed in Q1.OUTPUTBITS-1                
//     //.MULTIPLIER(MULTIPLIER) //one for using multipliers, zero to use alpha as a shift
// ) lpf3 (
//     .clk(clk),
//     .rst(rst),
//     .in(iir3_input),
//     .in_valid(1'b1),
//     .alpha(alpha),
//     .out(iir3_out),
//     .out_valid (iir3_out_valid)
// );

// tustin_lpf2_duplicate #(
//     .INPUT_BITS(MULTIPLIER_BITS-1), //assumed in Q1.INPUTBITS-1
//     .MULTIPLIER_BITS(MULTIPLIER_BITS), //same as coeff
//     .OUTPUT_BITS(OUTPUT_BITS) //assumed in Q1.OUTPUTBITS-1                
//     //.MULTIPLIER(MULTIPLIER) //one for using multipliers, zero to use alpha as a shift
// ) lpf4 (
//     .clk(clk),
//     .rst(rst),
//     .in(iir4_input),
//     .in_valid(1'b1),
//     .alpha(alpha),
//     .out(iir4_out),
//     .out_valid (iir4_out_valid)
// ); 

// always @(posedge clk or posedge rst) begin
//     if (rst) begin
//         iir1_out_reg <= 0;
//         iir2_out_reg <= 0;
//         iir3_out_reg <= 0;
//         iir4_out_reg <= 0;
//     end
//     else begin
//         iir1_out_reg <= iir1_out;
//         iir2_out_reg <= iir2_out;
//         iir3_out_reg <= iir3_out;
//         iir4_out_reg <= iir4_out;
//     end
// end

// USING THE OLDER LPF

tustin_lpf #(
    .INPUT_BITS(MULTIPLIER_BITS-1), //assumed in Q1.INPUTBITS-1
    .MULTIPLY_BITS(MULTIPLIER_BITS), //same as coeff
    .OUTPUT_BITS(OUTPUT_BITS) //assumed in Q1.OUTPUTBITS-1               
) iir_lpf1 (
    .clk(clk),
    .rst(rst),
    .in(iir1_input),
    .in_valid(1'b1),
    .alpha(alpha),
    .out(iir1_out),
    .out_valid (iir1_out_valid)
);

tustin_lpf #(
    .INPUT_BITS(MULTIPLIER_BITS-1), //assumed in Q1.INPUTBITS-1
    .MULTIPLY_BITS(MULTIPLIER_BITS), //same as coeff
    .OUTPUT_BITS(OUTPUT_BITS) //assumed in Q1.OUTPUTBITS-1               
) iir_lpf2 (
    .clk(clk),
    .rst(rst),
    .in(iir2_input),
    .in_valid(1'b1),
    .alpha(alpha),
    .out(iir2_out),
    .out_valid (iir2_out_valid)
);

tustin_lpf #(
    .INPUT_BITS(MULTIPLIER_BITS-1), //assumed in Q1.INPUTBITS-1
    .MULTIPLY_BITS(MULTIPLIER_BITS), //same as coeff
    .OUTPUT_BITS(OUTPUT_BITS) //assumed in Q1.OUTPUTBITS-1               
) iir_lpf3 (
    .clk(clk),
    .rst(rst),
    .in(iir3_input),
    .in_valid(1'b1),
    .alpha(alpha),
    .out(iir3_out),
    .out_valid (iir3_out_valid)
);

tustin_lpf #(
    .INPUT_BITS(MULTIPLIER_BITS-1), //assumed in Q1.INPUTBITS-1
    .MULTIPLY_BITS(MULTIPLIER_BITS), //same as coeff
    .OUTPUT_BITS(OUTPUT_BITS) //assumed in Q1.OUTPUTBITS-1               
) iir_lpf4 (
    .clk(clk),
    .rst(rst),
    .in(iir4_input),
    .in_valid(1'b1),
    .alpha(alpha),
    .out(iir4_out),
    .out_valid (iir4_out_valid)
);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        iir1_out_reg <= 0;
        iir2_out_reg <= 0;
        iir3_out_reg <= 0;
        iir4_out_reg <= 0;
        iir1_out_reg_temp <= 0;
        iir2_out_reg_temp <= 0;
        iir3_out_reg_temp <= 0;
        iir4_out_reg_temp <= 0;
    end
    else begin
        iir1_out_reg_temp <= iir1_out;
        iir2_out_reg_temp <= iir2_out;
        iir3_out_reg_temp <= iir3_out;
        iir4_out_reg_temp <= iir4_out;
        iir1_out_reg <= iir1_out_reg_temp;
        iir2_out_reg <= iir2_out_reg_temp;
        iir3_out_reg <= iir3_out_reg_temp;
        iir4_out_reg <= iir4_out_reg_temp;
    end
end

//Deserialize to obtain the X and Y outputs with the 2*FS clk but the data varies at FS clk

wire [(OUTPUT_BITS-1) : 0] Y_out_temp, X_out_temp;
deserializer #(.WIDTH(OUTPUT_BITS), .FACTOR(2)) deserialize_out(
    .clk(clk),
    .rst(rst),
    .in(iir4_out_reg),
    .in_valid(in_valid),
    .out({Y_out_temp, X_out_temp}),
    .out_valid(out_valid)  
);

assign X_out = X_out_temp[(OUTPUT_BITS-1) -: 16];
assign Y_out = Y_out_temp[(OUTPUT_BITS-1) -: 16];

endmodule