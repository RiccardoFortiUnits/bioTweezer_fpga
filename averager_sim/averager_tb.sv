`timescale 1ns/1ns

module averager_tb;

  // Define parameters
    parameter FREQUENCY = 100000; // Frequency in Hz
    parameter AMPLITUDE = 1; // Amplitude of the sinusoid
    parameter OFFSET = -323;       // DC offset of the sinusoid
    parameter int SIM_TIME = 1000000;     // Simulation time in ns

    logic clk;
    logic rst;
    logic signed [15:0] sin_out, sin_out2;
    logic signed [31:0] filtered_output;
    logic filtered_output_valid;

    // Instantiate sinusoid generator
    sinusoid_gen sinusoid_gen_inst(
        .clk(clk),
        .rst(rst),
        .frequency(FREQUENCY),
        .amplitude(AMPLITUDE),
        .offset(OFFSET),
        .sin_out(sin_out)
    );

    ADC_data_moving_average dut2(
        .clock_100(clk),    
        .data_in(sin_out),
        .data_out(sin_out2)
    );

    averager #(
    .AVERAGING_POINTS_BITS(8),	//BITS for averaging_points (so max averaging factor (2^AVERAGING_POINTS_BITS)-1)
	.INPUT_DATA_BITS(32),		//BITS for the input data
	.SIGNED(1)					//1 for signed data_in
    )dut(
        .clock(clk),
        .reset(rst),
        .shift(1),
        .averaging_points( 8'd16),
        .data_in({{16{sin_out2[15]}},sin_out2}),
        .data_out(filtered_output),	
        .run_averaging(1'b1),
        .data_valid(filtered_output_valid)
    );

    logic signed [31:0] filtered_output_reg;
    always @(posedge clk ) begin
        if (filtered_output_valid) begin
            filtered_output_reg <= filtered_output;
        end
    end

    // Reset generation
    initial begin
        rst = 1;
        #20; // Wait for 20 ns
        rst = 0; // Release reset
    end

    always #5 clk = ~clk;

  // Initial block
    initial begin
        clk = 0;
        #10; // Wait for some time for signals to stabilize

        // Simulation loop
        repeat (SIM_TIME) begin
            #1; // Advance time by 1 ns
        end

        $finish; // End simulation
    end

endmodule

module sinusoid_gen (
    input logic clk,
    input logic rst,
    input real frequency,
    input real amplitude,
    input real offset,
    output logic signed [15:0] sin_out
);

    real phase = 0;
    real sin;
    real sin2;
    real sin3;
    logic signed [15:0] temp;

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            phase <= 0;
        else begin
            temp = $rtoi($realtime);
            phase = 2 * 3.14159 * frequency * $realtime /1000000000 + temp[3:0]/32;
        end
        sin_out <= amplitude * $signed($rtoi($sin(phase)*32765)) + offset;
        sin <= $sin(phase);
        sin2 <= $rtoi($sin(phase)*32765);
        sin3 <= $signed($rtoi($sin(phase)*32765));
    end
endmodule
