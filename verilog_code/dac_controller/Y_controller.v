module Y_controller #(parameter BYTE_SIZE = 8,
                    COUNTER_TH = 2000,
                    DAC_BYTES = 2,
                    DAC_CHANNELS = 1,
                    MEMORY_WORDS = 2048)
(
    input	        clk,
    input           reset,

    input start_cmd,
    input start_Y,    
    input stop_cmd,
    input [15:0] Y_pixel, 
    input [31:0] Y_increment_step,  
    //DAC writing:
    input dac_busy,
    output reg dac_start = 1'b0,
    output [DAC_BYTES*BYTE_SIZE-1:0] dac_data,
    //Y sync commands:
    output reg stop_XZ,
    input pos_peak_period,
    input neg_peak_period,
    //controller status:
    output running,
    output stopped,
    output reg ADC_acquire = 1'b0
);

assign stopped = (STATE == IDLE);
assign running = (STATE == ACQUISITION);

localparam  IDLE = 0,
            WAIT_SYNC = 2,
            ACQUISITION = 3,
            WAIT_STOP = 4,
            WAIT_STOP1 = 5,
            STOP_RAMP = 6,
            PRE_SYNC_NORAMP = 7,
            WAIT_STOP2 = 8;

reg [3:0] STATE = IDLE;

reg start_write = 1'b0;
reg stop_write = 1'b0;
reg [15:0] Y_pixel_counter;
reg [39:0] data_accumulator;
reg direction; //1'b1 for increment and 1'b0 for decrement

reg [15:0] ramp_counter;

always @(posedge clk ) begin
    if (reset) begin
        STATE <= IDLE;
        stop_write <= 1'b0;
        start_write <= 1'b0;
        stop_XZ <= 1'b0; 
    end
    else begin
        case (STATE)
            IDLE: begin
                stop_write <= 1'b0;
                start_write <= 1'b0;
                stop_XZ <= 1'b0;               
                if (start_cmd) begin
                    STATE <= PRE_SYNC_NORAMP;                        
                end                
            end
            PRE_SYNC_NORAMP: begin
                if (start_Y) begin
                    STATE <= WAIT_SYNC;
                end
            end
            WAIT_SYNC: begin
                if (~Y_pixel[0] && pos_peak_period) begin //if even number of pixel wait positive peak
                    start_write <= 1'b1;
                    STATE <= ACQUISITION;
                end
                else if (Y_pixel[0] && neg_peak_period) begin //if odd number of pixel wait negative peak
                    start_write <= 1'b1;
                    STATE <= ACQUISITION;
                end
            end
            ACQUISITION: begin
                start_write <= 1'b0;
                if (stop_cmd == 1'b1) begin
                    STATE <= WAIT_STOP;
                end  
            end
            WAIT_STOP: begin
                if (ADC_acquire == 1'b0) begin
                    STATE <= WAIT_STOP1;
                end
            end
            WAIT_STOP1: begin                
                if (data_accumulator == 40'h8000000000) begin
                    STATE <= IDLE;
                    stop_write <= 1'b1;
                    stop_XZ <= 1'b1;
                end
            end
            default: begin
                STATE <= IDLE;
            end
        endcase
    end
end

//global memory adress counter
localparam  DISABLED = 0,
            WRITE = 1,
            UPDATE_VALUE = 2;

reg [2:0] STATE_DAC = DISABLED;

reg [15:0] mem_counter;

always @(posedge clk ) begin
    if (reset) begin
        STATE_DAC <= DISABLED;
        data_accumulator <= 40'h8000000000;
        ADC_acquire <= 1'b0;
        dac_start <= 1'b0;  
    end
    else begin
        case (STATE_DAC)
            DISABLED: begin        
                ADC_acquire <= 1'b0;        
                data_accumulator <= 40'h8000000000;
                dac_start <= 1'b0; 
                //Y_pixel_counter <= ((Y_pixel >> 1) - (~(Y_pixel[0]))); 
                if (Y_pixel[0]) Y_pixel_counter <= (Y_pixel >> 1);
                else Y_pixel_counter <= ((Y_pixel >> 1) - 1'b1);
                direction <= 1'b1;
                if (start_write == 1'b1) begin
                    STATE_DAC <= WRITE;
                end
            end
            WRITE: begin
                if (stop_write == 1'b1) begin
                     STATE_DAC <= DISABLED;
                end         
                else if (!dac_busy) begin
                    dac_start <= 1'b1;                    
                    STATE_DAC <= UPDATE_VALUE;
                end
            end
            UPDATE_VALUE: begin
                dac_start <= 1'b0;
                if (pos_peak_period) begin
                    if (Y_pixel_counter == 16'd0) begin;
                        if(direction) begin
                            if (stop_cmd == 1'b1 || STATE == WAIT_STOP) begin
                                ADC_acquire <= 1'b0;
                            end 
                            else begin
                                ADC_acquire <= 1'b1;
                            end                            
                        end
                        Y_pixel_counter <= Y_pixel - 1'b1;
                        direction <= ~direction;
                    end
                    else begin
                        Y_pixel_counter <= Y_pixel_counter - 1'b1;
                    end
                end
                if (direction) begin
                    data_accumulator <= data_accumulator + Y_increment_step;
                end
                else begin
                    data_accumulator <= data_accumulator - Y_increment_step;
                end
                STATE_DAC <= WRITE;
            end
            default: begin
                STATE_DAC <= DISABLED;
            end
        endcase
    end
end

assign dac_data = data_accumulator[39:24];

endmodule