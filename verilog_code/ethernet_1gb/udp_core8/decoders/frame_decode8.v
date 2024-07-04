
module frame_decode8 # (
		//frame header length = 14 bytes, but mac interface works with multiple of 4
	parameter	AVL_SIZE = 8, //in bits
				AVL_WORDS = 14,
	 			REG_LENGTH = AVL_SIZE/8 *AVL_WORDS, //in bytes
				MAC_SIZE = 48,
				BYTE_SIZE = 8)

(

	input clk,
	input sync_reset,
	
	input [AVL_SIZE-1:0] data_in,
	input data_in_valid,
	
	output [MAC_SIZE-1:0] source_mac,
	output [MAC_SIZE-1:0] dest_mac,
	output [2*BYTE_SIZE-1:0] packet_type
);



reg [REG_LENGTH*8-1:0] decode_data = {(REG_LENGTH*8){1'b0}};

always @(posedge clk)
begin
	if(sync_reset == 1'b1)
	begin
		decode_data <= {(REG_LENGTH*8){1'b0}};
	end
	else
	begin
		if(data_in_valid == 1'b1)
		begin
			decode_data[REG_LENGTH*8-1:AVL_SIZE] <=  decode_data[REG_LENGTH*8-AVL_SIZE-1:0];
			decode_data[AVL_SIZE-1:0] <= data_in;
		end	
	end	
end

assign dest_mac = decode_data[REG_LENGTH*8-1 -: MAC_SIZE];
assign source_mac = decode_data[REG_LENGTH*8-MAC_SIZE-1 -: MAC_SIZE];
assign packet_type = decode_data[REG_LENGTH*8-2*MAC_SIZE-1 -: 2*BYTE_SIZE];


endmodule
