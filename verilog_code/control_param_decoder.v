module control_param_decoder #(
    //the codes for the registers are ordered in this manner:
        //code 0 not used
        //all large registers, MSB code 2*i +1, LSB code 2*(i+1)
        //all small registers, code nOflargeRegisters*2+1+j
        parameter largeRegisterStartIdxs = {64, 32, 0},
        parameter nOflargeRegisters = 2,
        parameter smallRegisterStartIdxs = {64, 48, 32, 16, 0},
        parameter nOfsmallRegisters = 4,
        parameter maxTransmissionSize = 16

`define largeRegisterStart(registerIdx) largeRegisterStartIdxs[(registerIdx+1) * 32 -1-:32]
`define smallRegisterStart(registerIdx) smallRegisterStartIdxs[(registerIdx+1) * 32 -1-:32]
)(
    input clk,
    input reset,

    input [31:0] received_data,
    input        received_control_param_valid,

    input wipe_settings,

    output reg ack,
    output reg nak,
    output reg err,

    //----------------------------------------------------------------
    // pi CONTROL PARAMETERS
    output reg [`largeRegisterStart(nOflargeRegisters) -1:0] largeRegisters,
    output reg [nOflargeRegisters -1:0] largeRegisters_update_cmd,
    output reg [`smallRegisterStart(nOfsmallRegisters) -1:0] smallRegisters,
    output reg [nOfsmallRegisters -1:0] smallRegisters_update_cmd,

    //----------------------------------------------------------------
    output control_param_written
);

//-------------------------------------------------------------------------------------------------------------------------------
// CONTROL PARAMETERS LIST:
localparam  largeRegistersStartDataControl = 1,
            smallRegistersStartDataControl = nOflargeRegisters * 2 + largeRegistersStartDataControl;
//-------------------------------------------------------------------------------------------------------------------------------

// STATE MACHINE
localparam  IDLE = 0,
            EVAL = 1,
            CHECK_NAK = 2;

reg [1:0] STATE = IDLE;

reg [nOflargeRegisters -1:0] largeRegister_LSB_written, largeRegister_MSB_written;
reg [nOfsmallRegisters -1:0] smallRegister_written;

assign control_param_written = (&largeRegister_LSB_written) & (&largeRegister_MSB_written) & (&smallRegister_written);


reg [nOflargeRegisters -1:0] largeRegister_LSB_updateCmd, largeRegister_MSB_updateCmd;
                              

//-------------------------------------------------------------------------------------------------------------------------------
// SWEEP F PARAMETERS DECODING AND RESET
integer i,j;
always @(posedge clk) 
begin
    if (reset || wipe_settings) 
    begin        
        largeRegisters                 <= 0;
        largeRegisters_update_cmd      <= 0;
        largeRegister_LSB_updateCmd    <= 0;
        largeRegister_MSB_updateCmd    <= 0;
        smallRegisters                 <= 0;
        smallRegisters_update_cmd      <= 0;
        largeRegister_LSB_written      <= 0;
        largeRegister_MSB_written      <= 0;
        smallRegister_written          <= 0;

        STATE <= IDLE;  
    end
    else 
    begin
        case (STATE)
            IDLE: 
            begin
                smallRegisters_update_cmd <= 0;
                largeRegisters_update_cmd <= (largeRegister_LSB_updateCmd & largeRegister_MSB_updateCmd);
                largeRegister_LSB_updateCmd <= largeRegister_LSB_updateCmd & (~largeRegister_MSB_updateCmd);
                largeRegister_MSB_updateCmd <= largeRegister_MSB_updateCmd & (~largeRegister_LSB_updateCmd);

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
                STATE <= CHECK_NAK;

                for(i=0;i<nOflargeRegisters;i=i+1)begin
                    //large registers MSB
                    if(received_data[31-:8] == i*2+largeRegistersStartDataControl)begin
                        for(j=maxTransmissionSize;j<`largeRegisterStart(i+1)-`largeRegisterStart(i);j=j+1)begin
                            largeRegisters[`largeRegisterStart(i)+j] <= received_data[j-maxTransmissionSize];
                        end
                        largeRegister_MSB_updateCmd[i] <= 1'b1;
                        largeRegister_MSB_written    <= 1'b1;
                        ack <= 1'b1;
                    end
                    //large registers LSB
                    if(received_data[31-:8] == i*2+largeRegistersStartDataControl+1)begin
                        for(j=0;j<maxTransmissionSize;j=j+1)begin
                            largeRegisters[`largeRegisterStart(i)+j] <= received_data[j];
                        end
                        largeRegister_LSB_updateCmd[i] <= 1'b1;
                        largeRegister_LSB_written    <= 1'b1;
                        ack <= 1'b1;
                    end
                end
                for (i=0;i<nOfsmallRegisters;i=i+1) begin                    
                    //small registers
                    if(received_data[31-:8] == i+smallRegistersStartDataControl)begin
                        for(j=0;j<`smallRegisterStart(i+1)-`smallRegisterStart(i);j=j+1)begin
                            smallRegisters[`smallRegisterStart(i)+j] <= received_data[j];
                        end
                        smallRegisters_update_cmd[i] <= 1'b1;
                        smallRegister_written    <= 1'b1;
                        ack <= 1'b1;
                    end
                end
            end
            CHECK_NAK:
            begin
                STATE <= IDLE;
                if(!(ack | err))begin
                    nak <= 1'b1;
                end
            end
            
            default: 
            begin
                STATE <= IDLE;                     
            end
        endcase
    end
end

// generate
//     genvar gi, gj;
//     for(gi=0;gi<nOflargeRegisters;gi=gi+1)begin
//         for(gj=maxTransmissionSize;gj<`largeRegisterStart(gi+1)-`largeRegisterStart(gi);gj=gj+1)begin
//             always @(posedge clk) begin
//                 if(reset || STATE == IDLE) begin
//                     largeRegisters[`largeRegisterStart(i)+gj] <= 0;
//                 end else begin
//                     largeRegisters[`largeRegisterStart(i)+gj] <=  received_data[31-:8] == gi*2+largeRegistersStartDataControl ? received_data[gj] : 0;
//                 end
//             end
//         end
//     end
// endgenerate

endmodule
