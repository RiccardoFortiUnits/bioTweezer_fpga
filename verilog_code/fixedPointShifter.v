module fixedPointShifter#(
	parameter inputBitSize = 8,
	parameter inputFracSize = 7,
	parameter outputBitSize = 8,
	parameter outputFracSize = 7,
	parameter isSigned = 0
)(
	input [inputBitSize-1:0] in,
	output [outputBitSize-1:0] out
);
//move a fixed-point number to another with different sizes and decimal point position
//for now, there is no saturation (es: 0x52.3 shifted into a Q4.4 will become 0x2.3)
	localparam 	inputWholeSize = inputBitSize - inputFracSize,
				outputWholeSize = outputBitSize - outputFracSize;
generate
//fractional part
	if(outputFracSize <= inputFracSize)begin
		assign out[outputFracSize-1:0] = in[inputFracSize -1-:outputFracSize];
	end else begin
		assign out[outputFracSize -1-:inputFracSize] = in[inputFracSize -1:0];
		assign out[outputFracSize-inputFracSize -1:0] = 0;
	end

//whole part
	if(outputWholeSize <= inputWholeSize)begin
		assign out[outputBitSize -1:outputFracSize] = in[inputFracSize+outputWholeSize -1:inputFracSize];
	end else begin
		assign out[inputWholeSize+outputFracSize -1-:inputWholeSize] = in[inputBitSize -1:inputFracSize];
		if(isSigned)begin
			assign out[outputBitSize -1-:outputWholeSize-inputWholeSize] = {(outputWholeSize-inputWholeSize){in[inputBitSize -1]}};
		end else begin
			assign out[outputBitSize -1-:outputWholeSize-inputWholeSize] = {(outputWholeSize-inputWholeSize){1'b0}};
		end
	end

endgenerate	
endmodule