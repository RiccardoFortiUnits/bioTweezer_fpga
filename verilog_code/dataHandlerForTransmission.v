module dataHandlerForTransmission #(
    parameter dataBitSize = 16,
    parameter max_nOfDataPerTransmission = 'h1000,
    parameter fifoSize = 64
)(
    input dataClk,
    input fifoReadClk,
    input reset,
    
    input [$clog2(max_nOfDataPerTransmission+1) -1:0] nOfDataPerTransmission,
    input [dataBitSize -1:0] in,
    input enableData,

    input readRequest,
    output [dataBitSize -1:0] dataRead,
    output readEmpty,
	 output full
);
localparam averager_outBitSize = $clog2(max_nOfDataPerTransmission+1) + dataBitSize;
wire averagedData_valid;
wire [averager_outBitSize -1:0] averagedData_uncropped;
wire [dataBitSize -1:0] averagedData;
averager #(
    .AVERAGING_POINTS_BITS  ($clog2(max_nOfDataPerTransmission+1)),
    .INPUT_DATA_BITS        (dataBitSize),
    .SIGNED                 (1)
)pi_averager(
    .clock                  (dataClk),   
    .reset                  (reset),
    .run_averaging          (enableData),
    .shift                  (1'b1),
    .averaging_points       (nOfDataPerTransmission),
    .data_in                (in),
    .data_out               (averagedData_uncropped),
    .data_valid             (averagedData_valid)
);
assign averagedData = averagedData_uncropped[dataBitSize -1:0];//since the averager has .shift=1, it already did the correct shift for us
wire wrFull, rdFull;

dcfifo #(
	.clocks_are_synchronized("FALSE"),
	.lpm_hint("RAM_BLOCK_TYPE=MLAB"),
    .intended_device_family("Cyclone V"),
    .lpm_numwords(fifoSize),
    .lpm_showahead("OFF"),
    .lpm_type("dcfifo"),
    .lpm_width(dataBitSize),
    .lpm_widthu($clog2(fifoSize)),
    .overflow_checking("OFF"),
    .rdsync_delaypipe(5),
    .read_aclr_synch("OFF"),
    .underflow_checking("OFF"),
    .use_eab("OFF"),
    .write_aclr_synch("OFF"),
    .wrsync_delaypipe(5)
) dcfifo_component (
    .aclr (reset),
    .data (averagedData),
    .rdclk (fifoReadClk),
    .rdreq (readRequest),
    .wrclk (dataClk),
    .wrreq (averagedData_valid),
    .q (dataRead),
    .rdempty (readEmpty),
    .eccstatus (),
    .rdfull (rdFull),
    .rdusedw (),
    .wrempty (),
    .wrfull (wrFull),
    .wrusedw ()
);

endmodule