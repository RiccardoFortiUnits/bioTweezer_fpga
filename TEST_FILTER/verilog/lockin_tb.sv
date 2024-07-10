`timescale 1ns / 100ps

module lockin_tb;

  // Parameters
  parameter CLK_50MHZ_PERIOD = 20;  // 50 MHz clock period in ns
  parameter CLK_100MHZ_PERIOD = 10; // 100 MHz clock period in ns

  // Files
  integer X_out_file, Y_out_file, signal_in_file, cos_ref_file, sin_ref_file;


  // Clocks and Reset
  logic clk_50MHz = 1;
  logic clk_100MHz = 1;
  logic rst = 1;

   // Clock generation
  initial forever #((CLK_50MHZ_PERIOD)/2) clk_50MHz = ~clk_50MHz;
  initial forever #((CLK_100MHZ_PERIOD)/2) clk_100MHz = ~clk_100MHz;

  // Sinusoids
  logic [15:0] signal_in = 0;
  logic [15:0] sin_ref = 0;
  logic [15:0] cos_ref = 0;
  logic [31:0] X, Y;
  logic in_valid, out_valid;

  logic [26:0] alpha = 27'b000000000010110101000001000;

  lockin uut(
      .clk(clk_100MHz),
      .rst(rst),
      .signal_in(signal_in),
      .sin_ref(sin_ref),
      .cos_ref(cos_ref),
      .in_valid(in_valid),
      .filter_order(0),
      .alpha(alpha),
      .X_out(X),
      .Y_out(Y),
      .out_valid (out_valid)
  );

  reg [31:0] X_reg, Y_reg;

  always @(posedge clk_50MHz) begin
      if (rst) begin
          X_reg <= 0;
          Y_reg <= 0;
      end
      else if (out_valid) begin
          X_reg <= X;
          Y_reg <= Y;
      end
  end

  always @(posedge clk_50MHz ) begin
    if (out_valid) begin
        $fdisplay(X_out_file,"%d",X); //write as decimal
        $fdisplay(Y_out_file,"%d",Y); //write as decimal
    end
  end

  // Sinusoid generation and testbench logic
  initial begin
    
    // Initialize clocks and reset
    rst = 1;
    in_valid = 0;

    #80
    
    rst = 0;

    #41
    in_valid = 1;

    signal_in_file=$fopen("../../lockin_signal_in.txt","r");   //"r" means reading and "w" means writing
    cos_ref_file=$fopen("../../lockin_cos_ref.txt","r");   //"r" means reading and "w" means writing
    sin_ref_file=$fopen("../../lockin_sin_ref.txt","r");
    X_out_file=$fopen("../../lockin_X_out.txt","w");
    Y_out_file=$fopen("../../lockin_Y_out.txt","w");
    //read line by line.
    while ((! $feof(signal_in_file)) & (! $feof(cos_ref_file)) & (! $feof(sin_ref_file))) begin //read until an "end of file" is reached.
        $fscanf(signal_in_file,"%b\n",signal_in); //scan each line and get the value as an hexadecimal, use %b for binary and %d for decimal.
        $fscanf(cos_ref_file,"%b\n",cos_ref); //scan each line and get the value as an hexadecimal, use %b for binary and %d for decimal.
        $fscanf(sin_ref_file,"%b\n",sin_ref); //scan each line and get the value as an hexadecimal, use %b for binary and %d for decimal.
        
        #(CLK_50MHZ_PERIOD); //wait some time as needed.
    end

    in_valid = 0;
    // Run simulation for a duration
    #1000;
    $fclose(X_out_file);
    $fclose(Y_out_file);
    $fclose(signal_in_file);
    $fclose(cos_ref_file);
    $fclose(sin_ref_file);

    // Finish simulation
    $finish;
  end

endmodule
