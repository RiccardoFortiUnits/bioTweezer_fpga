module generic_param_decoder#(
	parameter paramBitSize = 1
) (
    input clk,
    input reset,

    input [31:0] received_data,
    input        data_valid,

    input wipe_settings,
	 
	 output reg [paramBitSize -1:0] param,

    output reg ack,
    output reg nak,
    output reg err
);


// STATE MACHINE
localparam  IDLE = 0,
            EVAL = 1;

reg [1:0] STATE = IDLE;

//-------------------------------------------------------------------------------------------------------------------------------
// PI ENABLE COMMANDS DECODING AND RESET

always @(posedge clk) 
begin
    if (reset || wipe_settings) 
    begin                
        STATE <= IDLE;
		  ack <= 0;
		  nak <= 0;
		  err <= 0;
		  
		  param <= 0;
    end
    else 
    begin
        case (STATE)
            IDLE: 
            begin
                if (data_valid) 
                begin
                    STATE <= EVAL;
                end
                else
                begin
                    STATE <= IDLE;
                end
            
                ack <= 1'b0;
                nak <= 1'b0;
                err <= 1'b0;
            end

            EVAL: 
            begin
                STATE <= IDLE;
					 param <= received_data[paramBitSize -1:0];
					 ack <= 1;
            end

            default: 
            begin
                STATE <= IDLE;                     
            end
        endcase
    end
end

endmodule