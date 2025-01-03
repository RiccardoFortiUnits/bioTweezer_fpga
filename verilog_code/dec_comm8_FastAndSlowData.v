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
              slowDataWordSize = 4,
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


localparam totalSlowWordBuffer = 1 << $clog2(maxSlowWordsPerTransission + 5);//it's always a power of 2, so we don't have problems when it overflows
reg [slowDataWordSize*totalSlowWordBuffer -1:0] allSlowWords;
reg [$clog2(totalSlowWordBuffer+1) -1:0] slowWordCounter;
reg [$clog2(totalSlowWordBuffer+1) -1:0] slowWordPointer;//one more bit to avoid overflow
wire [$clog2(totalSlowWordBuffer+1) -1:0] nextSlowWordPointer = slowWordCounter + slowWordPointer;

wire isSlowBufferFull = slowWordCounter >= maxSlowWordsPerTransission;
wire isSlowBufferEmpty = slowWordCounter == 0;
reg sendFastData, sendSlowData;
reg readNewSlowWordNow;
wire pauseSlowWordRequests = 1;//slowWordCounter >= totalSlowWordBuffer - 1;//todo find a better function 
                                                                            //to stop the data flow. Also, if 
                                                                            //you stop data reads during 
                                                                            //transmission, you wouldn't need
                                                                            //a buffer for (totalSlowWordBuffer)
                                                                            //words, but just for 
                                                                            //(maxSlowWordsPerTransission) words
localparam  tr_all = 'b11,
            tr_fastData = 'b01,
            tr_slowData = 'b10;
wire [1:0] transmissionType = {sendSlowData, sendFastData};
reg [$clog2(totalSlowWordBuffer+1) -1:0] nOfSlowWordsToSend;

reg [fastDataWordSize -1:0] fastWordToSend;

localparam  nOfFastBytes = (fastDataWordSize                              + BYTE_SIZE - 1) / BYTE_SIZE,
            nOfSlowBytes = (slowDataWordSize * maxSlowWordsPerTransission + BYTE_SIZE - 1) / BYTE_SIZE,
            max_nOfBytes = nOfFastBytes > nOfSlowBytes ? nOfFastBytes : nOfSlowBytes;
reg [$clog2(max_nOfBytes+1)-1:0] byte_counter;
wire [$clog2(max_nOfBytes+1)-1:0] slowBytesToSend = (nOfSlowWordsToSend * slowDataWordSize + BYTE_SIZE - 1) / BYTE_SIZE;//todo viene sintetizzato come prodotto e divisione? Si può in alternativa fare la moltiplicazione mentre si aggiungono le slow word (ad ogni nuova word si incrementa un counter)?
reg [$clog2(totalSlowWordBuffer+1) -1:0] slowWordDecrementer; 
always @(posedge clk) begin
    if (reset) begin
        state <= s_idle;
        requestFastData <= 0;
        requestSlowData <= 0;
        readNewSlowWordNow <= 0;
        allSlowWords <= 0;
        slowWordCounter <= 0;
        slowWordPointer <= 0;
        nOfSlowWordsToSend <= 0;
        fastWordToSend <= 0;
        byte_counter <= 0;
        tx_fifo_data_write <= 0;
        tx_fifo_status_write <= 0;
        tx_fifo_data <= 0;
        tx_fifo_status <= 0;
        sendFastData <= 0;
        sendSlowData <= 0;
        slowWordDecrementer <= 0;
    end else begin
        //setup reading of the next slow word. If some data is ready, we'll read it on the next 
        //cycle (slowDataReady works as a buffer_empty flag, we request a new data with requestSlowData
        //and read it in the next cycle)
        readNewSlowWordNow <= slowDataReady & pauseSlowWordRequests;
        requestSlowData <= slowDataReady & pauseSlowWordRequests;
        if(readNewSlowWordNow)begin
            //add the new word to the buffer
            allSlowWords[(nextSlowWordPointer + 1) * slowDataWordSize -1-:slowDataWordSize] <= slowDataWord;
            slowWordCounter <= slowWordCounter + 1 - slowWordDecrementer;
        end else begin
            slowWordCounter <= slowWordCounter - slowWordDecrementer;
        end
        slowWordPointer <= slowWordPointer + slowWordDecrementer;
        case(state)
            s_idle:begin
                tx_fifo_data_write   <= 0;
                tx_fifo_status_write <= 0;
                if(fastDataReady || isSlowBufferFull)begin
                    state <= s_header;
                    //save the current value of the fifos (in case there's new data arriving during the transmission)
                    sendFastData <= fastDataReady;
                    fastWordToSend <= fastDataWord;
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
                    tx_fifo_data <= fastWordToSend[(byte_counter + 1) * 8 -1-:8];//send the current byte of the current fifo
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
                    tx_fifo_data       <= allSlowWords[slowWordPointer * slowDataWordSize + (byte_counter + 1) * 8 -1-:8];//send the current byte of the current fifo
                    if (byte_counter < slowBytesToSend-1)begin//word not read completely?
                        byte_counter <= byte_counter + 1;//read the next byte
                    end else begin
                        state <= s_transmit;
                        slowWordDecrementer <= nOfSlowWordsToSend;
                        byte_counter <= 0;
                    end
                end
            end
            s_transmit:begin
                tx_fifo_data_write <= 0;
                slowWordDecrementer <= 0;
                if(tx_fifo_status_full)begin
                    //wait until the fifo gets a bit empty
                    tx_fifo_status_write <= 0;
                end else begin
                    tx_fifo_status <= {(slowBytesToSend + nOfFastBytes) + 1, destination_ip, destination_mac};//set the status (nOf bytes to transmit, IP and MAC address)
                    tx_fifo_status_write <= 1;//initiate the transmission

                    state <= s_idle;
                end
            end
        endcase
    end
end


endmodule