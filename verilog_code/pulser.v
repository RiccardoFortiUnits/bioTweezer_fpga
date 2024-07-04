module pulser (

    input clk,
    input signal_in,
    
    output signal_out

);

reg signal_in_reg;
reg signal_in_reg_1;
reg signal_out_reg = 1'b0;

assign signal_out = signal_out_reg;

always @ (posedge clk)
begin
    signal_in_reg_1 <= signal_in;
    signal_in_reg <= signal_in_reg_1;
end

localparam  IDLE = 1'b0,
            EDGE = 1'b1;

reg STATE = IDLE;

always @ (posedge clk)
begin
    case(STATE)
        IDLE:
        begin
            if(signal_in_reg)
            begin
                signal_out_reg <= 1'b1;
                STATE <= EDGE;
            end
        end

        EDGE:
        begin
            signal_out_reg <= 1'b0;
            if(!signal_in_reg)
                STATE <= IDLE;
        end

    endcase
end


endmodule
