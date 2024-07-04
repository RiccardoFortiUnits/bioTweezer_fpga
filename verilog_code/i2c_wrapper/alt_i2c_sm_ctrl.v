//controller for Altera I2C core

module alt_i2c_sm_ctrl #(parameter CLK_FREQ = 50000000, I2C_FREQ = 100000)
(

    input clk,
    input reset,

    input start,
    
    input [6:0] i2c_address,
    input rw,

    input [7:0] reg_address,
    input [7:0] data_in,

    output busy,

    inout i2c_sda,
    inout i2c_scl


);

localparam  SCL_CNT = CLK_FREQ/(I2C_FREQ*2),
            SCL_LCNT = SCL_CNT-60,
            SCL_HCNT = SCL_CNT+60,
            SDA_CNT = SCL_LCNT-(SCL_LCNT/2);


reg [3:0] i2c_avl_address;
reg i2c_avl_read;
reg i2c_avl_write;
wire [31:0] i2c_avl_readdata;
reg [31:0] i2c_avl_writedata;
wire i2c_avl_irq;

reg busy_int;

// Altera's recommended configuration:
// 1. disable core (CTRL register)
// 2. write conf (timings of SCL, SDA)
// 2. enable core (CTRL register)

assign busy = busy_int | ~i2c_avl_irq;

//register addresses
localparam TFR_CMD = 4'h0,
            RX_DATA = 4'h1,
            CTRL = 4'h2,
            ISER = 4'h3,
            ISR = 4'h4,
            STATUS = 4'h5,
            TFR_CMD_FIFO_LVL = 4'h6,
            RX_DATA_FIFO_LVL = 4'h7,
            SCL_LOW = 4'h8,
            SCL_HIGH = 4'h9,
            SDA_HOLD = 4'hA;


localparam IDLE = 5'd0,
            START_CONFIG_1 = 5'd1,
            START_CONFIG_2 = 5'd2,
            START_CONFIG_3 = 5'd3,
            START_CONFIG_4 = 5'd4,
            START_CONFIG_5 = 5'd5,
            TF_ADDRESS = 5'd6,
            TF_DATA = 5'd7;

reg [4:0] STATE = IDLE;
reg init_cfg_done_n = 1'b0;

always @(posedge clk)
begin
    if(reset)
    begin
        i2c_avl_read <= 1'b0;
        i2c_avl_write <= 1'b0;
        init_cfg_done_n <= 1'b1;
        busy_int <= 1'b1;
        STATE <= IDLE;
    end
    else
    begin
        case(STATE)

            IDLE:
            begin
                if(init_cfg_done_n)
                begin
                    i2c_avl_address <= CTRL;
                    i2c_avl_writedata <= 32'd0; //disable core
                    i2c_avl_write <= 1'b1;
                    STATE <= START_CONFIG_1;
                    busy_int <= 1'b1;
                end
                else if(start & i2c_avl_irq)
                begin
                    i2c_avl_address <= TFR_CMD;
                    i2c_avl_writedata <= {22'd0, 1'b1, 1'b0, i2c_address, rw}; //start transfer - address phase
                    i2c_avl_write <= 1'b1;
                    STATE <= TF_ADDRESS;
                    busy_int <= 1'b1;
                end
                else
                begin
                    i2c_avl_read <= 1'b0;
                    i2c_avl_write <= 1'b0;
                    busy_int <= 1'b0;
                end
            end

            START_CONFIG_1:
            begin
                i2c_avl_address <= ISER;
                i2c_avl_writedata <= {27'd0, 5'b00001}; //enable IRQ for TX_READY
                STATE <= START_CONFIG_2;
            end

            START_CONFIG_2:
            begin
                i2c_avl_address <= SCL_LOW;
                i2c_avl_writedata <= SCL_LCNT; //write scl low
                STATE <= START_CONFIG_3;
            end

            START_CONFIG_3:
            begin
                i2c_avl_address <= SCL_HIGH;
                i2c_avl_writedata <= SCL_HCNT; //write scl high
                STATE <= START_CONFIG_4;
            end

            START_CONFIG_4:
            begin
                i2c_avl_address <= SDA_HOLD;
                i2c_avl_writedata <= SDA_CNT; //write sda period
                STATE <= START_CONFIG_5;
            end

            START_CONFIG_5:
            begin
                i2c_avl_address <= CTRL;
                i2c_avl_writedata <= {26'd0, 2'd0, 2'd0, 1'b0, 1'b1}; //config & enable core
                init_cfg_done_n <= 1'b0;
                STATE <= IDLE;
            end

            TF_ADDRESS:
            begin
                if(i2c_avl_irq)
                begin
                    i2c_avl_writedata <= {22'd0, 1'b0, 1'b0, reg_address}; //start transfer - register address phase
                    STATE <= TF_DATA;
                end
            end

            TF_DATA:
            begin
                i2c_avl_writedata <= {22'd0, 1'b0, 1'b1, data_in}; //start transfer - data phase and stop
                STATE <= IDLE;
            end

            default:
            begin
                STATE <= IDLE;
            end


        endcase
    end

end




wire i2c_serial_sda_oe;
wire i2c_serial_scl_oe;

assign i2c_sda = i2c_serial_sda_oe ? 1'b0 : 1'bz;
assign i2c_scl = i2c_serial_scl_oe ? 1'b0 : 1'bz;

i2c_alt_contr i2c_alt_contr_0 (
    .clk_clk                    (clk),                    //   input,   width = 1,                    clk.clk
    .reset_reset_n                (~reset),                 //   input,   width = 1,                  reset.reset_n

    .i2c_0_csr_address          (i2c_avl_address),          //   input,   width = 4,              i2c_0_csr.address
    .i2c_0_csr_read             (i2c_avl_read),             //   input,   width = 1,                       .read
    .i2c_0_csr_write            (i2c_avl_write),            //   input,   width = 1,                       .write
    .i2c_0_csr_writedata        (i2c_avl_writedata),        //   input,  width = 32,                       .writedata
    .i2c_0_csr_readdata         (i2c_avl_readdata),         //  output,  width = 32,                       .readdata
    .i2c_0_interrupt_sender_irq (i2c_avl_irq), //  output,   width = 1, i2c_0_interrupt_sender.irq

    .i2c_0_i2c_serial_sda_in    (i2c_sda),    //   input,   width = 1,       i2c_0_i2c_serial.sda_in
    .i2c_0_i2c_serial_scl_in    (i2c_scl),    //   input,   width = 1,                       .scl_in
    .i2c_0_i2c_serial_sda_oe    (i2c_serial_sda_oe),    //  output,   width = 1,                       .sda_oe
    .i2c_0_i2c_serial_scl_oe    (i2c_serial_scl_oe)    //  output,   width = 1,                       .scl_oe
);



endmodule

