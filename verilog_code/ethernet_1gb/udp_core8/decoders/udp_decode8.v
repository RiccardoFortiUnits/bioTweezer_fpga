
module udp_decode8 # (
			//udp header length = 8 bytes
		parameter	AVL_SIZE = 8, //in bits
			AVL_WORDS = 8,
			REG_LENGTH = AVL_SIZE/8 *AVL_WORDS, //in bytes
			MAC_SIZE = 48,
			IP_SIZE = 32,
			BYTE_SIZE = 8)

(
	input clk,
	input sync_reset,
	
	input data_in_valid,
	input [AVL_SIZE-1:0] data_in,
	
	output [2*BYTE_SIZE-1:0] src_port,
	output [2*BYTE_SIZE-1:0] dst_port,
	output [2*BYTE_SIZE-1:0] checksum,
	output [2*BYTE_SIZE-1:0] length

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

	
	assign src_port = decode_data[REG_LENGTH*8-1 -: 2*BYTE_SIZE];
	assign dst_port = decode_data[REG_LENGTH*8-2*BYTE_SIZE-1 -: 2*BYTE_SIZE];
	assign length = decode_data[REG_LENGTH*8-4*BYTE_SIZE-1 -: 2*BYTE_SIZE] - 16'h0008; //subtract length of udp header
	assign checksum = decode_data[REG_LENGTH*8-6*BYTE_SIZE-1 -: 2*BYTE_SIZE];


	endmodule
