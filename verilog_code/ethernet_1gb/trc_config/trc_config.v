`include "trc_config_LUT.v"

module 	trc_config 	(
    
        input				clock,
        input				reset,
        input				start,
        output reg			finish_trc,	
        
        input						avl_busy,
        input [31:0]			avl_readdata,
        output wire [7:0]		avl_address,
        output wire [31:0]	avl_writedata,
        output reg				avl_read_req,
        output reg				avl_write_req
        

);

parameter LENGTH = 8'd19;       //length of LUT + 1

reg [7:0] 	index 	= 8'd0;	

localparam 	IDLE 	= 3'd0,
                RD	= 3'd1,
                WR 	= 3'd2,
                STOP 	= 3'd3,
                START = 3'd4; 
                
reg [2:0] 	STATE_TRC = IDLE;


reg start_1, start_2;

always @(posedge clock ) begin
    start_2 <= start_1;
    start_1 <= start;
end
    

wire wr;

    trc_config_LUT trc_config_LUT_0 (
        .index(index),
        .data(avl_writedata),
        .address(avl_address),
        .wr(wr)
    );
    
    always @(posedge clock)
    begin
        if(reset)
        begin
            avl_read_req <= 1'b0;
            avl_write_req <= 1'b0;
            index <= 8'd0;
            finish_trc <= 1'b0;
            STATE_TRC <= IDLE;
        end
        else
        begin
            case(STATE_TRC)
            
            IDLE:
            begin
                if(start_2)
                begin
                    STATE_TRC <= START;
                    index <= 8'd0;
                end
                else
                begin
                    finish_trc <= 1'b0;
                    STATE_TRC <= IDLE;
                end
            end
            
            START:
            begin
                if(wr)
                begin
                    avl_write_req <= 1'b1;
                    avl_read_req <= 1'b0;
                    STATE_TRC <= WR;
                end
                else
                begin
                    avl_read_req <= 1'b1;
                    avl_write_req <= 1'b0;
                    STATE_TRC <= RD;
                end
            end
            
            WR:
            begin
                if(!avl_busy)
                begin
                    avl_write_req <= 1'b0;
                    if(index == LENGTH - 1)
                    begin
                        STATE_TRC <= STOP;
                    end
                    else
                    begin
                        index <= index + 1'b1;
                        STATE_TRC <= START;
                    end
                end
            end
            
            RD:
            begin
                if(!avl_busy & (avl_writedata == avl_readdata))
                begin
                    avl_read_req <= 1'b0;
                    if(index == LENGTH - 1)
                    begin
                        STATE_TRC <= STOP;
                    end
                    else
                    begin
                        index <= index + 1'b1;
                        STATE_TRC <= START;
                    end
                end
            end
            
            STOP:
            begin
                finish_trc <= 1'b1;
            end
        
            default:
            begin
                avl_read_req 	<= 1'b0;
                avl_write_req 	<= 1'b0;
                index 		<= 8'd0;
                finish_trc 	<= 1'b0;
                STATE_TRC 	<= IDLE;
            end
            
            
            endcase
        end
        
    end
            
endmodule