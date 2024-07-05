
module saturator #(
	parameter inputWidth = 8, 
	parameter outputMaxWidth = 3 //the signal is saturated if it uses more than outputMaxWidth bits
)(
  input wire signed [inputWidth-1:0] input_data,
  output reg signed [inputWidth-1:0] saturated_output,
  output reg is_saturated
);

  // Calculate the saturation limit
  always @(*) begin
    if ({input_data [inputWidth-1],(|input_data [inputWidth-2:outputMaxWidth-1])} == 'b01) begin // positive saturation
        saturated_output = (1<<(outputMaxWidth-1)) - 1; // max positive
        is_saturated = 1;
    end else if ({input_data [inputWidth-1],(&input_data [inputWidth-2:outputMaxWidth-1])} == 'b10) begin // negative saturation
        saturated_output = -$signed(1<<(outputMaxWidth-1)); // max negative
        is_saturated = 1;
    end else begin // No saturation
        saturated_output = input_data;
        is_saturated = 0;
    end
  end
endmodule


module precisionSaturator #(
	parameter inputWidth = 8, 
	parameter maxValue = 'hF, 
	parameter minValue = -maxValue) (
  input wire signed [inputWidth-1:0] input_data,
  output reg signed [inputWidth-1:0] saturated_output,
  output reg is_saturated
);
    
  // Calculate the saturation limit
  always @(*) begin
    if(input_data > $signed(maxValue)) begin
        saturated_output = maxValue; // max positive
        is_saturated = 1;
    end else if (input_data < $signed(minValue)) begin // negative saturation
        saturated_output = minValue;
        is_saturated = 1;
    end else begin // No saturation
        saturated_output = input_data;
        is_saturated = 0;
    end
  end
endmodule
