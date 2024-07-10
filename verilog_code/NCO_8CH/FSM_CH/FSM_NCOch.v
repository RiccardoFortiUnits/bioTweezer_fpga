module FSM_NCOch (
    input           clk_50,
    input           reset,

    //Commands
    input           start_cmd,
    input           stop_cmd,

    //controller status
    output reg      running,

    //Sweep FIFO
    input           clr_fifo_cmd,
    input           clk_udp,
    input [191:0]   sweep_data_udp,
    input           fifo_wr_udp,
    output          fifo_full_udp,

    //ADC sync
    output reg              XY_ch_acquire,
    //NCO signal
    output [79:0]    	    NCO_ch_parameters,
    output reg              NCO_ch_enable
);

wire [191:0] fifo_rd_data;
reg fifo_rd_ack;
wire fifo_rd_empty;

sweep_fifo	sweep_fifo_from_udp (
	.aclr ( clr_fifo_cmd ),
	.wrclk ( clk_udp ),
	.data ( sweep_data_udp ),
	.wrreq ( fifo_wr_udp ),
	.wrfull ( fifo_full_udp ),
	
    .rdclk ( clk_50 ),
	.q ( fifo_rd_data ),
	.rdreq ( fifo_rd_ack ),
	.rdempty ( fifo_rd_empty )
);

wire [15:0] wfm_amplitude_fifo = fifo_rd_data[15:0];
wire [31:0] number_of_clock_fifo = fifo_rd_data[47:16];
wire [63:0] frequency_step_fifo = fifo_rd_data[111:48];
wire [31:0] frequency_final_fifo = fifo_rd_data[143:112];
wire [31:0] frequency_initial_fifo = fifo_rd_data[175:144];

reg [15:0] wfm_amplitude;
reg [31:0] frequency_initial, frequency_final, number_of_clock;
reg [63:0] frequency_step;

////////////// MAIN FSM /////////////

localparam  MAIN_IDLE = 0,
            MAIN_WAIT_FB = 1,
            MAIN_RUNNING = 2,
            MAIN_ENDING = 3,
            MAIN_END = 4,
            MAIN_WAIT_RESET = 5;

reg [2:0] FSM_main;

reg [31:0] step_counter;
reg [63:0] clock_counter;
reg signed [63:0] freq_modulation;

always @(posedge clk_50 ) begin
    if (reset) begin
        NCO_ch_enable <= 1'b0;      
        XY_ch_acquire <= 1'b0;
        freq_modulation <= 0;
        step_counter <= 0;
        clock_counter <= 0;
        running <= 1'b0;
        FSM_main <= MAIN_IDLE;
    end
    else begin
        case (FSM_main)
            MAIN_IDLE: begin
                running <= 1'b0;
                XY_ch_acquire <= 1'b0;  
                freq_modulation <= 0;
                frequency_initial <= 0;
                if (start_cmd && !fifo_rd_empty) begin //if there is a start commanda and the fifo is not empty start
                    running <= 1'b1;
                    FSM_main <= MAIN_RUNNING;
                    NCO_ch_enable <= 1'b1;
                    frequency_initial <= frequency_initial_fifo;
                    frequency_final <= frequency_final_fifo;
                    frequency_step <= frequency_step_fifo;
                    number_of_clock <= number_of_clock_fifo;
                    wfm_amplitude <= wfm_amplitude_fifo;
                    step_counter <= 0;
                    fifo_rd_ack <= 1'b1;
                end
            end 
            MAIN_RUNNING: begin
                fifo_rd_ack <= 1'b0;
                clock_counter <= clock_counter + 1; //keep incrementin the clock counter that the frequency has to be kept
                XY_ch_acquire <= 1'b0;
                if (stop_cmd) begin //if there is a stop siglan disable the channel
                    NCO_ch_enable <= 1'b0;
                    FSM_main <= MAIN_IDLE;
                end
                else if (start_cmd && !fifo_rd_empty) begin //if there is a start commanda and the fifo is not empty start
                    frequency_initial <= frequency_initial_fifo;
                    frequency_final <= frequency_final_fifo;
                    frequency_step <= frequency_step_fifo;
                    number_of_clock <= number_of_clock_fifo;
                    wfm_amplitude <= wfm_amplitude_fifo;
                    step_counter <= 0;
                    fifo_rd_ack <= 1'b1;
                end
                else if (clock_counter == number_of_clock - 2) begin
                    XY_ch_acquire <= 1'b1;                              //acquire the current X and Y outputs of the lockin just before freq change
                end
                else if (clock_counter == number_of_clock - 1) begin //if we have to change the frequency modulation
                    clock_counter <= 0;                                 //bring the counter to 0
                    if (step_counter == frequency_final - 1) begin      //if we are at the last step of the current sweep
                        if (!fifo_rd_empty) begin                           //if there is a scheduled sweep in the FIFO do that
                            frequency_initial <= frequency_initial_fifo;
                            frequency_final <= frequency_final_fifo;
                            frequency_step <= frequency_step_fifo;
                            number_of_clock <= number_of_clock_fifo;
                            wfm_amplitude <= wfm_amplitude_fifo;
					        freq_modulation <= 0;
                            step_counter <= 0;
                            fifo_rd_ack <= 1'b1;
                        end
                        else begin                                          //if there is no pending sweep the scan has ended
                            NCO_ch_enable <= 1'b0;                          //in this case the current X Y acquire is done by the adc_acquire falling edge
                            FSM_main <= MAIN_IDLE;
                        end                        
                    end
                    else begin                                          //if we weren't at the last step change the FM and increment the step
                        freq_modulation <= freq_modulation + frequency_step;
                        step_counter <= step_counter + 1;
                    end                        
                end
            end
        endcase
    end
end

assign NCO_ch_parameters = {frequency_initial, freq_modulation[63-:32], wfm_amplitude};

endmodule