//This is a single lockin module which outputs the X and Y coordinates
//The conversion to R(radius) and P(phase) must be done externally

//The signal_in, sin_ref, cos_ref and in_valid must be at the same frequency Fs
//The clk must be at 2*Fs (WITH A SYNCHRONOUS CLOCK TO THE ONE DRIVING THE DATA)

//the X_out, Y_out and out_valid must be sampled with the same clock driving the input

//the lockin module is >=250MHz capable (data in and out at 125 MHz)

//in_valid to out_valid latency at the Fs freq is 3 (is 5 with order 2)
//1 ser + 1 mult + 3 filt (+ 3 filt) + 2 deser = 7 (10) clock but this has to be /2 and floored

//`define SIMULATION

module lockin #(
    parameter   INPUT_BITS = 16, //assumed in Q1.INPUTBITS-1
                MULTIPLIER_BITS = 27, //same as coeff
                OUTPUT_BITS = 32, //assumed in Q1.OUTPUTBITS-1
                MULTIPLIER = 1
) (
    input                               clk,
    input                               rst,
    input                               filter_order, //0 for order 1, 1 for order 2
    input signed [INPUT_BITS -1 : 0]    signal_in,
    input signed [INPUT_BITS -1 : 0]    sin_ref,
    input signed [INPUT_BITS -1 : 0]    cos_ref,
    input                               in_valid,
    input signed [MULTIPLIER_BITS -1 : 0]   alpha,
    output signed [OUTPUT_BITS-1 : 0]   X_out,
    output signed [OUTPUT_BITS-1 : 0]   Y_out,
    output                              out_valid  
);


//Serializer for the reference signals (one cycle latency)

wire signed[INPUT_BITS -1 : 0] signal_ref;
wire signal_ref_valid;

serializer #(.WIDTH(INPUT_BITS), .FACTOR(2)) serializer_ref (
    .clk(clk),
    .rst(rst),
    .in({cos_ref, sin_ref}),
    .in_valid(in_valid),
    .out(signal_ref),
    .out_valid(signal_ref_valid)
);

//This samples the input signal giving a 1 clk latency to match the one of the serializer.
//The signal_in, beeing at half the clock rate of clk, is the same for two clock cycles.
//One can use another serializer with .in({signal_in, signal_in}), but this saves resources.

reg signed [INPUT_BITS -1 : 0] signal_in_reg;

always @(posedge clk  or posedge rst ) begin
    if (rst) begin
        signal_in_reg <= 0;
    end
    else begin
        signal_in_reg <= signal_in;     
    end
end

//Multiplier between the input signal and the reference signals
//The first is kept constant for two cycles and the later alternate between cos ans sin.
//This should use "half" a DSP block (one 18x18 multiplier), but this needs to be checked. 
//IN HIGH_SPEED mode there is an extra layer of register before the multiplication
wire signed [2*INPUT_BITS -1 : 0] mult_temp;
reg signed [2*INPUT_BITS -1 : 0] mult; //Q2.2*INPUTBITS-2
reg mult_valid;


assign mult_temp = signal_in_reg * signal_ref;  

always @(posedge clk or posedge rst ) begin
    if (rst) begin
        mult <= 0;
    end
    else begin
        mult <= mult_temp;    
    end
end

always @(posedge clk or posedge rst ) begin
    if (rst) begin
        mult_valid <= 0;
    end
    else begin   
        mult_valid <= signal_ref_valid;    
    end
end


//crop mult to fit in the multiplier input, this requires some saturation logic (to have Q1.xx format)
//the multiplication inputs are Q1.xx and so the product can range from -0.99... to 1
//if the result is 1 we crop it to 0.99...

wire signed [MULTIPLIER_BITS - 2 : 0] mult_cast; //Q1.25 (if MULTIPLIER_BITS=27)

generate
    if (2*INPUT_BITS > MULTIPLIER_BITS) begin
        assign mult_cast = (mult[2*INPUT_BITS -1 -: 2] == 2'b01)?
            {1'b0, {(MULTIPLIER_BITS-2){1'b1}}}:
            {mult[2*INPUT_BITS-1], mult[2*INPUT_BITS-3 -: MULTIPLIER_BITS-2]};
    end
    else begin
        assign mult_cast = (mult[2*INPUT_BITS -1 -: 2] == 2'b01)?
            {1'b0, {(MULTIPLIER_BITS-2){1'b1}}}:
            {mult[2*INPUT_BITS-1], mult[2*INPUT_BITS-3 : 0], {(MULTIPLIER_BITS-(2*INPUT_BITS-1)){1'b0}}};
    end
endgenerate

//use a 2-slow single pole IIR low pass filter

wire signed [OUTPUT_BITS - 1 : 0] filter_out1,filter_out2;
wire filter_out1_valid, filter_out2_valid;

tustin_lpf2 #(
    .INPUT_BITS(MULTIPLIER_BITS-1), //assumed in Q1.INPUTBITS-1
    .MULTIPLIER_BITS(MULTIPLIER_BITS), //same as coeff
    .OUTPUT_BITS(OUTPUT_BITS), //assumed in Q1.OUTPUTBITS-1                
    .MULTIPLIER(MULTIPLIER) //one for using multipliers, zero to use alpha as a shift
) iir_lpf1 (
    .clk(clk),
    .rst(rst),
    .in(mult_cast),
    .in_valid(mult_valid),
    .alpha(alpha),
    .out(filter_out1),
    .out_valid (filter_out1_valid)
);

tustin_lpf2 #(
    .INPUT_BITS(MULTIPLIER_BITS-1), //assumed in Q1.INPUTBITS-1
    .MULTIPLIER_BITS(MULTIPLIER_BITS), //same as coeff
    .OUTPUT_BITS(OUTPUT_BITS), //assumed in Q1.OUTPUTBITS-1                
    .MULTIPLIER(MULTIPLIER) //one for using multipliers, zero to use alpha as a shift
) iir_lpf2 (
    .clk(clk),
    .rst(rst),
    .in(filter_out1[(OUTPUT_BITS-1) -: (MULTIPLIER_BITS-1)]),
    .in_valid(filter_out1_valid),
    .alpha(alpha),
    .out(filter_out2),
    .out_valid (filter_out2_valid)
);

//Deserialize to obtain the X and Y outputs with the 2*FS clk but the data varies at FS clk

deserializer #(.WIDTH(OUTPUT_BITS), .FACTOR(2)) deserialize_out(
    .clk(clk),
    .rst(rst),
    .in(filter_order? filter_out2 : filter_out1),
    .in_valid(filter_order? filter_out2_valid : filter_out1_valid),
    .out({Y_out, X_out}),
    .out_valid(out_valid)  
);


`ifdef SIMULATION
    real signal_in_real, sin_ref_real, cos_ref_real, mult_real, mult_cast_real, alpha_real, filter_out_real, X_out_real, Y_out_real;
    always @* begin
        signal_in_real = (signal_in*(2.0**-(INPUT_BITS-1)));
        sin_ref_real = (sin_ref*(2.0**-(INPUT_BITS-1)));
        cos_ref_real = (cos_ref*(2.0**-(INPUT_BITS-1)));
        mult_real = (mult*(2.0**-(2*INPUT_BITS-2)));
        mult_cast_real = (mult_cast*(2.0**-(MULTIPLIER_BITS-2)));
        alpha_real = (alpha*(2.0**-(MULTIPLIER_BITS-1)));
        filter_out_real = (filter_out*(2.0**-(OUTPUT_BITS-1)));
        X_out_real = (X_out*(2.0**-(OUTPUT_BITS-1)));
        Y_out_real = (Y_out*(2.0**-(OUTPUT_BITS-1)));
    end
`endif 

endmodule