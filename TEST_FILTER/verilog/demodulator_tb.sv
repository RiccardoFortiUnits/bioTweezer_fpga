`timescale 1ns / 1ps

module demodulator_tb;

// Parameters
parameter CLK_50MHZ_PERIOD = 20;  // 50 MHz clock period in ns
parameter CLK_100MHZ_PERIOD = 10; // 100 MHz clock period in ns

// Clocks and Reset
logic clk_50MHz = 1;
logic clk_100MHz = 1;
logic rst = 1;

// Sinusoids
logic [15:0] in, cos, sin;

// Output
reg [31:0] out;
logic outvalid;

integer infile, cosfile, sinfile;
integer outfile;

// Module instantiation
demodulator uut (
  .clk(clk_100MHz),
  .rst(rst),
  .signal_in(in),
  .cos(cos),
  .sin(sin),
  .out(out),
  .out_valid(out_valid)
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

  // Apply reset
  #10 rst = 0;

  infile=$fopen("signalin.txt","r");   //"r" means reading and "w" means writing
  cosfile=$fopen("cos.txt","r");   //"r" means reading and "w" means writing
  sinfile=$fopen("sin.txt","r");   //"r" means reading and "w" means writing
  outfile=$fopen("output.txt","w");
  //read line by line.
  while (! $feof(infile)) begin //read until an "end of file" is reached.
      $fscanf(infile,"%d\n",in); //scan each line and get the value as an hexadecimal, use %b for binary and %d for decimal.
      $fscanf(cosfile,"%d\n",cos); //scan each line and get the value as an hexadecimal, use %b for binary and %d for decimal.
      $fscanf(sinfile,"%d\n",sin); //scan each line and get the value as an hexadecimal, use %b for binary and %d for decimal.
      #(CLK_50MHZ_PERIOD); //wait some time as needed.
  end

  $fclose(infile);
  $fclose(cosfile);
  $fclose(sinfile);
  $fclose(outfile);

  // Write output to a text file
  //$fopen("output.txt", "w");
  //$fwrite("output.txt", "%h\n", out);
  //$fclose;

  // Finish simulation
  $finish;
end

endmodule
