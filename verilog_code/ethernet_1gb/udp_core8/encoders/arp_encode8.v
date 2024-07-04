
module arp_encode8 # (
	//arp header length = 28 bytes, 1 (data_out) + 27 (encode_data)
	parameter	AVL_SIZE = 8, //in bits
		AVL_WORDS = 27,
		REG_LENGTH = AVL_SIZE/8 *AVL_WORDS, //in bytes
		MAC_SIZE = 48,
		IP_SIZE = 32,
		BYTE_SIZE = 8)


(

	input clk,
	input sync_reset,
	
	input run,

	input [AVL_SIZE-1:0]				data_in,

	input [MAC_SIZE-1:0] sender_hardware_address,
	input [IP_SIZE-1:0] sender_protocol_address,
	input [MAC_SIZE-1:0] target_hardware_address,
	input [IP_SIZE-1:0] target_protocol_address,

	output reg [AVL_SIZE-1:0] 			data_out

	);

	//assign carry_out = 16'h0001; // hardware type (ethernet)

	reg [REG_LENGTH*8-1:0] encode_data = {(REG_LENGTH*8){1'b0}};

	always @(posedge clk)
	begin
		if(sync_reset == 1'b1)
		begin
			data_out <= 8'h00; //first byte of hw type
			encode_data <= {8'h01, 16'h0800, 8'h06, 8'h04, 16'h0002, sender_hardware_address, sender_protocol_address, target_hardware_address, target_protocol_address}; //second byte of hw type, protocol type (IP),  6 for mac (hardware len), 4 for ipv4 (protocol len)
		end
		
		else if(run == 1'b1)
		begin
			data_out <= encode_data[REG_LENGTH*8-1 -: AVL_SIZE];
			encode_data[REG_LENGTH*8-1 -: REG_LENGTH*8-AVL_SIZE] <= encode_data[REG_LENGTH*8-AVL_SIZE-1 -: REG_LENGTH*8-AVL_SIZE];
			encode_data[AVL_SIZE-1:0] <= data_in; 
		end
	end

	
endmodule
	