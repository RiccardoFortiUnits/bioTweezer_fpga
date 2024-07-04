//RAM based shift register for the moving average implementation
//The actual use of the RAM is up to the compiler, it is not enforced
//The reset happens only if the ram has been previously written to decrease latency during a reset
module shift_register_ram_based  #(
    parameter MAX_LENGTH = 1024,	//Max length of the moving average
    DATA_BITS = 64					//Bits of the words in the shift registers
) (
	input						clock,
	input						reset,
	input						enable,	//When 1: data_in is written in the shift register and the "lenght"-1 times older data_in is set to the output
	input [ADDR_WIDTH-1:0]		length, //Minimum allowed length is 1 
	input [DATA_BITS-1:0]		data_in,
	output reg[DATA_BITS-1:0]	data_out,
	output						ready
);

localparam ADDR_WIDTH = $clog2(MAX_LENGTH);

//adv_pointer for the write and pointer for the read operations
reg already_resetted = 1'b0;
reg [ADDR_WIDTH-1:0] pointer = 0;
wire [ADDR_WIDTH-1:0] adv_pointer = pointer + (length - 1'b1);
always @(posedge clock) begin
	if (reset) begin
		pointer <= 0;
		already_resetted <= 1'b1;
	end
	else if (ready && enable && length != 0) begin
		pointer <= pointer + 1'b1;
		already_resetted <= 1'b0; //if a write happen the shift register is no longer fully empty
	end
end

//////////// Reset section //////////////
// Used for the complete ram cleaning, writing zero in all the adresses
reg [ADDR_WIDTH:0] reset_counter;
reg ram_reset = 1'b0;
assign ready = !ram_reset && !reset; //the shift register is ready when it's not resetting

always @(posedge clock ) begin
	if (reset) begin
		if (!already_resetted) begin  //if the shift register actually need a reset, initialize the reset counter and enable the reset procedure
			reset_counter <= MAX_LENGTH[ADDR_WIDTH:0];
			ram_reset <= 1'b1;
		end		
	end
	else if (reset_counter == 0) begin
		ram_reset <= 1'b0;
	end
	else if (reset_counter > 0) begin
		reset_counter <= reset_counter - 1'b1;
	end

	// if (reset_counter == 0) begin
	// 	if (reset && !already_resetted) begin
	// 		reset_counter <= MAX_LENGTH[ADDR_WIDTH:0];
	// 		ram_reset <= 1'b1;
	// 	end
	// 	else begin
	// 		ram_reset <= 1'b0;
	// 	end		
	// end
    // if (reset_counter > 0) begin
	// 	reset_counter <= reset_counter - 1'b1;
	// end
end

//when the ram is resetting it is always enabled with the data 0 and a decrementin address through the whole memory
wire enable_to_ram = (ram_reset == 1)? 1'b1:(!reset && ready && enable && length != 0);
wire [ADDR_WIDTH:0] address_for_reset = reset_counter-1'b1; //reset counter can be MAX_LENGTH, so doing -1 is write the entire memory
wire [ADDR_WIDTH-1:0] address_to_ram = (ram_reset == 1)? address_for_reset[ADDR_WIDTH-1:0] :adv_pointer;
wire [DATA_BITS-1:0] data_to_ram = (ram_reset == 1)? {DATA_BITS{1'b0}}:data_in;

///////////// RAM section ////////////////
reg [DATA_BITS-1:0] ram[MAX_LENGTH-1:0];

// Write port 
always @ (posedge clock) begin
	if (enable_to_ram) begin
		ram[address_to_ram] <= data_to_ram;
	end
end 

// Read port
always @ (posedge clock) begin
	if (reset || ram_reset) begin
		data_out <= 0;
	end
	else if (enable_to_ram)	begin
		if (length == 1) data_out <= data_to_ram; //to specify read during write operation
		else data_out <= ram[pointer];
	end
end

endmodule
