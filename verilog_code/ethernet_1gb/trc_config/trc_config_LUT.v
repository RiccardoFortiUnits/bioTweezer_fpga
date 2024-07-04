module trc_config_LUT(

    input [5:0]			index,
    output reg [7:0]	address,
    output reg [31:0]	data,
    output reg          wr // 1 for write, 0 for read
);

    localparam      PMA_CH_NR = 7'h08,
                    PMA_STATUS = 7'h0A,
                    PMA_OFFSET = 7'h0B,
                    PMA_DATA = 7'h0C;

// LUT for configuring the TRC: explanations can be found in altera's guide. Every channel (Tx and Rx must be configured)
// example: 1 SFP = 2 channels (tx & rx)
// 2 SFP = 4 channels
// not all features are available: writing in a register not available, reports an error.
// about logical numer of channels, refer to the IP core

    always @(index)
    begin
        case(index)

            0 :
            begin
                address = PMA_STATUS; //Read bit 8 of control register until it is clear
                data = 32'h0000_0000;	// 
                wr = 1'b0;
            end
            
            1 : 
            begin
                address = PMA_CH_NR;	//Write channel number to be updated - channel 0
                data = 32'h0000_0000;	// 
                wr = 1'b1;
            end
            
            2 :
            begin
                address = PMA_OFFSET;	//Write Offset feature - VOD
                data = 32'h0000_0000;	// 
                wr = 1'b1;
            end
            
            3 :
            begin
                address = PMA_DATA;	//Write appropriate data related to VOD
                data = 32'h0000_000A;	// 
                wr = 1'b1;
            end

            4 :
            begin
                address = PMA_OFFSET;	//Write Offset feature - Pre-emphasis pre-tap
                data = 32'h0000_0001;	// 
                wr = 1'b1;
            end
            
            5 :
            begin
                address = PMA_DATA;	//Write appropriate data related to Pre-emphasis pre-tap
                data = 32'h0000_0000;	// 
                wr = 1'b1;
            end

            6 :
            begin
                address = PMA_OFFSET;	//Write Offset feature - Pre-emphasis first post-tap
                data = 32'h0000_0002;	// 
                wr = 1'b1;
            end
            
            7 :
            begin
                address = PMA_DATA;	//Write appropriate data related to Pre-emphasis first post-tap
                data = 32'h0000_0000;	// 
                wr = 1'b1;
            end

            8 :
            begin
                address = PMA_STATUS;	//Write bit "write" of status register
                data = 32'h0000_0001;	// 
                wr = 1'b1;
            end

            9 :
            begin
                address = PMA_STATUS; //Read bit 8 of control register until it is clear
                data = 32'h0000_0000;	// 
                wr = 1'b0;
            end


            10 : 
            begin
                address = PMA_CH_NR;	//Write channel number to be updated - channel 1
                data = 32'h0000_0001;	// 
                wr = 1'b1;
            end
            
            11 :
            begin
                address = PMA_OFFSET;	//Write Offset feature - VOD
                data = 32'h0000_0000;	// 
                wr = 1'b1;
            end
            
            12 :
            begin
                address = PMA_DATA;	//Write appropriate data related to VOD
                data = 32'h0000_000A;	// 
                wr = 1'b1;
            end

            13 :
            begin
                address = PMA_OFFSET;	//Write Offset feature - Pre-emphasis pre-tap
                data = 32'h0000_0001;	// 
                wr = 1'b1;
            end
            
            14 :
            begin
                address = PMA_DATA;	//Write appropriate data related to Pre-emphasis pre-tap
                data = 32'h0000_0000;	// 
                wr = 1'b1;
            end

            15 :
            begin
                address = PMA_OFFSET;	//Write Offset feature - Pre-emphasis first post-tap
                data = 32'h0000_0002;	// 
                wr = 1'b1;
            end
            
            16 :
            begin
                address = PMA_DATA;	//Write appropriate data related to Pre-emphasis first post-tap
                data = 32'h0000_0000;	// 
                wr = 1'b1;
            end

            17 :
            begin
                address = PMA_STATUS;	//Write bit "write" of status register
                data = 32'h0000_0001;	// 
                wr = 1'b1;
            end

            18 :
            begin
                address = PMA_STATUS; //Read bit 8 of control register until it is clear
                data = 32'h0000_0000;	// 
                wr = 1'b0;
            end


            default:
            begin
                address = PMA_STATUS;	//
                data = 32'h0000_0000;
                wr = 1'b0;
            end
                        
        endcase
    end
endmodule
