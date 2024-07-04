
module icmp_decode8 # (
	//icmp header length = 4 bytes
		parameter	AVL_SIZE = 8, //in bits
			AVL_WORDS = 4,
			REG_LENGTH = AVL_SIZE/8 *AVL_WORDS, //in bytes
			MAC_SIZE = 48,
			IP_SIZE = 32,
			BYTE_SIZE = 8)

(
	input clk,
	input sync_reset,
	
	input data_in_valid,
	input [AVL_SIZE-1:0] data_in,
	
	output [BYTE_SIZE-1:0] icmp_type,
	output [BYTE_SIZE-1:0] code,
	output [2*BYTE_SIZE-1:0] checksum

);

reg [REG_LENGTH*8-1:0] decode_data = {(REG_LENGTH*8){1'b0}};

always @ (posedge clk)
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


assign icmp_type = decode_data[REG_LENGTH*8-1 -: BYTE_SIZE];
assign code = decode_data[REG_LENGTH*8-BYTE_SIZE-1 -: BYTE_SIZE];
assign checksum = decode_data[REG_LENGTH*8-2*BYTE_SIZE-1 -: 2*BYTE_SIZE];


endmodule
