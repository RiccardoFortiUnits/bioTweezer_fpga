`include "timeout_check.v"

module dec_comm8_port1 #(parameter AVL_SIZE = 8,
                    BYTE_SIZE = 8,
                    IP_SIZE = 32,
                    MAC_SIZE = 48,
                    MAX_WFM_LENGTH = 8192)
(
    input	        clk,
    input           reset,

    output reg [MAC_SIZE-1:0] source_mac = {{MAC_SIZE}{1'b0}},
    output reg [IP_SIZE-1:0] source_ip = {{IP_SIZE}{1'b0}},

    // rx fifo interface from 1gb eth
    input [AVL_SIZE-1:0]	                    rx_fifo_data,
    output reg		                            rx_fifo_data_read,
    input [2*BYTE_SIZE+IP_SIZE+MAC_SIZE-1:0]	rx_fifo_status,
    input		                                rx_fifo_status_empty,
    output reg		                            rx_fifo_status_read,

    // tx fifo interface to 1gb eth (for ack)
    output reg [AVL_SIZE-1:0] tx_fifo_data,
    output reg [2*BYTE_SIZE+IP_SIZE+MAC_SIZE-1:0] tx_fifo_status,
    output reg tx_fifo_data_write,
    output reg tx_fifo_status_write,
    input      tx_fifo_data_full,
    input      tx_fifo_status_full,

    //MODE selection
    output reg  mode_nCont_disc,
    output reg  mode_nRaw_dem,

    //parameters
    output reg [COMMAND_ONLY*BYTE_SIZE-1:0] frequency_initial,
    output reg [COMMAND_ONLY*BYTE_SIZE-1:0] frequency_final,
    output reg [63:0]                       frequency_step,
    output reg [COMMAND_ONLY*BYTE_SIZE-1:0] step_counter,
    output reg [15:0]                       wfm_amplitude,
    output reg [2:0] gain,
    output reg [15:0]                       dem_delay,

    //fifo parameters
    input           fifo_rd_clk,
    input           fifo_rd_ack,
    output [195:0]  fifo_rd_data,
    output          fifo_rd_empty,

    //acquisition mode commands
    output reg          start_fifo_cmd,
    output reg          start_dac_cmd,
    output reg          stop_dac_cmd,

    // DACs and ADC status 
    input   DAC_running, //FAST DAC running in a regime state (0 in soft start/stop)
    input   ADC_ready //ADC configured
);

// COMMAND LIST
// GENERAL COMMANDS:
localparam  SHOW_VERSION = 32'h5645_523F, //(VER?)
            START_DAC = 32'h4441_4347, //DAC GO (DACG)
            STOP_DAC = 32'h4441_4353, //DAC STOP (DACS)
            FREQUENCY_INITIAL = 32'h4652_494E, //Initial Frequency (FRIN)
            FREQUENCY_FINAL = 32'h4652_4649, //Final Frequency (FRFI)
            STEP_COUNTER = 32'h5354_434F, //Frequency Step (STCO)
            STEP_INCREMENT_MSB = 32'h5354_5031, //Step increment MSB (STP1) (Permanence per freq, used only if in discrete sweep)
            STEP_INCREMENT_LSB = 32'h5354_5032, //Step increment MSB (STP2) (Permanence per freq, used only if in discrete sweep)
            WFM_AMPLITUDE = 32'h5746_4D41, //Waveform amplitude in Q0.16 format (WFMA)
            SWEEP_MODE = 32'h5357_4D44, //Sweep mode (SWMD) high for discrete, low for continuous
            ACQUISITION_MODE = 32'h4143_4D44, //Acqusition mode (ACMD) high for demodulation, low for raw data
            DEM_DELAY = 32'h4445_4C59, //latency DAC -> ADC (DELY) 16 bit value of the delay
            GAIN = 32'h4741_494E, //digital gain for demodulation (GAIN) usefull for small signals in
            START_FROM_FIFO = 32'h5354_4646, //start the sweeps from the FIFO until it's empty (STFF)
            LOAD_FIFO = 32'h4C44_4646, //load one fifo word (LDFF)
            CLEAR_FIFO = 32'h434C_4646; //clear the fifo (CLFF)



// DECODER RX STATE MACHINE
localparam  RX_IDLE = 0,
            RX_READ_DATA = 1,
            RX_READ_DATA_1 = 2,
            RX_FLUSH = 3,
            RX_UNPACK_CMD = 4,
            RX_WAIT = 5,
            RX_EVAL = 6;

reg [2:0] RX_STATUS = RX_IDLE;

localparam  COMMAND_ONLY = 4,    //length of command: 32 bit - 4 bytes
            COMMAND_DATA = 8;    //length of command plus data: 32+32 - 8 bytes

reg [COMMAND_DATA*AVL_SIZE-1:0] rx_buffer; //received data buffer
reg [2*BYTE_SIZE-1:0] byte_counter; //received byte counter
reg [COMMAND_ONLY*BYTE_SIZE-1:0] received_cmd; //command part of the incoming data
reg [COMMAND_ONLY*BYTE_SIZE-1:0] received_data; //command part of the incoming data

reg with_data; //if the received command is with data or not
reg nak, ack, ver, err; //signals for the TX state machine

always @(posedge clk)
begin
	if(reset)
	begin
        rx_fifo_data_read <= 1'b0;
        rx_fifo_status_read <= 1'b0;

        source_mac <= {{MAC_SIZE}{1'b0}};
        source_ip <= {{IP_SIZE}{1'b0}};

        byte_counter <= 8'd0;

        with_data <= 1'b0;
        nak <= 1'b0;
        ack <= 1'b0;
        ver <= 1'b0;
        err <= 1'b0;
       
        mode_nCont_disc <= 0;
        mode_nRaw_dem <= 0;
        frequency_initial <= 0;
        frequency_final <= 0;
        frequency_step <= 0;
        step_counter <= 0;
        gain <= 0;
        dem_delay <= 1;
        start_fifo_cmd <= 0;
        start_dac_cmd <= 0;
        stop_dac_cmd <= 0;

        
        fifo_wr <= 1'b0;
        clr_fifo_cmd <= 1'b0;

        RX_STATUS <= RX_IDLE;
    end
    else
    begin
        case(RX_STATUS)

            RX_IDLE:
            begin
                nak <= 1'b0;
                ack <= 1'b0;
                ver <= 1'b0;
                err <= 1'b0;
                start_fifo_cmd <= 0;
                start_dac_cmd <= 0;
                stop_dac_cmd <= 0;
                fifo_wr <= 1'b0;
                clr_fifo_cmd <= 1'b0;
                if(!rx_fifo_status_empty) begin
                    rx_fifo_status_read <= 1'b1;
                    byte_counter <= rx_fifo_status[2*BYTE_SIZE+IP_SIZE+MAC_SIZE-1 -: 2*BYTE_SIZE];
                    source_ip <= rx_fifo_status[IP_SIZE+MAC_SIZE-1 -: IP_SIZE];
                    source_mac <= rx_fifo_status[MAC_SIZE-1 -: MAC_SIZE];
                    RX_STATUS <= RX_READ_DATA;
                end
            end

            RX_READ_DATA: //check if the command is with or without data while reading
            begin
                rx_fifo_status_read <= 1'b0;
                rx_fifo_data_read <= 1'b1;
                byte_counter <= byte_counter - 1'b1;

                if(byte_counter == COMMAND_ONLY) begin
                    with_data <= 1'b0;
                    RX_STATUS <= RX_READ_DATA_1;
                end
                else if (byte_counter == COMMAND_DATA) begin
                    with_data <= 1'b1;
                    RX_STATUS <= RX_READ_DATA_1;
                end
                else begin
                    RX_STATUS <= RX_FLUSH;
                end
            end

            RX_READ_DATA_1: //read the data from the RX FIFO
            begin
                if(byte_counter == 0) begin
                    rx_fifo_data_read <= 1'b0;
                    RX_STATUS <= RX_UNPACK_CMD;
                end
                                
                //shifting the register
                rx_buffer[COMMAND_DATA*AVL_SIZE-1:AVL_SIZE] <= rx_buffer[COMMAND_DATA*AVL_SIZE-AVL_SIZE-1:0];
                rx_buffer[AVL_SIZE-1:0] <= rx_fifo_data;
                
                byte_counter <= byte_counter - 1'b1;
            end

            RX_UNPACK_CMD: begin //unpack the received command and data
                rx_fifo_data_read <= 1'b0;
                if (with_data) received_cmd <= rx_buffer[COMMAND_DATA*AVL_SIZE-1 -: COMMAND_ONLY*AVL_SIZE];
                else received_cmd <= rx_buffer[COMMAND_ONLY*AVL_SIZE-1 : 0];
                received_data <= rx_buffer[COMMAND_ONLY*AVL_SIZE-1 : 0];
                RX_STATUS <= RX_WAIT;
            end

            RX_WAIT: begin //delay state to add a multicycle constraint to improve timing
                RX_STATUS <= RX_EVAL;
            end

            RX_EVAL: begin //evaluate the command
                RX_STATUS <= RX_IDLE;                
                case (received_cmd)
                //GENERAL COMMANDS
                    SHOW_VERSION: begin //return version
                        ver <= 1'b1;
                    end

                    START_DAC: begin //start the acquistion
                        if (!DAC_running && ADC_ready) begin
                            start_dac_cmd <= 1'b1;
                            ack <= 1'b1;
                        end
                        else begin
                            err <= 1'b1;
                        end
                    end

                    STOP_DAC: begin //stop the acquisition
                        if (DAC_running) begin
                            stop_dac_cmd <= 1'b1;
                            ack <= 1'b1;
                        end
                        else begin
                            err <= 1'b1;
                        end 
                    end

                    FREQUENCY_INITIAL: begin
                        if (with_data && !DAC_running) begin
                            frequency_initial <= received_data;
                            ack <= 1'b1;
                        end
                        else begin
                            err <= 1'b1;
                        end                
                    end

                    FREQUENCY_FINAL: begin
                        if (with_data && !DAC_running) begin
                            frequency_final <= received_data;
                            ack <= 1'b1;
                        end
                        else begin
                            err <= 1'b1;
                        end                
                    end

                    STEP_COUNTER: begin
                        if (with_data && !DAC_running) begin
                            step_counter <= received_data;
                            ack <= 1'b1;
                        end
                        else begin
                            err <= 1'b1;
                        end                
                    end

                    STEP_INCREMENT_MSB: begin
                        if (with_data && !DAC_running) begin
                            frequency_step[63-:32] <= received_data;
                            ack <= 1'b1;
                        end
                        else begin
                            err <= 1'b1;
                        end                
                    end 

                    STEP_INCREMENT_LSB: begin
                        if (with_data && !DAC_running) begin
                            frequency_step[31:0] <= received_data;
                            ack <= 1'b1;
                        end
                        else begin
                            err <= 1'b1;
                        end                
                    end 

                    WFM_AMPLITUDE: begin
                        if (with_data && !DAC_running) begin
                            wfm_amplitude <= received_data [15:0];
                            ack <= 1'b1;
                        end
                        else begin
                            err <= 1'b1;
                        end                
                    end

                    DEM_DELAY: begin
                        if (with_data && !DAC_running) begin
                            ack <= 1'b1;
                            dem_delay <= received_data[15:0];
                        end
                        else begin
                            err <= 1'b1;
                        end 
                    end

                    GAIN: begin
                        if (with_data && !DAC_running) begin
                            ack <= 1'b1;
                            gain <= received_data[2:0];
                        end
                        else begin
                            err <= 1'b1;
                        end 
                    end               

                    SWEEP_MODE: begin
                        if (!DAC_running && (&received_data || ~|received_data)) begin
                            ack <= 1'b1;
                            mode_nCont_disc <= received_data[31];
                        end
                        else begin
                            err <= 1'b1;
                        end 
                    end

                    ACQUISITION_MODE: begin
                        if (!DAC_running && (&received_data || ~|received_data)) begin
                            ack <= 1'b1;
                            mode_nRaw_dem <= received_data[31];
                        end
                        else begin
                            err <= 1'b1;
                        end 
                    end

                    START_FROM_FIFO: begin
                        if (!DAC_running && ADC_ready) begin
                            start_fifo_cmd <= 1'b1;
                            ack <= 1'b1;
                        end
                        else begin
                            err <= 1'b1;
                        end
                    end

                    LOAD_FIFO: begin
                        if (ADC_ready && !fifo_full) begin
                            fifo_wr <= 1'b1;
                            ack <= 1'b1;
                        end
                        else begin
                            err <= 1'b1;
                        end
                    end

                    CLEAR_FIFO: begin
                        if (!DAC_running) begin
                            clr_fifo_cmd <= 1'b1;
                            ack <= 1'b1;
                        end
                        else begin
                            err <= 1'b1;
                        end
                    end

                    default: 
                    begin
                        nak <= 1'b1;
                        ack <= 1'b0;
                        ver <= 1'b0;
                        err <= 1'b0;
                    end
                endcase
            end

            RX_FLUSH: //RX_flush the fifo if the received command has an unusual length
            begin
                if(byte_counter == 8'd0) begin
                    rx_fifo_data_read <= 1'b0;
                    nak <= 1'b1;
                    RX_STATUS <= RX_IDLE;
                end
                byte_counter <= byte_counter - 1'd1;
            end

            default:
            begin
                rx_fifo_data_read <= 1'b0;
                rx_fifo_status_read <= 1'b0;

                source_mac <= {{MAC_SIZE}{1'b0}};
                source_ip <= {{IP_SIZE}{1'b0}};

                byte_counter <= 8'd0;

                nak <= 1'b0;
                ack <= 1'b0;
                ver <= 1'b0;
                RX_STATUS <= RX_IDLE;
            end

        endcase
    end
end


reg clr_fifo_cmd;
reg fifo_wr;
wire fifo_full;


sweep_fifo	sweep_fifo_0 (
	.aclr ( clr_fifo_cmd ),

	.data ({16'd0, frequency_initial, frequency_final, frequency_step, step_counter, wfm_amplitude}),
	.wrclk ( clk ),
	.wrreq ( fifo_wr ),
	.wrfull ( fifo_full ),
	
    .rdclk ( fifo_rd_clk ),
	.rdreq ( fifo_rd_ack ),
	.q ( fifo_rd_data ),
	.rdempty ( fifo_rd_empty )
);

// DECODER TX STATE MACHINE

localparam 	    TX_IDLE = 0,
				TX_WRITE_DATA = 1;

reg [2:0] TX_STATUS = TX_IDLE;

// registers added to improve timing/separation between the state machines
reg nak_reg, ack_reg, ver_reg, err_reg;
always @(posedge clk ) begin
    if(reset)
	begin
        nak_reg <= 1'b0;
        ack_reg <= 1'b0;
        ver_reg <= 1'b0;
        err_reg <= 1'b0;
	end
    else begin
        nak_reg <= nak;
        ack_reg <= ack;
        ver_reg <= ver;
        err_reg <= err;
    end
end

localparam MAX_BYTES_TO_TRANSMIT = 16'd8;
reg [7:0] tx_buffer[0:MAX_BYTES_TO_TRANSMIT-1]; //transmission data buffer

reg [15:0] tx_counter  = 16'd0 ; //counter to scroll through the data to send
reg [15:0] tx_length  = 16'd0 ; //lenght of the data to sent

always @ (posedge clk)
begin
	if(reset)
	begin
		tx_fifo_status_write <= 1'b0;
		tx_fifo_data_write <= 1'b0;
		TX_STATUS <= TX_IDLE;
	end
	else
		case(TX_STATUS)
			TX_IDLE: begin //wait for what to send from the RX FSM
				tx_fifo_status_write <= 1'b0;
				if(ack_reg) begin
					tx_counter <= 16'd5;
                    tx_length <= 16'd5;
					tx_buffer[4] <= 8'd65;  // A
					tx_buffer[3] <= 8'd67;  // C
					tx_buffer[2] <= 8'd75;  // K
					tx_buffer[1] <= 8'd13;  // \r
					tx_buffer[0] <= 8'd10;  // \n
					TX_STATUS <= TX_WRITE_DATA;
				end
				else if(nak_reg) begin
					tx_counter <= 16'd5;
                    tx_length <= 16'd5;
					tx_buffer[4] <= 8'd78;  // N
					tx_buffer[3] <= 8'd65;  // A
					tx_buffer[2] <= 8'd75;  // K
					tx_buffer[1] <= 8'd13;  // \r
					tx_buffer[0] <= 8'd10;  // \n
					TX_STATUS <= TX_WRITE_DATA;
				end
				else if(ver_reg) begin
					tx_counter <= 16'd8;
                    tx_length <= 16'd8;
					tx_buffer[7] <= 8'h33;  // 3
					tx_buffer[6] <= 8'h2E;  // .
					tx_buffer[5] <= 8'h33;  // 3
					tx_buffer[4] <= 8'h45;  // E
                    tx_buffer[3] <= 8'h4C;  // L
					tx_buffer[2] <= 8'h45;  // E
					tx_buffer[1] <= 8'd13;  // \r
					tx_buffer[0] <= 8'd10;  // \n
					TX_STATUS <= TX_WRITE_DATA;
				end
                else if(err_reg) begin
					tx_counter <= 16'd5;
                    tx_length <= 16'd5;
					tx_buffer[4] <= 8'd69;  // E
					tx_buffer[3] <= 8'd82;  // R
					tx_buffer[2] <= 8'd82;  // R
					tx_buffer[1] <= 8'd13;  // \r
					tx_buffer[0] <= 8'd10;  // \n
					TX_STATUS <= TX_WRITE_DATA;
				end
			end

			TX_WRITE_DATA: begin //scroll through the buffer and write into the the TX fifos
				if(tx_counter == 8'd0) begin
					tx_fifo_data_write <= 1'b0;
					tx_fifo_status <= {tx_length, source_ip, source_mac}; //always answer to the last sender
					tx_fifo_status_write <= 1'b1;
					TX_STATUS <= TX_IDLE;
				end
				else begin
                    if (!tx_fifo_data_full) begin
                        tx_fifo_data_write <= 1'b1;
                        tx_fifo_data <= tx_buffer[tx_counter-1'b1];
                        tx_counter <= tx_counter - 1'b1;
                    end
                    else begin
                        tx_fifo_data_write <= 1'b0;
                    end					
				end
			end

			default: begin
				tx_fifo_status_write <= 1'b0;
				tx_fifo_data_write <= 1'b0;
				TX_STATUS <= TX_IDLE;
			end
		endcase
end
endmodule
