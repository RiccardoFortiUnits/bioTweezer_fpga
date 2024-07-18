module new_dec_comm8_port2 #(
    parameter AVL_SIZE    = 8,
              BYTE_SIZE   = 8,
              IP_SIZE     = 32,
              MAC_SIZE    = 48,
              FIFO_LENGTH = 16,
              nOfFifos = 4
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

    //----------------------------------------------------------------
    // DATA TO TRANSMIT
    output[nOfFifos -1:0]                   rdreq_fifo,
    input [nOfFifos * FIFO_LENGTH -1:0]     rddata_fifo, 
    input [nOfFifos -1:0]                   rdempty_fifo

    //----------------------------------------------------------------
);

//-------------------------------------------------------------------------------------------------------------------------------
// DECODER TX STATE MACHINE

localparam TX_IDLE                 = 0,// wait for data in the fifos
           TX_HEADER_CTRL_MODE     = 1,// write header
           TX_WRITE_DATA_FROM_FIFO = 2,// write the data from all the fifos (we'll loop for every fifo until we've read them all)
           TRANSMIT                = 3,// transmit the packet
           WAIT                    = 4;// buffer state, to allow the fifos to reset



localparam BYTE_IN_FIFO = FIFO_LENGTH/BYTE_SIZE;
reg [$clog2(BYTE_IN_FIFO)-1:0] byte_counter;

reg [2:0] TX_STATE;

reg rdreq_all_fifos;
// all the fifos are read at the same time
assign rdreq_fifo = {(nOfFifos){rdreq_all_fifos}};
reg [2:0] fifo_sel_counter;          // register to select the fifo to read
wire [FIFO_LENGTH-1:0] fifo_sel_data; // temporary storage for the selected fifo

wire [7:0] data_from_fifo_slice;     // fifo data slice

// logic to get the correct byte from the FIFO
assign data_from_fifo_slice = fifo_sel_data[FIFO_LENGTH-1 - 8*byte_counter -:8];


// Assign the input array to the unpacked array
wire [FIFO_LENGTH -1:0] unpacked_rddata_fifo [nOfFifos -1:0];
generate
genvar i;
  for (i = 0; i < nOfFifos; i = i + 1) begin: aaaa
		assign unpacked_rddata_fifo[i] = rddata_fifo[FIFO_LENGTH * (i+1) - 1 : FIFO_LENGTH * i];
  end
endgenerate

assign fifo_sel_data = unpacked_rddata_fifo[fifo_sel_counter];

always @(posedge clk) 
begin


    if (reset) 
    begin
        fifo_sel_counter <= 0;
        rdreq_all_fifos  <= 0;

        tx_fifo_data_write   <= 0;
        tx_fifo_status_write <= 0;

        byte_counter <= 0;

        TX_STATE <= TX_IDLE;
    end
    else 
    begin
        case (TX_STATE)
            TX_IDLE: 
            begin
                fifo_sel_counter <= 0;   
                rdreq_all_fifos  <= 0;   

                tx_fifo_data_write   <= 0;
                tx_fifo_status_write <= 0;

                byte_counter <= 0;

                if (!rdempty_fifo)
                begin // start when the all the fifos are not empty (all the fifos are written at the same time anyway)
                    TX_STATE <= TX_HEADER_CTRL_MODE;                            
                end
            end

            TX_HEADER_CTRL_MODE:
            begin
                tx_fifo_data_write <= 1;
                tx_fifo_data       <= 8'hA5;//for now, no header is necessary, but let's write something anyway
                
                TX_STATE <= TX_WRITE_DATA_FROM_FIFO;
            end

            TX_WRITE_DATA_FROM_FIFO: 
            begin // write the data to the UDP fifo
                if(tx_fifo_data_full)begin
                    //wait until the fifo gets a bit empty
                    tx_fifo_data_write <= 0;
                end else begin
                    tx_fifo_data_write <= 1;
                    tx_fifo_data       <= data_from_fifo_slice;//send the current byte of the current fifo
                    if (byte_counter < BYTE_IN_FIFO-1) //current fifo not read completely? 
                    begin
                        byte_counter <= byte_counter + 1;//read the next byte
                    end               
                    else 
                    begin 
                        if (fifo_sel_counter == nOfFifos-1)//last fifo completed?
                        begin
                            TX_STATE <= TRANSMIT;
                        end
                        else 
                        begin
                            fifo_sel_counter <= fifo_sel_counter + 1;//go to the next fifo
                            byte_counter <= 0;
                        end
                    end
                end
            end

            TRANSMIT:
            begin
                tx_fifo_data_write <= 0;
                if(tx_fifo_status_full)begin
                    //wait until the fifo gets a bit empty
                    tx_fifo_status_write <= 0;
                end else begin
                    tx_fifo_status <= {nOfFifos * BYTE_IN_FIFO + 1, destination_ip, destination_mac};//set the status (nOf bytes to transmit, IP and MAC address)
                    tx_fifo_status_write <= 1;//initiate the transmission
                    rdreq_all_fifos <= 1;//prepare the request for the next bunch of data

                    TX_STATE <= WAIT;
                end
            end

            WAIT: 
            begin // wait state needed to get the rdempty_fifos back to one after tx_fifo_status_write <= 1;
                    //todo: since I added the TRANSMIT case, maybe it's no longer necessary, and we can merge the TRANSMIT and WAIT cases
                rdreq_all_fifos      <= 0;

                tx_fifo_data_write   <= 0;
                tx_fifo_status_write <= 0;

                TX_STATE <= TX_IDLE;
            end
            
            default: 
            begin
                fifo_sel_counter     <= 0;
                rdreq_all_fifos      <= 0;

                tx_fifo_data_write   <= 0;
                tx_fifo_status_write <= 0;

                byte_counter         <= 0;

                TX_STATE <= TX_IDLE;
            end

        endcase
    end
end
//-------------------------------------------------------------------------------------------------------------------------------

endmodule