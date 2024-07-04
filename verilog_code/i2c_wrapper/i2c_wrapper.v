`include "i2c_handler.v"
//`include "si5340/si5340_lut.v"
`include "lmk61e2/lmk61e2_lut.v"

module i2c_wrapper #(parameter CLK_FREQ = 50000000, I2C_FREQ = 100000)
(
    input clk,
    input reset,

    input start,
    output busy,
    output reg initial_config = 1'b0,
    output reg done = 1'b0,

    inout i2c_sda,
    inout i2c_scl


);

localparam  SI5340_ADDRESS = 7'b1110100,
            SI5340_STOP_INDEX = 10'd105,
            LMK61E2_ADDRESS = 7'b1011010,
            LMK61E2_STOP_INDEX = 10'd2,
            NUM_COMPONENTS = 1;



reg [6:0] i2c_address;
reg [7:0] i2c_reg_address;
reg [7:0] i2c_data;
reg [9:0] i2c_stop_index;

reg [2:0] sel_component;

// wire [7:0] si5340_reg_address;
// wire [7:0] si5340_data;

wire [7:0] lmk61e2_reg_address;
wire [7:0] lmk61e2_data;

always @(*)
begin
    case(sel_component)

        3'd0:   //idle
        begin
            i2c_address = 7'd0;
            i2c_reg_address = 8'd0;
            i2c_data = 8'd0;
            i2c_stop_index = 10'd0;
        end

        3'd1:   //select lmk61e2
        begin
            i2c_address = LMK61E2_ADDRESS;
            i2c_reg_address = lmk61e2_reg_address;
            i2c_data = lmk61e2_data;
            i2c_stop_index = LMK61E2_STOP_INDEX;
        end

        // 3'd2:   //select si5340
        // begin
        //     i2c_address = SI5340_ADDRESS;
        //     i2c_reg_address = si5340_reg_address;
        //     i2c_data = si5340_data;
        //     i2c_stop_index = SI5340_STOP_INDEX;
        // end



        default:
        begin
            i2c_address = 7'd0;
            i2c_reg_address = 8'd0;
            i2c_data = 8'd0;
            i2c_stop_index = 10'd0;
        end


    endcase
end




// ----- MAIN STATE MACHINE

wire handler_busy;
reg handler_start = 1'b0;
//reg initial_config = 1'b0;

reg busy_int;

assign busy = busy_int | handler_busy;

localparam IDLE = 4'd0,
            FIRST_CONF_WAIT = 4'd1,
            FIRST_CONF_RUN = 4'd2;

reg [3:0] STATE = IDLE;


always @ (posedge clk)
begin
    if(reset)
    begin
        handler_start <= 1'b0;
        sel_component <= 3'd0;
        initial_config <= 1'b1;
		done <= 1'b0;
        busy_int <= 1'b1;
        STATE <= IDLE;
    end
    else
    begin
        case(STATE)
            IDLE:
            begin
                if(initial_config & !handler_busy)
                begin
                    sel_component <= 3'd1;
                    handler_start <= 1'b1;
                    busy_int <= 1'b1;
                    STATE <= FIRST_CONF_WAIT;
                end
                else
                    busy_int <= 1'b0;
            end

            FIRST_CONF_WAIT:
            begin
                handler_start <= 1'b0;
                STATE <= FIRST_CONF_RUN;
            end

            FIRST_CONF_RUN:
            begin
                if(!handler_busy)
                begin
                    if(sel_component == NUM_COMPONENTS)
                    begin
                        busy_int <= 1'b0;
                        initial_config <= 1'b0;
                        handler_start <= 1'b0;
		                done <= 1'b1;
                        STATE <= IDLE;
                    end
                    else
                    begin
                        sel_component <= sel_component + 1'b1;
                        handler_start <= 1'b1;
                        STATE <= FIRST_CONF_WAIT;
                    end
                end 
                
            end

            default:
            begin
                handler_start <= 1'b0;
                sel_component <= 3'd0;
                initial_config <= 1'b0;
                busy_int <= 1'b0;
                STATE <= IDLE;
            end
        endcase
    end
end


wire [9:0] index;

i2c_handler #(.CLK_FREQ(CLK_FREQ), .I2C_FREQ(I2C_FREQ))  i2c_handler_0
(
    .clk(clk),
    .reset(reset),

    .start(handler_start),
    .busy(handler_busy),

    .stop_index(i2c_stop_index),
    .index(index),

    .i2c_address(i2c_address),
    .i2c_reg_address(i2c_reg_address),
    .i2c_data(i2c_data),

    .i2c_sda(i2c_sda),
    .i2c_scl(i2c_scl)


);



// si5340_lut si5340_lut_0 (

// 					.index(index),
					
//                     .enable_outputs(4'b0100),
//                     .sel_f3(3'd3),  //DIGIO_CLK - 225 MHz
//                     .sel_f2(3'd7),  //FPGA CLK - 100 MHz
//                     .sel_f1(3'd1),  //UMCD_CLK - 322.265 MHz
//                     .sel_f0(3'd6),  //UMCA_CLK - 125 MHz

// 					.address(si5340_reg_address),
// 					.data(si5340_data),
//                     .rw()
					
// );

lmk61e2_lut lmk61e2_lut_0 (
					.index(index),
                    .divider(8'd25), // ADC_CLK 100 MHz (divider 50)
					
					.address(lmk61e2_reg_address),
					.data(lmk61e2_data),
					.rw()
					
);


endmodule

