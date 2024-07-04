
module ip_decode_sec8 # (
		parameter	AVL_SIZE = 8, //in bits
			AVL_WORDS = 8,
			REG_LENGTH = AVL_SIZE/8 *AVL_WORDS, //in bytes
			MAC_SIZE = 48,
			IP_SIZE = 32,
			BYTE_SIZE = 8)

	//parameter IP_SEC_HEADER_LENGTH = 8; 

(
	input clk,
	input sync_reset,
	
	input data_in_valid,
	input [AVL_SIZE-1:0] data_in,
	
	output [IP_SIZE-1:0] src_ip,
	output [IP_SIZE-1:0] dst_ip

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

assign src_ip = decode_data[REG_LENGTH*8-1 -: IP_SIZE];
assign dst_ip = decode_data[REG_LENGTH*8-IP_SIZE-1 -: IP_SIZE];

endmodule
