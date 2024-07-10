`timescale 1ns / 1ps

module lpf_tb;

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
  reg [31:0] out, out_lpf, out_lpf1;
  logic in_valid, out_valid, out_lpf_valid,out_lpf_valid1, out_valid1;

  integer outfile1, outfile2, infile1, infile2;

  // Module instantiation
  serializer #(.FACTOR(2)) uut (
    .clk(clk_100MHz),
    .rst(rst),
    .in({in2, in1}),
    .in_valid(in_valid),
    .out(out),
    .out_valid(out_valid)
  );

  logic [26:0] alpha = 27'b0_00000000000000000000000001;

  tustin_lpf2 #(.INPUT_BITS(26)) uut1(  
    .clk(clk_100MHz),
    .rst(rst),
    .in(out[26 : 0]),
    .in_valid(out_valid),
    .alpha(alpha),
    .out(out_lpf),
    .out_valid(out_lpf_valid)
  );

  tustin_lpf2 #(.INPUT_BITS(26), .MULTIPLIER(0))uut3(  
    .clk(clk_100MHz),
    .rst(rst),
    .in(out[26 : 0]),
    .in_valid(out_valid),
    .alpha(2),
    .out(out_lpf1),
    .out_valid(out_lpf_valid1)
  );

  deserializer #(.FACTOR(2)) uut2 (
    .clk_fast(clk_100MHz),
    .rst(rst),
    .in(out_lpf),
    .in_valid(out_lpf_valid),
    .out({out2, out1}),
    .out_valid(out_valid1)
  );

  // Clock generation
  initial forever #((CLK_50MHZ_PERIOD)/2) clk_50MHz = ~clk_50MHz;
  initial forever #((CLK_100MHZ_PERIOD)/2) clk_100MHz = ~clk_100MHz;

  always @(posedge clk_50MHz ) begin
    if (out_valid1) begin
        $fdisplay(outfile1,"%d",out1); //write as decimal
        $fdisplay(outfile2,"%d",out2); //write as decimal
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
    // outfile1=$fopen("sin_comp.txt","r");   //"r" means reading and "w" means writing
    // outfile2=$fopen("cos_comp.txt","r");   //"r" means reading and "w" means writing
    // outfile=$fopen("output_lpf.txt","w");
    infile1=$fopen("../../I_bin.txt","r");   //"r" means reading and "w" means writing
    infile2=$fopen("../../Q_bin.txt","r");   //"r" means reading and "w" means writing
    outfile1=$fopen("../../I_lpf.txt","w");
    outfile2=$fopen("../../Q_lpf.txt","w");
    //read line by line.
    while ((! $feof(infile1)) & (! $feof(infile2))) begin //read until an "end of file" is reached.
        $fscanf(infile1,"%b\n",in1); //scan each line and get the value as an hexadecimal, use %b for binary and %d for decimal.
        $fscanf(infile2,"%b\n",in2); //scan each line and get the value as an hexadecimal, use %b for binary and %d for decimal.
        
        #(CLK_50MHZ_PERIOD); //wait some time as needed.
    end
    in_valid = 0;

    // Run simulation for a duration
    #100;
    $fclose(outfile1);
    $fclose(outfile2);
    $fclose(infile1);
    $fclose(infile2);

    // Write output to a text file
    //$fopen("output.txt", "w");
    //$fwrite("output.txt", "%h\n", out);
    //$fclose;

    // Finish simulation
    $finish;
  end

endmodule
