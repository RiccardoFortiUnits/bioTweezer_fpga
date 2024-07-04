
module icmp_encode8 # (
	//icmp header length = 4 bytes, 1 (data_out) + 3 (encode_data)
		parameter	AVL_SIZE = 8, //in bits
			AVL_WORDS = 3,
			REG_LENGTH = AVL_SIZE/8 *AVL_WORDS, //in bytes
			MAC_SIZE = 48,
			IP_SIZE = 32,
			BYTE_SIZE = 8)
(

	input clk,
	input sync_reset,
	
	input run,
	
	input [AVL_SIZE-1:0] data_in,

	input [BYTE_SIZE-1:0] icmp_type,
	input [BYTE_SIZE-1:0] code,
	input [2*BYTE_SIZE-1:0] checksum,

	output reg [AVL_SIZE-1:0] data_out
);


reg [REG_LENGTH*8-1:0] encode_data = {(REG_LENGTH*8){1'b0}};


always @(posedge clk)
begin
	if(sync_reset == 1'b1)
	begin
		data_out <= icmp_type;
		encode_data <= {code, checksum};
	end
	else if (run == 1'b1)
	begin
		data_out <= encode_data[REG_LENGTH*8-1 -: AVL_SIZE];
		encode_data[REG_LENGTH*8-1 -: REG_LENGTH*8-AVL_SIZE] <= encode_data[REG_LENGTH*8-AVL_SIZE-1 -: REG_LENGTH*8-AVL_SIZE];
		encode_data[AVL_SIZE-1:0] <= data_in; 
	end
end	

endmodule
