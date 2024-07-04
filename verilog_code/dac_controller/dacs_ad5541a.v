// first_start is needed since the DACs don't start at a known value,
// this force it to midscale (which due to the external subtraction means 0)

module dacs_ad5541a (

    input clock,
    input reset,

    //DAC vref: 5V - Vout = data * 5 / 65536
    input [15:0] dac1_datain,
    input [15:0] dac2_datain,
    input [15:0] dac3_datain,
    input [15:0] dac4_datain,

    input [2:0] select_dac, 
    // 000 dac1, 001 dac2, 010 dac3, 011 dac4, 100 all dacs simultaneously
    input start,
    output reg busy = 1'b0,

    // dac spi interface
    // SCLK max frequency is 14 MHz for 2.5V logic
    output reg sclk = 1'b0,
    output reg ldac_n = 1'b1,

    output [3:0] dac_sdo = 4'd0,

    output reg [3:0] cs_n = 4'b1111

);

reg int_cs_n = 1'b1;

always @ (*) begin
    if(reset) begin
        cs_n = {4'b1111};
    end
    else begin
        case (select_dac_reg)
            3'b000:
                cs_n = {3'b111, int_cs_n};
            3'b001:
                cs_n = {2'b11, int_cs_n, 1'b1};
            3'b010:
                cs_n = {1'b1, int_cs_n, 2'b11};
            3'b011:
                cs_n = {int_cs_n, 3'b111};
            3'b100:
                cs_n = {4{int_cs_n}};
            default:
                cs_n = {4'b1111};
        endcase
    end
end 

localparam  IDLE = 3'd0,
            WAIT_CS1 = 3'd1,
            START = 3'd2,
            WAIT_CS2 = 3'd3,
            WAIT_LDAC = 3'd4,
            WAIT_TEST = 3'd6,
            ENDING = 3'd5;

reg [3:0] STATUS = IDLE;

reg [5:0] bit_counter = 6'd0;

reg enable_sclk = 1'b0;
reg reset_sclk = 1'b0;

reg [2:0] select_dac_reg;
reg [15:0] dac1_datain_reg;
reg [15:0] dac2_datain_reg;
reg [15:0] dac3_datain_reg;
reg [15:0] dac4_datain_reg;
reg first_start = 1'b0;

wire [15:0] dac1_datain_sel = (first_start == 1'b1)? 16'h8000 : dac1_datain;
wire [15:0] dac2_datain_sel = (first_start == 1'b1)? 16'h8000 : dac2_datain;
wire [15:0] dac3_datain_sel = (first_start == 1'b1)? 16'h8000 : dac3_datain;
wire [15:0] dac4_datain_sel = (first_start == 1'b1)? 16'h8000 : dac4_datain;

reg [7:0] counter;

always @ (posedge clock)
begin
    if(reset)
    begin
        select_dac_reg <= 3'b111;
        first_start <= 1'b1;
        bit_counter <= 6'd0;
        int_cs_n <= 1'b1;
        ldac_n <= 1'b1;
        reset_sclk <= 1'b1;
        enable_sclk <= 1'b0;
        busy <= 1'b0;
        STATUS <= IDLE;
    end
    else
    begin
        case(STATUS)

        IDLE:
        begin
            if(start || first_start)
            begin
                first_start <= 1'b0;
                //registering inputs
                dac1_datain_reg <= dac1_datain_sel;
                dac2_datain_reg <= dac2_datain_sel;
                dac3_datain_reg <= dac3_datain_sel;
                dac4_datain_reg <= dac4_datain_sel;

                select_dac_reg <= select_dac;

                bit_counter <= 6'd0;

                reset_sclk <= 1'b0;
                busy <= 1'b1;
                
                //enabling dacs
                int_cs_n <= 1'b0;

                STATUS <= WAIT_CS1;

            end
            else
            begin
                busy <= 1'b0;
                int_cs_n <= 1'b1;
                reset_sclk <= 1'b1;
            end
            ldac_n <= 1'b1;
        end


        WAIT_CS1:
        begin
            enable_sclk <= 1'b1;
            STATUS <= START;
        end

        START:
        begin
            if(bit_counter == 6'd31)
            begin
                enable_sclk <= 1'b0;
                int_cs_n <= 1'b1;
                STATUS <= ENDING;
            end
            else
                bit_counter <= bit_counter + 1'b1;
        end
/*
        WAIT_CS2:
        begin
            int_cs_n <= 1'b1;
            busy <= 1'b0;
            STATUS <= IDLE;
            //STATUS <= WAIT_LDAC;
        end

        WAIT_LDAC:
        begin
            ldac_n <= 1'b0;
            STATUS <= ENDING;
        end
*/
        ENDING:
        begin
            ldac_n <= 1'b1;
            busy <= 1'b0;
            STATUS <= IDLE;
            // counter <= 8'd0;
            // busy <= 1'b1;
            // STATUS <= WAIT_TEST;
        end

        // WAIT_TEST:
        // begin
        //     counter <= counter + 1'b1;
        //     if (counter == 14) begin
        //         busy <= 1'b0;
        //         STATUS <= IDLE;
        //     end
        // end


        default:
        begin
            int_cs_n <= 1'b1;
            ldac_n <= 1'b1;
            reset_sclk <= 1'b1;
            enable_sclk <= 1'b0;
            busy <= 1'b0;
            STATUS <= IDLE;
        end

        endcase
    end
end


// sclk creation
always @ (posedge clock)
begin
    if(reset_sclk)
    begin
        sclk <= 1'b0;
    end
    else
    begin
        if(enable_sclk)
            sclk <= ~sclk;
    end
end

// sdo indexing
reg [3:0] sdo_index = 4'd15;

always @ (posedge clock)
begin
    if(reset_sclk)
        sdo_index <= 4'd15;
    else if(enable_sclk & sclk) //data is sampled on posedge sclk by the adc, so the change is on negedge
    begin
        sdo_index <= sdo_index - 1'b1;
    end
end


// sdo outputs
assign dac_sdo[0] = ((select_dac_reg == 3'b000) || (select_dac_reg == 3'b100)) ? dac1_datain_reg[sdo_index] : 1'b0;
assign dac_sdo[1] = ((select_dac_reg == 3'b001) || (select_dac_reg == 3'b100)) ? dac2_datain_reg[sdo_index] : 1'b0;
assign dac_sdo[2] = ((select_dac_reg == 3'b010) || (select_dac_reg == 3'b100)) ? dac3_datain_reg[sdo_index] : 1'b0;
assign dac_sdo[3] = ((select_dac_reg == 3'b011) || (select_dac_reg == 3'b100)) ? dac4_datain_reg[sdo_index] : 1'b0;

endmodule
