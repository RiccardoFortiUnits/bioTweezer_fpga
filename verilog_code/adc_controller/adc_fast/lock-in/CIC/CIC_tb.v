`timescale 1 ns/10 ps

module CIC_tb;

localparam N_input = 64

reg[3:0] read_data [0:N_input-1]

initial begin
    $readmemb("input_output_files/adder_data.txt", read_data);
    reset <= 1'b0;
    #50
    reset <= 1'b1;
end

always 
begin
    if (reset == 0) begin
        clk = 0;
    end
    else begin
        clk = 1'b1; 
        #10; // high for 20 * timescale = 20 ns
        clk = 1'b0;
        #10; // low for 20 * timescale = 20 ns
    end
end

integer index;
reg [16:0] data_in;
reg valid;

always @(posedge clk ) begin
    if (reset == 0) begin
        data_in <= 0;
        index <= 0;
        valid <= 1'b0
    end
    else begin
        valid <= 1'b1;
        if (index < N_input) begin
            index = index+1;
            data_in <= read_data[index];
        end
        else begin
            $stop
        end
    end
end

	CIC_lockin u0 (
		.clk       (clk),       //     clock.clk
		.reset_n   (1'b0),   //     reset.reset_n
		.in_error  (2'b00),  //  av_st_in.error
		.in_valid  (valid),  //          .valid
		.in_ready  (),  //          .ready
		.in_data   (data_in),   //          .in_data
		.out_data  (),  // av_st_out.out_data
		.out_error (), //          .error
		.out_valid (), //          .valid
		.out_ready (1'b1), //          .ready
		.rate      (2)       //      rate.conduit
	);
    
endmodule