
module arp_decode8 # (	
		//arp protocol length = 28 bytes
	parameter	AVL_SIZE = 8, //in bits
			AVL_WORDS = 28,
			REG_LENGTH = AVL_SIZE/8 *AVL_WORDS, //in bytes
			MAC_SIZE = 48,
			IP_SIZE = 32,
			BYTE_SIZE = 8)


(
input								sync_reset,
input								clk,

input [AVL_SIZE-1:0]				data_in,
input								data_in_valid,

output [2*BYTE_SIZE-1:0]		hardware_type,
output [2*BYTE_SIZE-1:0]		protocol_type,
output [BYTE_SIZE-1:0]			hardware_len,
output [BYTE_SIZE-1:0]			protocol_len,
output [2*BYTE_SIZE-1:0]		operation,
output [MAC_SIZE-1:0]			sender_hardware_address,
output [IP_SIZE-1:0]			sender_protocol_address,
output [MAC_SIZE-1:0]			target_hardware_address,
output [IP_SIZE-1:0]			target_protocol_address,

output 						decode_valid

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

assign decode_valid = (hardware_len == 8'h06  /*MAC*/
						&& protocol_len == 8'h04 /*IPv4*/
						&& hardware_type == 16'h0001 /* ethernet */
						&& protocol_type == 16'h0800 /*IP*/  ) ? 1'b1 : 1'b0; 
						
						
assign hardware_type = decode_data[REG_LENGTH*8-1 -: 2*BYTE_SIZE];
assign protocol_type = decode_data[REG_LENGTH*8-2*BYTE_SIZE-1 -: 2*BYTE_SIZE];
assign hardware_len = decode_data[REG_LENGTH*8-2*BYTE_SIZE-2*BYTE_SIZE-1 -: BYTE_SIZE];
assign protocol_len = decode_data[REG_LENGTH*8-2*BYTE_SIZE-2*BYTE_SIZE-BYTE_SIZE-1 -: BYTE_SIZE];
assign operation = decode_data[REG_LENGTH*8-2*BYTE_SIZE-2*BYTE_SIZE-2*BYTE_SIZE-1 -: 2*BYTE_SIZE];
assign sender_hardware_address = decode_data[REG_LENGTH*8-2*BYTE_SIZE-2*2*BYTE_SIZE-2*BYTE_SIZE-1 -: MAC_SIZE];
assign sender_protocol_address = decode_data[REG_LENGTH*8-2*BYTE_SIZE-2*2*BYTE_SIZE-2*BYTE_SIZE-MAC_SIZE-1 -: IP_SIZE];
assign target_hardware_address = decode_data[REG_LENGTH*8-2*BYTE_SIZE-2*2*BYTE_SIZE-2*BYTE_SIZE-MAC_SIZE-IP_SIZE-1 -: MAC_SIZE];
assign target_protocol_address = decode_data[REG_LENGTH*8-2*BYTE_SIZE-2*2*BYTE_SIZE-2*BYTE_SIZE-2*MAC_SIZE-IP_SIZE-1 -: IP_SIZE];
	

	
	
endmodule
