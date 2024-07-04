module udp_delayer8 # (
	parameter	AVL_SIZE = 8, //in bits
				BYTE_SIZE = 8)
(

	input clk,
	input sync_reset,
	
	input dvalid_in,
 	
	input  [AVL_SIZE-1:0] data_in,

	output reg [AVL_SIZE-1:0] data_out,
    output reg dvalid_out

);


always @(posedge clk)
begin
    data_out <= data_in;
	dvalid_out <= dvalid_in;
end




endmodule
