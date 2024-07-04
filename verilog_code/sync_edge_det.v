module sync_edge_det #( parameter WIDTH = 1)
(
    input clk,

    input [WIDTH-1:0] signal_in,

    output reg [WIDTH-1:0] data_out = {WIDTH{1'd0}},
    
    output [WIDTH-1:0] rising,
    output [WIDTH-1:0] falling

);

reg [WIDTH-1:0] temp_reg1, temp_reg2;

always @(posedge clk)
begin
    temp_reg1 <= signal_in;
    data_out <= temp_reg1;
    temp_reg2 <= data_out;
end

assign rising = (temp_reg2 ^ data_out) & data_out;
assign falling = (temp_reg2 ^ data_out) & ~data_out;

endmodule
