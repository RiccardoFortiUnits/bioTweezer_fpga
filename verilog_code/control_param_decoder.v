module control_param_decoder #(
        parameter signalBitSize = 16,
        parameter signalFracSize = signalBitSize - 1,
        parameter coeffBitSize = 20,
        parameter coeffFracSize = coeffBitSize - 1
        
)(
    input clk,
    input reset,
    input DAC_stopped,  

    input [31:0] received_data,
    input        received_control_param_valid,

    input wipe_settings,//todo: questo comando resetta i valori, ma non avvisa i moduli successivi di aggiornare i valori, quindi non c'è alcun effetto

    output reg control_data,

    output reg ack,
    output reg nak,
    output reg err,

    //----------------------------------------------------------------
    // pi CONTROL PARAMETERS
    output reg [coeffBitSize -1:0] pi_kp_coefficient,
    output reg        pi_kp_coefficient_update_cmd,
    output reg [coeffBitSize -1:0] pi_ti_coefficient,
    output reg        pi_ti_coefficient_update_cmd,
    output reg [coeffBitSize -1:0] pi_setpoint,
    output reg        pi_setpoint_update_cmd,
    output reg [signalBitSize -1:0] pi_limit_HI,
    output reg [signalBitSize -1:0] pi_limit_LO,

    //----------------------------------------------------------------

    output control_param_written
);

//-------------------------------------------------------------------------------------------------------------------------------
// CONTROL PARAMETERS LIST:
localparam  pi_KP_COEFF_MSB = 8'h01,
            pi_KP_COEFF_LSB = 8'h02,
            pi_TI_COEFF_MSB = 8'h03,
            pi_TI_COEFF_LSB = 8'h04,
            pi_SETPOINT     = 8'h05,
            pi_LIMIT_HI     = 8'h07,
            pi_LIMIT_LO     = 8'h08;
//-------------------------------------------------------------------------------------------------------------------------------

// STATE MACHINE
localparam  IDLE = 0,
            EVAL = 1;

reg [1:0] STATE = IDLE;

reg pi_kp_coefficient_MSB_written, pi_kp_coefficient_LSB_written, pi_ti_coefficient_MSB_written, pi_ti_coefficient_LSB_written;
reg pi_setpoint_written, pi_limit_HI_written, pi_limit_LO_written;




reg pi_kp_coefficient_MSB_update_cmd, pi_kp_coefficient_LSB_update_cmd, pi_ti_coefficient_MSB_update_cmd, pi_ti_coefficient_LSB_update_cmd;
reg pi_setpoint_MSB_update_cmd, pi_setpoint_LSB_update_cmd;



assign control_param_written = pi_kp_coefficient_MSB_written & pi_kp_coefficient_LSB_written & pi_ti_coefficient_MSB_written & pi_ti_coefficient_LSB_written 
                               & pi_setpoint_written & pi_limit_HI_written & pi_limit_LO_written;
                              

//-------------------------------------------------------------------------------------------------------------------------------
// SWEEP F PARAMETERS DECODING AND RESET

always @(posedge clk) 
begin
    if (reset || wipe_settings) 
    begin        
        pi_kp_coefficient  <= 27'd0;
        pi_ti_coefficient  <= 27'd0;
        pi_setpoint        <= 27'd0;
        pi_limit_HI        <= 14'd0;
        pi_limit_LO        <= 14'd0;
        pi_kp_coefficient_MSB_written              <= 1'b0;
        pi_kp_coefficient_LSB_written              <= 1'b0;
        pi_ti_coefficient_MSB_written              <= 1'b0;
        pi_ti_coefficient_LSB_written              <= 1'b0;
        pi_setpoint_written                        <= 1'b0;
        pi_limit_HI_written                        <= 1'b0;
        pi_limit_LO_written                        <= 1'b0;
        pi_kp_coefficient_update_cmd               <= 1'b0;
        pi_kp_coefficient_MSB_update_cmd           <= 1'b0;
        pi_kp_coefficient_LSB_update_cmd           <= 1'b0;
        pi_ti_coefficient_update_cmd               <= 1'b0;
        pi_ti_coefficient_MSB_update_cmd           <= 1'b0;
        pi_ti_coefficient_LSB_update_cmd           <= 1'b0;
        pi_setpoint_update_cmd                     <= 1'b0;
        pi_setpoint_MSB_update_cmd                 <= 1'b0;
        pi_setpoint_LSB_update_cmd                 <= 1'b0;

        STATE <= IDLE;  
    end
    else 
    begin
        case (STATE)
            IDLE: 
            begin
                pi_kp_coefficient_update_cmd           <= 1'b0;
                pi_ti_coefficient_update_cmd           <= 1'b0;
                pi_setpoint_update_cmd                 <= 1'b0;
               

                if (pi_kp_coefficient_MSB_update_cmd && pi_kp_coefficient_LSB_update_cmd)
                begin
                    pi_kp_coefficient_update_cmd     <= 1'b1;
                    pi_kp_coefficient_MSB_update_cmd <= 1'b0;
                    pi_kp_coefficient_LSB_update_cmd <= 1'b0;
                end
                else
                begin
                    pi_kp_coefficient_update_cmd     <= 1'b0;
                end

                if (pi_ti_coefficient_MSB_update_cmd && pi_ti_coefficient_LSB_update_cmd)
                begin
                    pi_ti_coefficient_update_cmd     <= 1'b1;
                    pi_ti_coefficient_MSB_update_cmd <= 1'b0;
                    pi_ti_coefficient_LSB_update_cmd <= 1'b0;
                end
                else
                begin
                    pi_ti_coefficient_update_cmd     <= 1'b0;
                end

                if (received_control_param_valid) 
                begin
                    STATE <= EVAL;
                end
                else
                begin
                    STATE <= IDLE;
                end
            
                ack <= 1'b0;
                nak <= 1'b0;
                err <= 1'b0;
            end

            EVAL: 
            begin
                STATE <= IDLE;
                case (received_data[31-:8])
`define updateGeneric(state, register, BitSize, offset, update_cmd, written)       \
    state:                                                                                                              \
    begin                                                                                                               \
        register[BitSize -1:offset] <= received_data[BitSize-offset -1:0]; \
        update_cmd <= 1'b1;                                                                                 \
        written    <= 1'b1;                                                                                 \
        ack <= 1'b1;                                                                                                \
    end
`define updateMSB(state, register, BitSize, MSB_update_cmd, MSB_written) `updateGeneric(state, register, BitSize, 16, MSB_update_cmd, MSB_written)
`define updateLSB(state, register, LSB_update_cmd, LSB_written) `updateGeneric(state, register, 16, 0, LSB_update_cmd, LSB_written)
`define update(state, register, BitSize, LSB_update_cmd, LSB_written) `updateGeneric(state, register, BitSize, 0, LSB_update_cmd, LSB_written)
                        
                    `updateMSB(pi_KP_COEFF_MSB, pi_kp_coefficient, coeffBitSize, pi_kp_coefficient_MSB_update_cmd, pi_kp_coefficient_MSB_written)
                    `updateLSB(pi_KP_COEFF_LSB, pi_kp_coefficient, pi_kp_coefficient_LSB_update_cmd, pi_kp_coefficient_LSB_written)

                    `updateMSB(pi_TI_COEFF_MSB, pi_ti_coefficient, coeffBitSize, pi_ti_coefficient_MSB_update_cmd, pi_ti_coefficient_MSB_written)
                    `updateLSB(pi_TI_COEFF_LSB, pi_ti_coefficient, pi_ti_coefficient_LSB_update_cmd, pi_ti_coefficient_LSB_written)
                    `update(pi_SETPOINT, pi_setpoint, signalBitSize, pi_setpoint_update_cmd, pi_setpoint_written)

`define update_checkDAC_stopped(state, register, BitSize, written)       \
    state:															\
    begin															\
        if (DAC_stopped) 											\
        begin														\
            register[BitSize -1:0] <= received_data[BitSize -1:0];	\
            written <= 1'b1;										\
            ack <= 1'b1;											\
        end															\
        else														\
            err <= 1'b1;											\
    end
                    `update_checkDAC_stopped(pi_LIMIT_HI, pi_limit_HI, signalBitSize, pi_limit_HI_written)
                    `update_checkDAC_stopped(pi_LIMIT_LO, pi_limit_LO, signalBitSize, pi_limit_LO_written)

                    default: 
                    begin
                        nak <= 1'b1;                        
                    end
                    
                endcase
            end

            default: 
            begin
                STATE <= IDLE;                     
            end
        endcase
    end
end

endmodule
