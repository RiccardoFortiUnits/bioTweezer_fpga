
module ip_encode8 # (
	//ip header length = 20 bytes, 1 (data_out) + 19 (encode_data)
	parameter	AVL_SIZE = 8, //in bits
				AVL_WORDS = 19,
	 			REG_LENGTH = AVL_SIZE/8 *AVL_WORDS, //in bytes
				MAC_SIZE = 48,
				IP_SIZE = 32,
				BYTE_SIZE = 8)
(

	input clk,
	input sync_reset,
	
	input run,
	
	input  [AVL_SIZE-1:0] data_in,

	input [2*BYTE_SIZE-1:0] packet_length,
	input [BYTE_SIZE-1:0] protocol,
	input [IP_SIZE-1:0] src_ip,
	input [IP_SIZE-1:0] dst_ip,

	output reg [AVL_SIZE-1:0] data_out

);

	
	reg [REG_LENGTH*8-1:0] encode_data = {(REG_LENGTH*8){1'b0}};

	wire [31:0] checksum_1;
	wire [31:0] checksum_2;
	wire [31:0] checksum_3;
	wire [15:0] checksum_result;
	
	
	// ip checksum calculation
    // done as a wrapped-overflow ones-complement
    //assign checksum_1 = 32'h00000501 + (24'h000000 & protocol) + (16'h0000 & packet_length); // sum of all static variables - including overlap
	// h0501 is h4500 + h4000 + h8000 
    assign checksum_1 = 32'h00000501 + {24'h000000, protocol} + {16'h0000, packet_length};
	 // max of above is h0000_0501 + h0000_00FF + h0000_FFFF = h0001_05FF
    
	 //assign checksum_2 = checksum_1 + (16'h0000 & src_ip[31:16]) + (16'h0000 & src_ip[15:0]);
	 assign checksum_2 = checksum_1 + {16'h0000, src_ip[31:16]} + {16'h0000, src_ip[15:0]};
    // max of above is h0001_05FF + h0000_FFFF + h0000_FFFF = h0003_05FD
    
	 //assign checksum_3 = checksum_2 + (16'h0000 & dst_ip[31:16]) + (16'h0000 & dst_ip[15:0]);
	 assign checksum_3 = checksum_2 + {16'h0000, dst_ip[31:16]} + {16'h0000, dst_ip[15:0]};
    // max of above is h0003_05FD + h0000_FFFF + h0000_FFFF = h0005_05FB
    // therefore a single addition should avoid wrapping
    
	 //assign checksum_result = not(checksum_3[15:0] + checksum_3[31:16]);
	assign checksum_result = ~(checksum_3[15:0] + checksum_3[31:16]);
	

//assign carry_out = {8'h45, 8'h00}; // ipv4, 5 32-bit words, dscp

always @ (posedge clk)
begin
	if(sync_reset == 1'b1)
	begin
		data_out <= 8'h45;
		encode_data <= {8'h00, packet_length, 16'h0000, 16'h4000, 8'h80, protocol, checksum_result, src_ip, dst_ip};
	end
	else if(run == 1'b1)
	begin
		data_out <= encode_data[REG_LENGTH*8-1 -: AVL_SIZE];
		encode_data[REG_LENGTH*8-1 -: REG_LENGTH*8-AVL_SIZE] <= encode_data[REG_LENGTH*8-AVL_SIZE-1 -: REG_LENGTH*8-AVL_SIZE];
		encode_data[AVL_SIZE-1:0] <= data_in;
	end
end



endmodule
