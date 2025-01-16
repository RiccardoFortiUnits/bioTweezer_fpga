/*sends 2 types of data:
    fastData: sent as soon as it is written in the fifo (one word per transmission)
    slowData: sent when the fifo is filling up (maxSlowWordsPerTransission), or with the next fastData
*/
module dec_comm8_FastAndSlowData #(
    parameter AVL_SIZE    = 8,
              BYTE_SIZE   = 8,
              IP_SIZE     = 32,
              MAC_SIZE    = 48,
              fastDataWordSize = 16,
              slowDataWordSize = 28,
              maxSlowWordsPerTransission = 4
) (
    input clk,   // clock 125 MHz (rx_xcvr_clk)
    input reset, // !mac_configured_125 from eth_1gb_wrapper.v
    
    //----------------------------------------------------------------
    // TX FIFO INTERFACE TO 1GB ETHERNET
    output reg [AVL_SIZE-1:0]                         tx_fifo_data,
    output reg [2*BYTE_SIZE + IP_SIZE + MAC_SIZE-1:0] tx_fifo_status,
    output reg tx_fifo_data_write,
    output reg tx_fifo_status_write,
    input      tx_fifo_data_full,
    input      tx_fifo_status_full,

    input [MAC_SIZE-1:0] destination_mac,
    input [IP_SIZE-1:0]  destination_ip,
    //----------------------------------------------------------------

    input [fastDataWordSize -1:0] fastDataWord,
    input fastDataReady,

    output reg requestFastData,
    input [slowDataWordSize -1:0] slowDataWord,
    input slowDataReady,
    output reg requestSlowData
    //----------------------------------------------------------------
);

//-------------------------------------------------------------------------------------------------------------------------------
// DECODER TX STATE MACHINE
localparam  s_idle = 0,
            s_header = 1,
            s_fastData = 2,
            s_slowData = 3,
            s_transmit = 4;
reg [3:0] state;

reg readSlowData;

localparam  nOfFastBytes = (fastDataWordSize                              + BYTE_SIZE - 1) / BYTE_SIZE,
            nOfSlowBytes = (slowDataWordSize * maxSlowWordsPerTransission + BYTE_SIZE - 1) / BYTE_SIZE,
            max_nOfBytes = $unsigned(nOfFastBytes) > $unsigned(nOfSlowBytes) ? nOfFastBytes : nOfSlowBytes;

localparam slowWordBufferSize = nOfSlowBytes * BYTE_SIZE;//let's add some more bits, so that the number of bits is byte-aligned
reg [slowWordBufferSize -1:0] allSlowWords;
reg [$clog2(maxSlowWordsPerTransission+1) -1:0] slowWordCounter;

wire isSlowBufferFull = $unsigned(slowWordCounter) >= $unsigned(maxSlowWordsPerTransission);
wire isSlowBufferEmpty = slowWordCounter == 0;
reg sendFastData, sendSlowData;
localparam  tr_all = 'b11,
            tr_fastData = 'b01,
            tr_slowData = 'b10;
wire [1:0] transmissionType = {sendSlowData, sendFastData};
reg [$clog2(maxSlowWordsPerTransission+1) -1:0] nOfSlowWordsToSend;

reg [$clog2(max_nOfBytes * BYTE_SIZE)+1 -1:0] byte_counter;//let's avoid problems when we compare this value with a value with a bigger byte size
wire [$clog2(max_nOfBytes * BYTE_SIZE)+1 -1:0] slowBitsToSend = (nOfSlowWordsToSend * slowDataWordSize);//we don't give this value in bytes, otherwise we would have to do a division by BYTE_SIZE. 
                                                                                            //I don't trust the compiler in simplifying that, so I'm gonna just multiply the other numbers by BYTE_SIZE
 
always @(posedge clk) begin
    if (reset) begin
        state <= s_idle;
        requestFastData <= 0;
        requestSlowData <= 0;
        readSlowData <= 0;
        allSlowWords <= 0;
        slowWordCounter <= 0;
        nOfSlowWordsToSend <= 0;
        byte_counter <= 0;
        tx_fifo_data_write <= 0;
        tx_fifo_status_write <= 0;
        tx_fifo_data <= 0;
        tx_fifo_status <= 0;
        sendFastData <= 0;
        sendSlowData <= 0;
    end else begin
        //setup reading of the next slow word. If some data is ready, we'll read it on the next 2 cycles. We can start the reading of a 
            //new word if we're in idle state, and eventually we can finish a reading that has been started while we were in idle.
            //I put this section outside of the main state machine because the reading can happen at any time of the first part of the 
            //state machine. So, the alternative would have been to add this procedure to many of the states of the main machine
        if(state == s_idle || requestSlowData || readSlowData || s_transmit) begin
            //while in idle state, let's keep reading slow words (if available)
            if(state == s_idle && slowDataReady && !(requestSlowData || readSlowData))begin//word available? (and we're not already reading another one?)
                //let's read it in the next clock cycle
                requestSlowData <= 1;
            end else if (requestSlowData) begin//have we asked for a word in the previous clock cycle?
                //next cycle, the word will be ready
                requestSlowData <= 0;
                readSlowData <= 1;
            end else if(readSlowData) begin                        
                //add the new word to the buffer
                allSlowWords[(slowWordCounter + 1) * slowDataWordSize -1-:slowDataWordSize] <= slowDataWord;
                slowWordCounter <= slowWordCounter + 1;
                readSlowData <= 0;
            end else if (state == s_transmit)begin
                //let's reset the word counter
                slowWordCounter <= slowWordCounter - nOfSlowWordsToSend;//instead of setting it to 0, let's remove the number of sent words, since we might have read an extra word during the last transmission
            end
        end

        case(state)
            s_idle:begin
                tx_fifo_data_write   <= 0;
                tx_fifo_status_write <= 0;
                if(fastDataReady || isSlowBufferFull)begin
                    state <= s_header;
                    //save the current value of the fifos (in case there's new data arriving during the transmission)
                    sendFastData <= fastDataReady;
                    sendSlowData <= ! isSlowBufferEmpty;
                    nOfSlowWordsToSend <= isSlowBufferFull ? maxSlowWordsPerTransission : slowWordCounter;
                    // rdreq_all_fifos <= 1;//request the next bunch of data
                    requestFastData <= fastDataReady;
                end else begin
                    requestFastData <= 0;                    
                end
            end
            s_header:begin
                state <= sendFastData ? s_fastData : s_slowData;//put fast data first (if available)
                tx_fifo_data_write <= 1;
                tx_fifo_data       <= {nOfSlowWordsToSend, transmissionType};//header: typeof data and number of slow words
                
                requestFastData <= 0;
            end
            s_fastData:begin
                if(tx_fifo_data_full)begin
                    //wait until the fifo gets a bit empty
                    tx_fifo_data_write <= 0;
                end else begin
                    tx_fifo_data_write <= 1;
                    tx_fifo_data <= fastDataWord[(byte_counter + 1) * BYTE_SIZE -1-:BYTE_SIZE];//send the current byte of the current fifo
                    if (byte_counter < nOfFastBytes-1)begin//word not read completely?
                        byte_counter <= byte_counter + 1;//read the next byte
                    end else begin
                        state <= sendSlowData ? s_slowData : s_transmit;
                        byte_counter <= 0;
                    end
                end
            end
            s_slowData:begin
                if(tx_fifo_data_full)begin
                    //wait until the fifo gets a bit empty
                    tx_fifo_data_write <= 0;
                end else begin
                    tx_fifo_data_write <= 1;
                    tx_fifo_data       <= allSlowWords[(byte_counter + 1) * BYTE_SIZE -1-:BYTE_SIZE];//send the current byte of the current fifo

                    byte_counter <= byte_counter + 1;//read the next byte
                    if ($unsigned((byte_counter + 1) * BYTE_SIZE) >= $unsigned(slowBitsToSend))begin//word read completely?
                        state <= s_transmit;//let's not reset byte_counter, we'll use its value to know how many bytes we sent
                    end
                end
            end
            s_transmit:begin
                tx_fifo_data_write <= 0;
                if(tx_fifo_status_full)begin
                    //wait until the fifo gets a bit empty
                    tx_fifo_status_write <= 0;
                end else begin
                    //no need to check for sendSlowData, because if there's no slow word, byte_counter was reset during s_fastData, otherwise it is holding the number of bits given by s_slowData
                    tx_fifo_status <= {byte_counter + (sendFastData ? nOfFastBytes : 0) + 1, destination_ip, destination_mac};//set the status (nOf bytes to transmit, IP and MAC address)
                    tx_fifo_status_write <= 1;//initiate the transmission

                    byte_counter <= 0;
                    state <= s_idle;
                end
            end
        endcase
    end
end


endmodule


/*


add wave -position insertpoint sim:/dec_comm8_FastAndSlowData/*
force -freeze sim:/dec_comm8_FastAndSlowData/clk 1 0, 0 {50 ps} -r 100
force -freeze sim:/dec_comm8_FastAndSlowData/reset z1 0
force -freeze sim:/dec_comm8_FastAndSlowData/tx_fifo_data_full z0 0
force -freeze sim:/dec_comm8_FastAndSlowData/tx_fifo_status_full z0 0
force -freeze sim:/dec_comm8_FastAndSlowData/destination_mac EEEEEEEEEEEEE 0
force -freeze sim:/dec_comm8_FastAndSlowData/destination_ip DDDDDDDDDDDDDD 0
force -freeze sim:/dec_comm8_FastAndSlowData/fastDataWord 0 0
force -freeze sim:/dec_comm8_FastAndSlowData/fastDataReady 0 0
force -freeze sim:/dec_comm8_FastAndSlowData/slowDataWord 0 0
force -freeze sim:/dec_comm8_FastAndSlowData/slowDataReady 0 0
run
# add 3 values to the slow data, then add a fast word
force -freeze sim:/dec_comm8_FastAndSlowData/reset 10 0
run
force -freeze sim:/dec_comm8_FastAndSlowData/slowDataReady 01 0
run
run
force -freeze sim:/dec_comm8_FastAndSlowData/slowDataWord 3456789 0
force -freeze sim:/dec_comm8_FastAndSlowData/slowDataReady 10 0
run
run
force -freeze sim:/dec_comm8_FastAndSlowData/slowDataReady 01 0
run
run
force -freeze sim:/dec_comm8_FastAndSlowData/slowDataWord 2345678 0
force -freeze sim:/dec_comm8_FastAndSlowData/slowDataReady 10 0
run
run
force -freeze sim:/dec_comm8_FastAndSlowData/slowDataReady 01 0
run
run
force -freeze sim:/dec_comm8_FastAndSlowData/slowDataWord 1234567 0
force -freeze sim:/dec_comm8_FastAndSlowData/slowDataReady 10 0
run
run
force -freeze sim:/dec_comm8_FastAndSlowData/fastDataReady 01 0
run
run
force -freeze sim:/dec_comm8_FastAndSlowData/fastDataWord 5432 0
force -freeze sim:/dec_comm8_FastAndSlowData/fastDataReady 10 0
run
run
run
run
run
run
run
run
run
# test, send a slow word, and a fast word while the slow word is being read
force -freeze sim:/dec_comm8_FastAndSlowData/slowDataReady 01 0
force -freeze sim:/dec_comm8_FastAndSlowData/fastDataReady 01 0
run
run
force -freeze sim:/dec_comm8_FastAndSlowData/slowDataWord 3123456 0
force -freeze sim:/dec_comm8_FastAndSlowData/fastDataReady 0 0
force -freeze sim:/dec_comm8_FastAndSlowData/fastDataWord 10FE 0
run
run
run
run
run
# other case, with a 1-cycle difference (the last word is still not included in the transmission)
force -freeze sim:/dec_comm8_FastAndSlowData/slowDataWord 2012345 0
force -freeze sim:/dec_comm8_FastAndSlowData/slowDataReady 0 0
run
run
force -freeze sim:/dec_comm8_FastAndSlowData/slowDataReady 1 0
run
run
force -freeze sim:/dec_comm8_FastAndSlowData/fastDataReady 1 0
force -freeze sim:/dec_comm8_FastAndSlowData/slowDataWord 1f01234 0
force -freeze sim:/dec_comm8_FastAndSlowData/slowDataReady 0 0
run
force -freeze sim:/dec_comm8_FastAndSlowData/fastDataReady 10 0
force -freeze sim:/dec_comm8_FastAndSlowData/fastDataWord dcba 0
run
run
run
run
run
run
run
run
*/



