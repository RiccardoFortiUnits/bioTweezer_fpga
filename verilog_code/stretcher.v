module stretcher #(
		parameter output_pulse_cycles = 4 //how many clock cycles the stretched pulse must stay high
	)(

    input clk,
    input signal_in,
    
    output signal_out

);


reg signal_in_reg;
reg signal_in_reg_1;
reg signal_out_reg = 1'b0;

assign signal_out = signal_out_reg;

// always @ (posedge clk)
// begin
//     signal_in_reg_1 <= signal_in;
//     signal_in_reg <= signal_in_reg_1;
// end

reg [$clog2(output_pulse_cycles)-1: 0] counter = 0;

localparam  IDLE = 1'b0,
            COUNT = 1'b1;

reg STATE = IDLE;

always @ (posedge clk)
begin
    case(STATE)
        IDLE:
        begin
            if(signal_in)
            begin
                signal_out_reg <= 1'b1;
                counter <= 0;
                STATE <= COUNT;
            end
        end

        COUNT:
        begin
            if(counter == output_pulse_cycles - 1'b1)
            begin
                signal_out_reg <= 1'b0;
                STATE <= IDLE;
            end
            counter <= counter + 1'b1;
        end

    endcase
end



endmodule
