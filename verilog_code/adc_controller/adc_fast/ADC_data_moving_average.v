//simple lenght 2 moving average, in order to average the 100MHz data and use them at 50MHz with the following averaging
//this is a non-recursive moving average
module ADC_data_moving_average(
    input clock_100,    
    input [15:0] data_in,
    output reg [15:0] data_out
);

reg signed [15:0] data_in_del;
wire signed [17:0] data_sum = {data_in_del[15],data_in_del} + {data_in[15],data_in}; //padding to avoid issues in the zero crossing (e.g. 001+111=[100]0, while 0001+1111=1[000]0)
always @(posedge clock_100 ) begin
	data_in_del <= data_in;
    data_out <= data_sum[16:1]; //registered data out with a factor 2 division
end

endmodule