module dec_comm_fifo (

    input clk,
    input reset,

    //fifo interface
    //hps to fpga
    input cmd_fifo_empty,
    input [31:0] cmd_fifo_data,
    output reg cmd_fifo_read = 1'b0,
    //fpga to hps
    input rsp_fifo_empty,
    output reg [31:0] rsp_fifo_data,
    output reg rsp_fifo_write = 1'b0,

    output reg led_driver = 1'b0



);


// COMMAND LIST
// GENERAL COMMANDS:
localparam  LED_ON = 32'hABAB_ABAB,
            LED_OFF = 32'hEEEE_AAAA,
            SHOW_VER = 32'hCCCC_CCCC;


// DECODER RX STATE MACHINE

localparam  IDLE = 0,
            READ_DATA = 1,
            READ_DATA_1 = 2,
            EVAL = 3;

reg [2:0] RX_STATUS = IDLE;

reg with_data = 1'b0;
reg nak = 1'b0;
reg ack = 1'b0;
reg ver = 1'b0;

reg [31:0] rx_buffer;

always @(posedge clk or posedge reset)
begin
	if(reset)
	begin
        cmd_fifo_read <= 1'b0;

        with_data <= 1'b0;
        nak <= 1'b0;
        ack <= 1'b0;
        ver <= 1'b0;

        led_driver <= 1'b0;

        RX_STATUS <= IDLE;
    end
    else
    begin
        case(RX_STATUS)

            IDLE:
            begin
                if(!cmd_fifo_empty) // data is arrived
                begin
                    cmd_fifo_read <= 1'b1;
                    RX_STATUS <= READ_DATA;
                end
                with_data <= 1'b0;
                nak <= 1'b0;
                ack <= 1'b0;
                ver <= 1'b0;
            end

            READ_DATA:  //extra status to compensate fifo delay
            begin
                cmd_fifo_read <= 1'b0;
                RX_STATUS <= READ_DATA_1;
            end

            READ_DATA_1:
            begin
                rx_buffer <= cmd_fifo_data;
                RX_STATUS <= EVAL;
            end

            EVAL:
            begin
                case (rx_buffer)

                //GENERAL COMMANDS
                    LED_ON:
                    begin
                        led_driver <= 1'b1;
                        ack <= 1'b1;
                        RX_STATUS <= IDLE;
                    end

                    LED_OFF:
                    begin
                        led_driver <= 1'b0;
                        ack <= 1'b1;
                        RX_STATUS <= IDLE;
                    end

                    SHOW_VER:
                    begin
                        ver <= 1'b1;
                        RX_STATUS <= IDLE;
                    end


                    default: 
                    begin
                        nak <= 1'b1;
                        ack <= 1'b0;
                        ver <= 1'b0;
                        RX_STATUS <= IDLE;
                    end
                endcase
            end


            default:
            begin
                cmd_fifo_read <= 1'b0;
                nak <= 1'b0;
                ack <= 1'b0;
                ver <= 1'b0;
                RX_STATUS <= IDLE;
            end

        endcase
    end
end




// TX STATE MACHINE

localparam 	TX_IDLE = 0,
				TX_WRITE_DATA = 1,
				TX_FLUSH = 2;

reg [2:0] TX_STATUS = TX_IDLE;


always @(posedge clk)
begin
    if(reset)
    begin
        rsp_fifo_write <= 1'b0;
        TX_STATUS <= TX_IDLE;
    end
    else
    begin
        case (TX_STATUS)
            TX_IDLE:
            begin
                if (ack)
                begin
                    rsp_fifo_data <= {8'd65, 8'd67, 8'd75, 8'd10}; // A C K \n 
                    rsp_fifo_write <= 1'b1;
                    TX_STATUS <= TX_WRITE_DATA;
                end
                else if(nak)
                begin
                    rsp_fifo_data <= {8'd78, 8'd65, 8'd75, 8'd10}; // N A K \n 
                    rsp_fifo_write <= 1'b1;
                    TX_STATUS <= TX_WRITE_DATA;
                end
                else if(ver)
                begin
                    rsp_fifo_data <= {8'd48, 8'd46, 8'd49, 8'd10}; // 0 . 1 \n 
                    rsp_fifo_write <= 1'b1;
                    TX_STATUS <= TX_WRITE_DATA;
                end
                else
                    rsp_fifo_write <= 1'b0;
            end 

            TX_WRITE_DATA:
            begin
                rsp_fifo_write <= 1'b0;
                TX_STATUS <= TX_IDLE;
            end



            default: 
            begin
                rsp_fifo_write <= 1'b0;
                TX_STATUS <= TX_IDLE;
            end
        endcase
    end
end




endmodule
