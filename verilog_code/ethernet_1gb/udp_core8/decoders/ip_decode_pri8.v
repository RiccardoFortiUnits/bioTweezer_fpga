
module ip_decode_pri8 # (	
	//ip header length = 12 bytes
	parameter	AVL_SIZE = 8, //in bits
			AVL_WORDS = 12,
			REG_LENGTH = AVL_SIZE/8 *AVL_WORDS, //in bytes
			MAC_SIZE = 48,
			IP_SIZE = 32,
			BYTE_SIZE = 8)

	
(
	input clk,
	input sync_reset,
	
	input [AVL_SIZE-1:0] data_in,
	input data_in_valid,
	
	output [BYTE_SIZE/2-1:0] headerLength,
	output [BYTE_SIZE/2-1:0] headerVersion,
	output [BYTE_SIZE-1:0] dscp,
	output [2*BYTE_SIZE-1:0] totalLength,
	output [2*BYTE_SIZE-1:0] idCode,
	output [2:0] flags,
	output [12:0] fragmentOffset,
	output [BYTE_SIZE-1:0] timeToLive,
	output [BYTE_SIZE-1:0] protocol,
	output [2*BYTE_SIZE-1:0] checkSum,
	output [BYTE_SIZE/2-1:0] offset_count,
	
	output ip_header_valid

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

assign headerVersion = decode_data[REG_LENGTH*8-1 -: BYTE_SIZE/2];
assign headerLength = decode_data[REG_LENGTH*8-BYTE_SIZE/2-1 -: BYTE_SIZE/2];
assign dscp = decode_data[REG_LENGTH*8-2*BYTE_SIZE/2-1 -: BYTE_SIZE];

assign ip_header_valid = (headerVersion == 4'b0100) ? 1'b1 : 1'b0;

assign totalLength = decode_data[REG_LENGTH*8-2*BYTE_SIZE-1 -: 2*BYTE_SIZE];
assign idCode = decode_data[REG_LENGTH*8-4*BYTE_SIZE-1 -: 2*BYTE_SIZE];
assign flags = decode_data[REG_LENGTH*8-6*BYTE_SIZE-1 -: 3];
assign fragmentOffset = decode_data[REG_LENGTH*8-6*BYTE_SIZE-3-1 -: 13];
assign timeToLive = decode_data[REG_LENGTH*8-6*BYTE_SIZE-3-13-1 -: BYTE_SIZE];
assign protocol = decode_data[REG_LENGTH*8-7*BYTE_SIZE-3-13-1 -: BYTE_SIZE];
assign checkSum = decode_data[REG_LENGTH*8-8*BYTE_SIZE-3-13-1 -: 2*BYTE_SIZE];
// how many extra clocks we need (i.e. strip out the header)
assign  offset_count = headerLength - 4'd5; // header length - standard length (5 words of 32 bits)


endmodule
