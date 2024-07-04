`include "alt_i2c_sm_ctrl.v"

module i2c_handler #(parameter CLK_FREQ = 50000000, I2C_FREQ = 100000)
(
    input clk,
    input reset,

    input start,
    output busy,

    input [9:0] stop_index,
    output reg [9:0] index,

    input [6:0] i2c_address,
    input [7:0] i2c_reg_address,
    input [7:0] i2c_data,

    inout i2c_sda,
    inout i2c_scl


);


// ----- MAIN STATE MACHINE

wire ctrl_busy;
reg ctrl_start = 1'b0;

localparam IDLE = 4'd0,
            CONF_WAIT = 4'd1,
            CONF_RUN = 4'd2;

reg [3:0] STATE = IDLE;

reg int_busy;
assign busy = int_busy | ctrl_busy;

always @ (posedge clk)
begin
    if(reset)
    begin
        ctrl_start <= 1'b0;
        int_busy <= 1'b1;
        STATE <= IDLE;
    end
    else
    begin
        case(STATE)
            IDLE:
            begin
                if(start & !ctrl_busy)
                begin
                    index <= 1;
                    ctrl_start <= 1'b1;
                    int_busy <= 1'b1;
                    STATE <= CONF_WAIT;
                end
                else
                    int_busy <= 1'b0;
            end

            CONF_WAIT:
            begin
                if(!ctrl_busy)
                    STATE <= CONF_RUN;
                ctrl_start <= 1'b0;
            end

            CONF_RUN:
            begin
                if(!ctrl_busy)
                begin
                    index <= index + 1'b1;
                    if(index == stop_index)
                    begin
                        ctrl_start <= 1'b0;
                        int_busy <= 1'b0;
                        STATE <= IDLE;
                    end
                    else
                    begin
                        ctrl_start <= 1'b1;
                        STATE <= CONF_WAIT;
                    end
                end
                else
                begin
                    ctrl_start <= 1'b0;
                    STATE <= CONF_WAIT;
                end
            end

            default:
            begin
                ctrl_start <= 1'b0;
                int_busy <= 1'b0;
                STATE <= IDLE;
            end
        endcase
    end
end


alt_i2c_sm_ctrl #(.CLK_FREQ(CLK_FREQ), .I2C_FREQ(I2C_FREQ)) alt_i2c_sm_ctrl_0 
(

    .clk(clk),
    .reset(reset),

    .start(ctrl_start),
    .busy(ctrl_busy),
    
    .i2c_address(i2c_address),
    .rw(),

    .reg_address(i2c_reg_address),
    .data_in(i2c_data),

    .i2c_sda(i2c_sda),
    .i2c_scl(i2c_scl)


);



endmodule

