
module udp_encode8 # (
	//udp header length = 8 bytes, 1 (data_out) + 7 (encode_data)
	 	parameter	AVL_SIZE = 8, //in bits
				AVL_WORDS = 7,
	 			REG_LENGTH = AVL_SIZE/8 *AVL_WORDS, //in bytes
				MAC_SIZE = 48,
				IP_SIZE = 32,
				BYTE_SIZE = 8)

(

	input clk,
	input sync_reset,
	
	input run,
	
	input [AVL_SIZE-1:0] data_in,
	
	input [2*BYTE_SIZE-1:0] src_port,
	input [2*BYTE_SIZE-1:0] dst_port,
	input [2*BYTE_SIZE-1:0] packet_length,
	input [2*BYTE_SIZE-1:0] checksum,

	output reg [AVL_SIZE-1:0] data_out
);


reg [REG_LENGTH*8-1:0] encode_data = {(REG_LENGTH*8){1'b0}};


always @ (posedge clk)
begin
	if(sync_reset == 1'b1)
	begin
		data_out <= src_port[2*BYTE_SIZE-1 -: BYTE_SIZE]; //first byte of src port
		encode_data <= {src_port[2*BYTE_SIZE-BYTE_SIZE-1 -: BYTE_SIZE], dst_port, packet_length + 16'h0008, checksum}; //second byte of src port, dest port, length, checksum 
	end
	else if(run == 1'b1)
	begin
			data_out <= encode_data[REG_LENGTH*8-1 -: AVL_SIZE];
			encode_data[REG_LENGTH*8-1 -: REG_LENGTH*8-AVL_SIZE] <= encode_data[REG_LENGTH*8-AVL_SIZE-1 -: REG_LENGTH*8-AVL_SIZE];
			encode_data[AVL_SIZE-1:0] <= data_in; 
	end	
	end

endmodule
	