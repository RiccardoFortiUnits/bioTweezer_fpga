/*
	implements a first degree IIR of the form
	y(n) = a*x(n) + (1-a)*y(n-1), with a = 2^-k
	So, no requirement for multipliers

*/
module superLongAndCompactIIR
#(
	parameter dataBitSize = 16,
	parameter log2_smallerCoefficient = 30,//about 20 seconds
	parameter isSigned = 1
)(
	input clk,
	input reset,
	input [dataBitSize -1:0] in,
	input [$clog2(log2_smallerCoefficient+1) -1:0] log2Coeff,
	output [dataBitSize -1:0] out
);
reg signed [dataBitSize + log2_smallerCoefficient -1:0] out_uncropped;
wire signed [dataBitSize + log2_smallerCoefficient -1:0] in_extended;
wire signed [dataBitSize + log2_smallerCoefficient -1:0] ax, _ay;
generate
	if(isSigned)begin
		assign ax = $signed(in_extended) >>> log2Coeff;
		assign _ay = -($signed(out_uncropped) >>> log2Coeff);
	end else begin
		assign ax = $unsigned(in_extended) >> log2Coeff;
		assign _ay = -($unsigned(out_uncropped) >> log2Coeff);
	end
endgenerate
fixedPointShifter#(dataBitSize, 0, dataBitSize + log2_smallerCoefficient, log2_smallerCoefficient, isSigned) 
	extendInput(in, in_extended);
always @(posedge clk) begin
	if(reset) begin
		out_uncropped <= 0;
	end else begin
		out_uncropped <= out_uncropped + ax + _ay;
	end
end
assign out = out_uncropped[dataBitSize + log2_smallerCoefficient -1-:dataBitSize]; 
endmodule