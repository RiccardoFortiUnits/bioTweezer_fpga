`timescale 1ns / 1ps

module serializer_tb;

  // Parameters
  parameter CLK_50MHZ_PERIOD = 20;  // 50 MHz clock period in ns
  parameter CLK_100MHZ_PERIOD = 10; // 100 MHz clock period in ns

  // Clocks and Reset
  logic clk_50MHz = 1;
  logic clk_100MHz = 1;
  logic rst = 1;

  // Sinusoids
  logic [31:0] in1 = 0;
  logic [31:0] in2 = 0;
  logic [31:0] out1, out2, out3, out4;  

  // Output
  reg [31:0] out, out_lpf;
  logic in_valid, out_valid, out_lpf_valid, out_valid1;

  integer outfile, outfile1, outfile2;

  // Module instantiation
  serializer #(.FACTOR(2)) uut (
    .clk(clk_100MHz),
    .rst(rst),
    .in({in1, in2}),
    .in_valid(in_valid),
    .out(out),
    .out_valid(out_valid)
  );

  logic [26:0] alpha = 1'b1<<22;

  tustin_lpf uut1(  
    .clk(clk_100MHz),
    .rst(rst),
    .in(out[26 : 0]),
    .in_valid(out_valid),
    .alpha(alpha),
    .out(out_lpf),
    .out_valid(out_lpf_valid)
  );

  deserializer #(.FACTOR(2)) uut2 (
    .clk_fast(clk_100MHz),
    .rst(rst),
    .in(out_lpf),
    .in_valid(out_lpf_valid),
    .out({out1, out2}),
    .out_valid(out_valid1)
  );

  // Clock generation
  initial forever #((CLK_50MHZ_PERIOD)/2) clk_50MHz = ~clk_50MHz;
  initial forever #((CLK_100MHZ_PERIOD)/2) clk_100MHz = ~clk_100MHz;

  always @(posedge clk_100MHz ) begin
    if (out_valid) begin
        $fdisplay(outfile,"%d",out); //write as decimal
    end
  end

  // Sinusoid generation and testbench logic
  initial begin
    // Initialize clocks and reset
    rst = 1;
    in_valid = 0;

    // Apply reset
    #81 rst = 0;

    in_valid = 1;
    outfile1=$fopen("sin_1MHz.txt","r");   //"r" means reading and "w" means writing
    outfile2=$fopen("sin_2MHz.txt","r");   //"r" means reading and "w" means writing
    outfile=$fopen("output.txt","w");
    //read line by line.
    while ((! $feof(outfile1)) && (! $feof(outfile2)) ) begin //read until an "end of file" is reached.
        
        //$fscanf(outfile1,"%d\n",in1); //scan each line and get the value as an hexadecimal, use %b for binary and %d for decimal.
        $fscanf(outfile2,"%d\n",in2); //scan each line and get the value as an hexadecimal, use %b for binary and %d for decimal.
        #(CLK_50MHZ_PERIOD); //wait some time as needed.
    end
    $fclose(outfile1);
    $fclose(outfile2);
    $fclose(outfile);
    in_valid = 0;

    // Run simulation for a duration
    #100;

    // Write output to a text file
    //$fopen("output.txt", "w");
    //$fwrite("output.txt", "%h\n", out);
    //$fclose;

    // Finish simulation
    $finish;
  end

endmodule
