module dataHandlerForSporadicData#(
    parameter dataBitSize = 16,
    parameter fifoSize = 64
)(
    input dataClk,
    input fifoReadClk,
    input reset,
    
    input [dataBitSize -1:0] in,
    input in_valid,

    input readRequest,
    output [dataBitSize -1:0] dataRead,
    output readEmpty,
	output full
);

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
    .data (in),
    .rdclk (fifoReadClk),
    .rdreq (readRequest),
    .wrclk (dataClk),
    .wrreq (in_valid),
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

