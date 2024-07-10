module debouncer #( parameter   CLOCK_FREQUENCY = 50, //in MHz
                                    DEBOUNCE_TIME = 5)    //in ms
(
    input clk,
    input reset,
    input data_in,
    output reg data_out
);

localparam N_COUNTER = DEBOUNCE_TIME * CLOCK_FREQUENCY * 1000;

reg [$clog2(N_COUNTER) - 1:0] counter;
reg temp_reg1, temp_reg2;

always @(posedge clk ) begin
    if (reset) begin
        temp_reg1 <= data_in;
        temp_reg2 <= data_in;
        data_out <= data_in;
        counter <= N_COUNTER[$clog2(N_COUNTER) - 1:0];
    end
    else begin
        temp_reg1 <= data_in;
        temp_reg2 <= temp_reg1;
        if (temp_reg1 == temp_reg2 && counter < N_COUNTER) begin
            counter <= counter + 1'b1;
        end
        if (temp_reg1 != temp_reg2) begin
            counter <= 0;
        end
        if (counter >= N_COUNTER) begin
            data_out <= temp_reg2;
        end
    end
end

endmodule