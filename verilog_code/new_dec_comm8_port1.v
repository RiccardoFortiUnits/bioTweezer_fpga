//`include "timeout_check.v"

module new_dec_comm8_port1 #(
    parameter AVL_SIZE  = 8,
              BYTE_SIZE = 8,
              IP_SIZE   = 32,
              MAC_SIZE  = 48
) (
    input clk,   // clock 125 MHz (rx_xcvr_clk)
    input reset, // !mac_configured_125 from eth_1gb_wrapper.v

    output reg [MAC_SIZE-1:0] source_mac = {{MAC_SIZE}{1'b0}},
    output reg [IP_SIZE-1:0]  source_ip  = {{IP_SIZE}{1'b0}},
    //----------------------------------------------------------------
    // RX FIFO INTERFACE FROM 1GB ETHERNET
    input [AVL_SIZE-1:0]	                     rx_fifo_data,
    input [2*BYTE_SIZE + IP_SIZE + MAC_SIZE-1:0] rx_fifo_status,
    input		                                 rx_fifo_status_empty,
    output reg		                             rx_fifo_data_read,
    output reg		                             rx_fifo_status_read,
    //----------------------------------------------------------------

    //----------------------------------------------------------------
    // TX FIFO INTERFACE TO 1GB ETHERNET (for ACK, NAK, ERR)
    output reg [AVL_SIZE-1:0]                         tx_fifo_data,
    output reg [2*BYTE_SIZE + IP_SIZE + MAC_SIZE-1:0] tx_fifo_status,
    output reg tx_fifo_data_write,
    output reg tx_fifo_status_write,
    input      tx_fifo_data_full,
    input      tx_fifo_status_full,

    //----------------------------------------------------------------

    //----------------------------------------------------------------
    // TO/FROM PARAMETER DECODERS
    output reg [4*BYTE_SIZE-1:0] received_data,

    output reg                   received_control_param_valid,

    output reg                   received_pi_enable_comm_valid,
    output reg                   received_pi_reset_comm_valid,

    output                       wipe_settings,

    input                        control_param_written,//unused...

    input                        control_param_ack,
    input                        control_param_nak,
    input                        control_param_err,

    input                        pi_enable_comm_ack,
    input                        pi_enable_comm_nak,
    input                        pi_enable_comm_err,

    input                        pi_reset_comm_ack,
    input                        pi_reset_comm_nak,
    input                        pi_reset_comm_err,
    //----------------------------------------------------------------

    //----------------------------------------------------------------
    // ACQUISITION COMMANDS
    output reg start_control_cmd = 1'b0,
    output reg stop_control_cmd  = 1'b0,
    //----------------------------------------------------------------
    
    //----------------------------------------------------------------
    // DAC and ADC STATUS 
    input DAC_running,
    input DAC_stopped,
    input ADC_ready,
    //----------------------------------------------------------------

    //----------------------------------------------------------------
    // CONNECTION STATUS
    output              conn_timeout_n
    //----------------------------------------------------------------
);

//-------------------------------------------------------------------------------------------------------------------------------
// COMMAND LIST:
localparam  SHOW_VERSION    = 32'h5645_523F, // VER? - Returns the current firmware version
            CONN            = 32'h434F_4E4E, // CONN - Connection keepalive command
            START_CONTROL   = 32'h434F_4F4E, // COON - Starts the control and the acquisition
            STOP_CONTROL    = 32'h434F_4646, // COFF - Stops  the control and the acquisition
            CONTROL_PARAM   = 32'h4350_4152, // CPAR - This command sends the parameters necessary for the control
            FPGA_PI_EN      = 32'h5049_454E, // PIEN - This command enables the FPGA PI controller
            FPGA_PI_RST     = 32'h5049_434C, // PICL - This command resets the FPGA PI controller
            RUN_OK          = 32'h5255_4E3F, // RUN? - Returns ACK if is running, otherwise returns ERR
            ADC_DELAY       = 32'h4144_454C, // ADEL - ADC/DAC Delay Value     
            WIPE            = 32'h5749_5045; // WIPE - This command wipes all the parameters stored and disables all the PI controllers
//-------------------------------------------------------------------------------------------------------------------------------

//-------------------------------------------------------------------------------------------------------------------------------
// DECODER RX STATE MACHINE

localparam  RX_IDLE        = 0,
            RX_READ_DATA   = 1,
            RX_READ_DATA_1 = 2,
            RX_FLUSH       = 3,
            RX_UNPACK_CMD  = 4,
            RX_WAIT        = 5,
            RX_EVAL        = 6,
            RX_CONTROL_PARAM_EVAL  = 7,
            RX_FPGA_PIEN_COMM_EVAL = 8,
            RX_FPGA_PICL_COMM_EVAL = 9;

reg [3:0] RX_STATUS = RX_IDLE;

localparam  COMMAND_ONLY = 4, // length of command:                  32 bit - 4 bytes
            COMMAND_DATA = 8; // length of command + data: 32 + 32 = 64 bit - 8 bytes

reg [COMMAND_DATA*AVL_SIZE-1:0]  rx_buffer;    // received data buffer
reg [2*BYTE_SIZE-1:0]            byte_counter; // received byte counter
reg [COMMAND_ONLY*BYTE_SIZE-1:0] received_cmd; // command part of the incoming data

reg with_data;          // if the received command is with data or not
reg ack, nak, ver, err; // signals for the TX state machine

reg    conn_timeout_restart, conn_timeout_enable;
reg    wipe_from_command;
wire   wipe_from_timeout = 0; 
assign wipe_settings = wipe_from_timeout || wipe_from_command; // wipe from timeout or wipe from command

always @(posedge clk)
begin
	if (reset)
	begin
        rx_fifo_data_read   <= 1'b0;
        rx_fifo_status_read <= 1'b0;

        source_mac <= {{MAC_SIZE}{1'b0}};
        source_ip  <= {{IP_SIZE}{1'b0}};

        byte_counter <= 1'd0;

        with_data <= 1'b0;

        ack <= 1'b0;
        nak <= 1'b0;
        ver <= 1'b0;
        err <= 1'b0;

        conn_timeout_restart <= 1'b0;
        conn_timeout_enable  <= 1'b0;
        wipe_from_command    <= 1'b0;

        received_control_param_valid  <= 1'b0;

        received_pi_enable_comm_valid <= 1'b0;
        received_pi_reset_comm_valid  <= 1'b0;

        
        start_control_cmd <= 1'b0;
        stop_control_cmd  <= 1'b0;


        RX_STATUS <= RX_IDLE;
    end
    else
    begin
        case (RX_STATUS)
            RX_IDLE:
            begin
                if (!rx_fifo_status_empty) // if data has arrived
                begin
                    rx_fifo_status_read <= 1'b1;
                    byte_counter        <= rx_fifo_status[2*BYTE_SIZE + IP_SIZE + MAC_SIZE-1 -: 2*BYTE_SIZE];
                    source_ip           <= rx_fifo_status[IP_SIZE + MAC_SIZE-1 -: IP_SIZE];
                    source_mac          <= rx_fifo_status[MAC_SIZE-1 -: MAC_SIZE];
                    RX_STATUS           <= RX_READ_DATA;
                end
                else
                begin
                    RX_STATUS <= RX_IDLE;
                end

                with_data <= 1'b0;

                ack <= 1'b0;
                nak <= 1'b0;
                ver <= 1'b0;
                err <= 1'b0;

                received_control_param_valid  <= 1'b0;

                received_pi_enable_comm_valid <= 1'b0;
                received_pi_reset_comm_valid  <= 1'b0;


                start_control_cmd <= 1'b0;
                stop_control_cmd  <= 1'b0;

                conn_timeout_restart <= 1'b0;

                if (wipe_settings) 
                begin

                    wipe_from_command   <= 1'b0;
                    conn_timeout_enable <= 1'b0;
                end
            end

            RX_READ_DATA: // check if the command is with or without data while reading
            begin
                rx_fifo_status_read <= 1'b0;
                rx_fifo_data_read   <= 1'b1;
                byte_counter        <= byte_counter - 1'b1;

                if (byte_counter == COMMAND_ONLY)
                begin
                    with_data <= 1'b0;
                    RX_STATUS <= RX_READ_DATA_1;
                end
                else if (byte_counter == COMMAND_DATA)
                begin
                    with_data <= 1'b1;
                    RX_STATUS <= RX_READ_DATA_1;
                end
                else
                begin
                    RX_STATUS <= RX_FLUSH;
                end
            end

            RX_READ_DATA_1: // read the data from the RX FIFO 
            begin
                if (byte_counter == 0)
                begin
                    rx_fifo_data_read <= 1'b0;
                    RX_STATUS <= RX_UNPACK_CMD;
                end
                                
                // shifting the register
                rx_buffer[COMMAND_DATA*AVL_SIZE-1:BYTE_SIZE] <= rx_buffer[COMMAND_DATA*AVL_SIZE-BYTE_SIZE-1:0];
                rx_buffer[BYTE_SIZE-1:0] <= rx_fifo_data;
                
                byte_counter <= byte_counter - 1'b1;
            end

            RX_UNPACK_CMD: 
            begin // unpack the received command and data
                rx_fifo_data_read <= 1'b0;

                if (with_data) received_cmd <= rx_buffer[COMMAND_DATA*AVL_SIZE-1 -: COMMAND_ONLY*BYTE_SIZE];
                else           received_cmd <= rx_buffer[COMMAND_ONLY*AVL_SIZE-1 : 0];

                received_data <= rx_buffer[COMMAND_ONLY*AVL_SIZE-1 : 0];
                RX_STATUS <= RX_WAIT;
            end

            RX_WAIT: 
            begin // delay state to add a multicycle constraint to improve timing
                RX_STATUS <= RX_EVAL;
            end

            RX_EVAL: 
            begin 
                RX_STATUS <= RX_IDLE;                
                conn_timeout_restart <= 1'b1; // restart the timeout counter   when any command is received
                conn_timeout_enable  <= 1'b1; // enable  the timeout detection when any command is received
                case (received_cmd)
`define evalCommand(command, checkCondition, evaluation)   \
    command:                                               \
    begin                                                  \
        if(checkCondition)                                 \
        begin                                              \
            evaluation                                     \
        end                                                \
        else                                               \
        begin                                              \
            err <= 1'b1;                                   \
        end                                                \
    end
                    `evalCommand(SHOW_VERSION, 1, 
                        ver <= 1'b1;
                    )
                    `evalCommand(CONN, 1,
                        ack <= 1'b1; //keep alive command
                    )
                    `evalCommand(START_CONTROL, DAC_stopped && ADC_ready, 
                        start_control_cmd <= 1'b1; // Starts the control and the acquisition
                        ack <= 1'b1;
                    )
                    `evalCommand(STOP_CONTROL, DAC_running, 
                        stop_control_cmd <= 1'b1; // Stops the control and the acquisition
                        ack <= 1'b1;
                    )
                    `evalCommand(CONTROL_PARAM, with_data == 1'b1, 
                        received_control_param_valid <= 1'b1; // Parameters necessary for the control received
                        RX_STATUS <= RX_CONTROL_PARAM_EVAL;
                        //we'll toggle the ack only after receiving news from the control_param_decoder
                    )
                    `evalCommand(FPGA_PI_EN, with_data == 1'b1, 
                        received_pi_enable_comm_valid <= 1'b1; // This command enables the FPGA PI controller
                        RX_STATUS <= RX_FPGA_PIEN_COMM_EVAL;
                    )
                    `evalCommand(FPGA_PI_RST, with_data == 1'b1, // This command resets the FPGA PI controller
                        received_pi_reset_comm_valid <= 1'b1;
                        RX_STATUS <= RX_FPGA_PICL_COMM_EVAL;
                    )
                    `evalCommand(RUN_OK, DAC_running, 
                        ack <= 1'b1; // ACK if is running, otherwise returns ERR
                    )
                    //`evalCommand(ADC_DELAY, DAC_stopped, 
                    //    adc_delay_cmd <= received_data[15:0];
                    //    ack <= 1'b1;
                    //)
                    `evalCommand(WIPE, DAC_stopped, 
                        wipe_from_command <= 1'b1; // This command wipes all the parameters stored, resets and disables all the PI controllers
                        ack <= 1'b1;
                    )

                    default: 
                    begin
                        ack <= 1'b0;
                        nak <= 1'b1;
                        ver <= 1'b0;
                        err <= 1'b0;
                    end
                endcase
            end
`define evaluateAckNakErr(rxStatus, data_valid, data_ack, data_nak, data_err) \
    rxStatus:                                                                   \
    begin                                                                       \
        data_valid <= 1'b0;                                                     \
        if (data_ack)                                                           \
        begin                                                                   \
            ack <= 1'b1;                                                        \
            RX_STATUS <= RX_IDLE;                                               \
        end                                                                     \
        if (data_nak)                                                          \
        begin                                                                   \
            nak <= 1'b1;                                                        \
            RX_STATUS <= RX_IDLE;                                               \
        end                                                                     \
        if (data_err)                                                           \
        begin                                                                   \
            err <= 1'b1;                                                        \
            RX_STATUS <= RX_IDLE;                                               \
        end                                                                     \
    end
            `evaluateAckNakErr(RX_CONTROL_PARAM_EVAL, received_control_param_valid, control_param_ack, control_param_nak, control_param_err)
            `evaluateAckNakErr(RX_FPGA_PIEN_COMM_EVAL, received_pi_enable_comm_valid, pi_enable_comm_ack, pi_enable_comm_nak, pi_enable_comm_err)
            `evaluateAckNakErr(RX_FPGA_PICL_COMM_EVAL, received_pi_reset_comm_valid, pi_reset_comm_ack, pi_reset_comm_nak, pi_reset_comm_err)

            RX_FLUSH: // flush the fifo if the received command has an unusual length
            begin
                if (byte_counter == 1'd0)
                begin
                    rx_fifo_data_read <= 1'b0;
                    nak <= 1'b1;
                    RX_STATUS <= RX_IDLE;
                end
                byte_counter <= byte_counter - 1'd1;
            end

            default:
            begin
                rx_fifo_data_read   <= 1'b0;
                rx_fifo_status_read <= 1'b0;

                source_mac <= {{MAC_SIZE}{1'b0}};
                source_ip  <= {{IP_SIZE}{1'b0}};

                byte_counter <= 8'd0;

                ack <= 1'b0;
                nak <= 1'b0;
                ver <= 1'b0;
                err <= 1'b0;

                RX_STATUS <= RX_IDLE;
            end
        endcase
    end
end

//-------------------------------------------------------------------------------------------------------------------------------
// CONNECTION TIMEOUT CHECK
// the timeout counter is enabled when a command is received and is disabled after a wipe (both from command or timeout)
// the timeout counter restart when a command is received and is continuosly restarted when the DAC is running

timeout_check #(.BIT_WIDTH(32)) wait_data_timeout (
    .clk(clk),
    .reset(reset || !conn_timeout_enable),
    .restart_counter(conn_timeout_restart || DAC_running),
    .delay_length(32'd1250_000_000), // timeout after 10 seconds
    .timed_out_n(conn_timeout_n)
);

//-------------------------------------------------------------------------------------------------------------------------------
// DECODER TX STATE MACHINE

localparam TX_IDLE = 0,
		   TX_WRITE_DATA = 1;

reg [2:0]  TX_STATUS = TX_IDLE;

// registers added to improve timing/separation between the state machines
reg ack_reg, nak_reg, ver_reg, err_reg;

always @(posedge clk) 
begin
    if (reset)
	begin
        ack_reg <= 1'b0;
        nak_reg <= 1'b0;
        ver_reg <= 1'b0;
        err_reg <= 1'b0;
	end 
    else 
    begin
        ack_reg <= ack;
        nak_reg <= nak;
        ver_reg <= ver;
        err_reg <= err;
    end
end

localparam MAX_BYTES_TO_TRANSMIT = 16'd8;
reg [7:0] tx_buffer[0:MAX_BYTES_TO_TRANSMIT-1]; // TRANSMISSION DATA BUFFER

reg [15:0] tx_counter = 16'd0; // counter to scroll through the data to send
reg [15:0] tx_length  = 16'd0; // lenght of the data to send

always @(posedge clk)
begin
	if (reset)
	begin
		tx_fifo_status_write <= 1'b0;
		tx_fifo_data_write   <= 1'b0;
		TX_STATUS            <= TX_IDLE;
	end
	else
		case (TX_STATUS)
			TX_IDLE: 
            begin
				tx_fifo_status_write <= 1'b0;
				if (ack_reg)
                begin
					tx_counter   <= 16'd5;
                    tx_length    <= 16'd5;
					tx_buffer[4] <= 8'd65; // A
					tx_buffer[3] <= 8'd67; // C
					tx_buffer[2] <= 8'd75; // K
					tx_buffer[1] <= 8'd13; // \r
					tx_buffer[0] <= 8'd10; // \n
					TX_STATUS    <= TX_WRITE_DATA;
				end
				else if (nak_reg)
                begin
					tx_counter   <= 16'd5;
                    tx_length    <= 16'd5;
					tx_buffer[4] <= 8'd78; // N
					tx_buffer[3] <= 8'd65; // A
					tx_buffer[2] <= 8'd75; // K
					tx_buffer[1] <= 8'd13; // \r
					tx_buffer[0] <= 8'd10; // \n
					TX_STATUS    <= TX_WRITE_DATA;
				end
				else if (ver_reg)
                begin
					tx_counter   <= 16'd8;
                    tx_length    <= 16'd8;
					tx_buffer[7] <= 8'h31; // 1
					tx_buffer[6] <= 8'h2E; // .
					tx_buffer[5] <= 8'h30; // 0
					tx_buffer[4] <= 8'h54; // T
               tx_buffer[3] <= 8'h57; // W
					tx_buffer[2] <= 8'h45; // E
					tx_buffer[1] <= 8'd13; // \r
					tx_buffer[0] <= 8'd10; // \n
					TX_STATUS    <= TX_WRITE_DATA;
				end
                else if (err_reg) 
                begin
					tx_counter   <= 16'd5;
                    tx_length    <= 16'd5;
					tx_buffer[4] <= 8'd69; // E
					tx_buffer[3] <= 8'd82; // R
					tx_buffer[2] <= 8'd82; // R
					tx_buffer[1] <= 8'd13; // \r
					tx_buffer[0] <= 8'd10; // \n
					TX_STATUS    <= TX_WRITE_DATA;
				end
			end

			TX_WRITE_DATA: 
            begin // scroll through the buffer and write into the the TX fifos
				if (tx_counter == 16'd0) 
                begin
					tx_fifo_data_write   <= 1'b0;
					tx_fifo_status       <= {tx_length, source_ip, source_mac}; // always answer to the last sender
					tx_fifo_status_write <= 1'b1;
					TX_STATUS            <= TX_IDLE;
				end
				else 
                begin
                    if (!tx_fifo_data_full) 
                    begin
                        tx_fifo_data_write <= 1'b1;
                        tx_fifo_data       <= tx_buffer[tx_counter - 16'd1];
                        tx_counter         <= tx_counter - 16'd1;
                    end
                    else 
                    begin
                        tx_fifo_data_write <= 1'b0;
                    end					
				end
			end

			default: 
            begin
				tx_fifo_status_write <= 1'b0;
				tx_fifo_data_write   <= 1'b0;
				TX_STATUS            <= TX_IDLE;
			end
		endcase
end

endmodule