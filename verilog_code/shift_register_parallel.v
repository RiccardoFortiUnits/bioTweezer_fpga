//single bit shift register to implement a simple delay
module shift_register_parallel  #(
    parameter MAX_LENGTH = 32,	//Max delay length
	parameter BIT_WIDTH = 16 	//data bits
) (
	input		clock,
	input		reset,
	input		enable,	//When 1: data_in is written in the shift register and the "lenght"-1 times older data_in is set to the output
	input [ADDR_WIDTH-1:0]		length, //Minimum allowed length is 1 
	input [BIT_WIDTH-1:0]		data_in,
	output reg [BIT_WIDTH-1:0]	data_out
);

localparam ADDR_WIDTH = $clog2(MAX_LENGTH);

reg [BIT_WIDTH-1:0] shift_register [MAX_LENGTH-1:0];
//adv_pointer for the write and pointer for the read operations
always @(posedge clock ) begin
	if (reset) begin
		for (i=0; i<MAX_LENGTH; i=i+1) begin
			shift_register[i] <= {BIT_WIDTH{1'b0}};
		end		
		data_out <= 1'b0;
	end
	else if (enable) begin
		for (i=1; i<MAX_LENGTH; i=i+1) begin
			shift_register[i] <= shift_register[i-1];
		end
		shift_register[0] <= {BIT_WIDTH{1'b0}};
		
		if (length == 0) begin
			data_out <= 0;
		end
		else if (length == 1) begin
			data_out <= data_in;
		end
		else begin
			data_out <= shift_register[length-2];
		end
	end
end

endmodule
