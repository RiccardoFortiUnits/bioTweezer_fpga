
module frame_encode8 # (
		//frame header length = 14 bytes, 1 (data_out) + 13 (encode_data)
	parameter	AVL_SIZE = 8, //in bits
				AVL_WORDS = 13,
	 			REG_LENGTH = AVL_SIZE/8 *AVL_WORDS, //in bytes
				MAC_SIZE = 48,
				BYTE_SIZE = 8)

(
	
	input clk,
	input sync_reset,

	input run,
	
	input [AVL_SIZE-1:0] data_in,
	
	input [MAC_SIZE-1:0] source_mac,
	input [MAC_SIZE-1:0] dest_mac,
	input [2*BYTE_SIZE-1:0] packet_type,

	output reg [AVL_SIZE-1:0] data_out


);

reg [REG_LENGTH*8-1:0] encode_data = {(REG_LENGTH*8){1'b0}};


always @(posedge clk)
begin
	if(sync_reset == 1'b1)
	begin
		data_out <= dest_mac[MAC_SIZE-1 -: AVL_SIZE];
		encode_data <= {dest_mac[MAC_SIZE-AVL_SIZE-1:0], source_mac, packet_type};

	end
	else if (run == 1'b1)
	begin
		data_out <= encode_data[REG_LENGTH*8-1 -: AVL_SIZE];
		encode_data[REG_LENGTH*8-1 -: REG_LENGTH*8-AVL_SIZE] <= encode_data[REG_LENGTH*8-AVL_SIZE-1 -: REG_LENGTH*8-AVL_SIZE];
		encode_data[AVL_SIZE-1:0] <= data_in; 
	end
end	



endmodule
