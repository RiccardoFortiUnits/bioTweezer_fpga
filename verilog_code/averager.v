//module averaging "averaging_points" of signed "data_in" (or just sum if shift = 0)
//Output data bits = AVERAGING_POINTS_BITS + INPUT_DATA_BITS

module averager #(
	parameter AVERAGING_POINTS_BITS = 48,	//BITS for averaging_points (so max averaging factor (2^AVERAGING_POINTS_BITS)-1)
	parameter INPUT_DATA_BITS = 16,			//BITS for the input data
	parameter SIGNED = 1					//1 for signed data_in
)(
    input   clock,
    input   reset,
	input 	shift, //1 if shift wanted for the average (to use only if averaging_points = 2^n)
    
	input 	[AVERAGING_POINTS_BITS-1:0] averaging_points,
    input   [INPUT_DATA_BITS-1:0] data_in,
    output  [OUTPUT_DATA_BITS-1:0] data_out,
	

    input   run_averaging,
    output reg  data_valid
);

localparam 	OUTPUT_DATA_BITS = INPUT_DATA_BITS + AVERAGING_POINTS_BITS;


wire [OUTPUT_DATA_BITS-1:0] data_in_extended;
wire [OUTPUT_DATA_BITS-1:0] sum_shifted;

// If the averager is signed the input data must be sign extended to a length of OUTPUT_DATA_BITS, otherwise zero extended
// If the averager is signed (and shift is 1) the sum must be arithmetically shifted, otherwise logically shifted
generate
    if (SIGNED == 1) begin
		assign data_in_extended = {{AVERAGING_POINTS_BITS{data_in[INPUT_DATA_BITS-1]}},data_in};
		assign sum_shifted = sum>>>shift_value;
    end
    else begin
        assign data_in_extended = {{AVERAGING_POINTS_BITS{1'b0}},data_in};
		assign sum_shifted = sum>>shift_value;
    end
endgenerate

localparam IDLE = 0,
		   ADD = 1;

reg [1:0] state = IDLE;
reg [AVERAGING_POINTS_BITS-1:0] sum_counter;
reg signed [OUTPUT_DATA_BITS-1:0] sum;

always @(posedge clock ) begin
	if (reset) begin
		state <= IDLE;
		data_valid <= 1'b0;
		sum_counter <= 0;
		sum <= 0;
	end
	else begin
		case (state)
			IDLE: begin
				data_valid <= 1'b0;
				if (run_averaging) begin
					sum <= data_in_extended;
					sum_counter <= 1;					
					if (averaging_points == 1) data_valid <= 1'b1;
					else state <= ADD;
				end
			end

			ADD: begin
				if (run_averaging) begin
					sum_counter <= sum_counter + 1'b1;
					sum <= sum + data_in_extended;
					if (sum_counter >= averaging_points - 1) begin
						data_valid <= 1'b1;
						state <= IDLE;
					end
				end
			end

			default: begin
				state <= IDLE;
				data_valid <= 1'b0;
				sum_counter <= 0;
				sum <= 0;
			end
		endcase
	end
end

wire [$clog2(AVERAGING_POINTS_BITS)-1:0] shift_value;
log2n #(.BITS(AVERAGING_POINTS_BITS)) log2_averaging(
	.clock(clock),
	.reset(reset),
	.data_in(averaging_points),
	.log2_out(shift_value)
);

assign data_out = shift? sum_shifted : sum;
    
endmodule