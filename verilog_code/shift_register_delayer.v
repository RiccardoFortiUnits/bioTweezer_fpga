//single bit shift register to implement a simple delay
module shift_register_delayer  #(
    parameter MAX_LENGTH = 1024	//Max delay length
) (
	input		clock,
	input		reset,
	input		enable,	//When 1: data_in is written in the shift register and the "lenght"-1 times older data_in is set to the output
	input [ADDR_WIDTH-1:0]	length, //Minimum allowed length is 1 
	input 		data_in,
	output reg	data_out
);

localparam ADDR_WIDTH = $clog2(MAX_LENGTH);

reg [MAX_LENGTH-1:0] shift_register;
//adv_pointer for the write and pointer for the read operations
always @(posedge clock ) begin
	if (reset) begin
		shift_register <= {MAX_LENGTH{1'b0}};
		data_out <= 1'b0;
	end
	else if (enable) begin
		shift_register[MAX_LENGTH-1:1] <= shift_register[MAX_LENGTH-2:0];
		shift_register[0] <= data_in;
		if (length == 0) begin
			data_out <= 1'b0;
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
