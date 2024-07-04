module wfm_memory #(
    parameter MAX_WFM_LENGTH = 8192,	//Max length of the moving average
    WFM_BITS = 16					//Bits of the words in the shift registers
) (
    input wrclock,
    input [WFM_BITS-1:0] wrmem_data,
    input [ADDR_WIDTH-1:0] wraddress,
    input wren,

    input rdclock,

    input [ADDR_WIDTH-1:0] X_rdaddress,
    output reg [WFM_BITS-1:0] X_rddata,

    input [ADDR_WIDTH-1:0] Z_rdaddress,
    output reg [WFM_BITS-1:0] Z_rddata,

    input [ADDR_WIDTH-1:0] sin_ref_rdaddress,
    output reg [WFM_BITS-1:0] sin_ref_rddata,

    input [ADDR_WIDTH-1:0] cos_ref_rdaddress,
    output reg [WFM_BITS-1:0] cos_ref_rddata

);

localparam ADDR_WIDTH = $clog2(MAX_WFM_LENGTH);

reg [WFM_BITS-1:0] ramX[MAX_WFM_LENGTH-1:0];
reg [WFM_BITS-1:0] ramZ[MAX_WFM_LENGTH-1:0];
reg [WFM_BITS-1:0] ramsin[MAX_WFM_LENGTH-1:0];
reg [WFM_BITS-1:0] ramcos[MAX_WFM_LENGTH-1:0];

//RAM X
always @ (posedge wrclock) begin
	if (wren) begin
		ramX[wraddress] <= wrmem_data;
	end
end
always @ (posedge rdclock) begin
	X_rddata <= ramX[X_rdaddress];
end

//RAM Z
always @ (posedge wrclock) begin
	if (wren) begin
		ramZ[wraddress] <= wrmem_data;
	end
end
always @ (posedge rdclock) begin
	Z_rddata <= ramZ[Z_rdaddress];
end

//RAM SINref
always @ (posedge wrclock) begin
	if (wren) begin
		ramsin[wraddress] <= wrmem_data;
	end
end
always @ (posedge rdclock) begin
	sin_ref_rddata <= ramsin[sin_ref_rdaddress];
end

 //RAM COSref
always @ (posedge wrclock) begin
	if (wren) begin
		ramcos[wraddress] <= wrmem_data;
	end
end
always @ (posedge rdclock) begin
	cos_ref_rddata <= ramcos[cos_ref_rdaddress];
end
    
endmodule