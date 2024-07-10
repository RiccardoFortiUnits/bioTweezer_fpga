`timescale 1ns / 1ps

module cordic_tb;

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
  logic [31:0] out1, out2;  

  // Output
  wire [26:0] r, q;
  logic in_valid, out_valid, out_lpf_valid, out_valid1;

  integer outfile, outfile1, outfile2;

  // Module instantiation
  cordic uut (
    .areset(rst),
    .clk(clk_100MHz),
    .en(1'b1),
    .x(in1),
    .y(in2),
    .q(q),
    .r(r)
  );

  // Clock generation
  initial forever #((CLK_50MHZ_PERIOD)/2) clk_50MHz = ~clk_50MHz;
  initial forever #((CLK_100MHZ_PERIOD)/2) clk_100MHz = ~clk_100MHz;

  always @(posedge clk_100MHz ) begin
    $fdisplay(outfile,"%d",q); //write as decimal
  end

  // Sinusoid generation and testbench logic
  initial begin
    // Initialize clocks and reset
    rst = 1;

    // Apply reset
    #81 rst = 0;

    outfile1=$fopen("I_bin.txt","r");   //"r" means reading and "w" means writing
    outfile2=$fopen("Q_bin.txt","r");   //"r" means reading and "w" means writing
    outfile=$fopen("output.txt","w");
    //read line by line.
    while ((! $feof(outfile1)) && (! $feof(outfile2)) ) begin //read until an "end of file" is reached.
        
        $fscanf(outfile1,"%b\n",in1); //scan each line and get the value as an hexadecimal, use %b for binary and %d for decimal.
        $fscanf(outfile2,"%b\n",in2); //scan each line and get the value as an hexadecimal, use %b for binary and %d for decimal.
        #(CLK_50MHZ_PERIOD); //wait some time as needed.
    end
    $fclose(outfile1);
    $fclose(outfile2);
    $fclose(outfile);

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