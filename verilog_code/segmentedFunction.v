
module segmentedFunction#(
    parameter     nOfEdges = 4         ,
    parameter     totalBits_IO = 16     ,
    parameter     fracBits_IO = 15       ,
    parameter     totalBits_m = totalBits_IO ,
    parameter     fracBits_m = 13,
    parameter     areSignalsSigned = 1
)(
    input                                       clk   ,
    input                                       reset ,
    input [totalBits_IO-1:0]                    in    ,
    output reg [totalBits_IO-1:0]               out   ,

    input [totalBits_IO * nOfEdges -1:0]        edgePoints,
    input [totalBits_IO * nOfEdges -1:0]        qs,
    input [totalBits_m * nOfEdges -1:0]         ms
);
`define range(index) (totalBits_IO)*(index+1) -1-:totalBits_IO
`define m_range(index) (totalBits_m)*(index+1) -1-:totalBits_m
//applies to the input a segmented function. The values for edgePoints, qs and 
    //ms can be found for any segmented function as follows
    /*    
    #x and y are the sample points and values of the function ( y[i] = f(x[i]) )
    #es: x = np.linspace(0,1,8)
    #    y = np.tanh(x*4)
    a = x[0:len(x)-1]
    b = x[1:]
    c = y[0:len(y)-1]
    d = y[1:]
    edgePoints = a
    qs = c
    ms = (d-c) / (b-a)
    */
    
//if you don't use some samples, set their edgePoint to a value <= edgePoint[0] (just set them to 0 
    //or -(2^(totalBits_IO-1)), depending on if the signals are signed or not)


localparam multiplicationDelay = 3;//we'll need a bunch of delays to "synchronize" with all the operations

reg [totalBits_IO-1:0]      in_r            [3 -1:0];

wire [nOfEdges-1:0] isInHigherThanEdge;//bitString of the form 00...0011...11
wire [nOfEdges-1:0] isCurrentEdge;//bitString of the form      00...0010...00
reg [$clog2(nOfEdges):0] edgeIndex;

reg [totalBits_IO-1:0] current_Edge;
reg [totalBits_IO-1:0] current_q[multiplicationDelay -1:0];
reg [totalBits_m-1:0] current_m;
wire [totalBits_IO-1:0] mx;
wire [totalBits_IO-1:0] edge0 = edgePoints[`range(0)];
wire [totalBits_IO-1:0] edge1 = edgePoints[`range(1)];

generate
    genvar gi;
    
    //set isInHigherThanEdge    
    if(areSignalsSigned) begin
        assign isInHigherThanEdge[0] = $signed(in_r[0]) >= $signed(edgePoints[`range(0)]);
        for(gi = 1; gi < nOfEdges; gi = gi + 1)begin:signedLoop
            assign isInHigherThanEdge[gi] = ($signed(in_r[0]) >= $signed(edgePoints[`range(gi)])) && 
                ($signed(edgePoints[`range(gi)]) > $signed(edgePoints[`range(gi-1)]));// if set lower or higher than the first 
                                                                                    //edge, it means it is disabled
        end
    end else begin
        assign isInHigherThanEdge[0] = $unsigned(in_r[0]) >= $unsigned(edgePoints[`range(0)]);
        for(gi = 1; gi < nOfEdges; gi = gi + 1)begin:unsignedLoop
            assign isInHigherThanEdge[gi] = ($unsigned(in_r[0]) >= $unsigned(edgePoints[`range(gi)])) && 
                ($unsigned(edgePoints[`range(gi)]) > $unsigned(edgePoints[`range(gi-1)]));// if set lower or higher than the first 
                                                                                    //edge, it means it is disabled
        end    
    end
    
    //set isCurrentEdge
    assign isCurrentEdge[nOfEdges - 1] = isInHigherThanEdge[nOfEdges - 1];
    for(gi = 0; gi < nOfEdges - 1; gi = gi + 1)begin:set_isCurrentEdge
        assign isCurrentEdge[gi] = !isInHigherThanEdge[gi + 1] & isInHigherThanEdge[gi];
    end
    
endgenerate
wire [totalBits_IO+1 -1:0] inMinusEdge = {in_r[3 -1][totalBits_IO-1],in_r[3 -1]} - {current_Edge[totalBits_IO-1],current_Edge};
clocked_FractionalMultiplier #(
  .A_WIDTH			(totalBits_IO + 1),//stupid sum/difference between integers, which requires one more bit to not overflow... 
  .B_WIDTH			(totalBits_m),
  .OUTPUT_WIDTH		(totalBits_IO),
  .FRAC_BITS_A		(fracBits_IO),
  .FRAC_BITS_B		(fracBits_m),
  .FRAC_BITS_OUT	(fracBits_IO),
  .areSignalsSigned (areSignalsSigned)
) mult (
  .clk(clk),
  .reset(reset),
  .a(inMinusEdge),
  .b(current_m),
  .result(mx)
);


integer i;
always @(posedge clk)begin
    if(reset)begin
        for(i=0; i < 3; i = i + 1)begin
            in_r[i] <= 0;
        end
        out <= 0;
        
        edgeIndex <= 0;
        current_Edge <= 0;
        for(i=0; i < multiplicationDelay; i = i + 1)begin
            current_q[i] <= 0;
        end
        current_m <= 0;
        
    end else begin
        in_r[0] <= in;
        for(i=1; i < 3; i = i + 1)begin
            in_r[i] <= in_r[i-1];
        end
    
        for(i=0; i < nOfEdges; i = i + 1)begin
            if(isCurrentEdge[i])begin
                edgeIndex <= i;     
            end
        end
        
        current_q[0] <= qs[`range(edgeIndex)];
        current_Edge <= edgePoints[`range(edgeIndex)];
        for(i=1; i < multiplicationDelay; i = i + 1)begin
            current_q[i] <= current_q[i-1];
        end
        
        current_m <= ms[`m_range(edgeIndex)];
        
        out <= current_q[multiplicationDelay-1] + mx;
    end
end

endmodule





/*
add wave -position insertpoint sim:/segmentedFunction/*
add wave -position insertpoint sim:/segmentedFunction/current_q
add wave -position insertpoint sim:/segmentedFunction/in_r
force -freeze sim:/segmentedFunction/clk 1 0, 0 {50 ps} -r 100
force -freeze sim:/segmentedFunction/reset 1 0
force -freeze sim:/segmentedFunction/in 3000 0
force -freeze sim:/segmentedFunction/edgePoints 5000_4000_2000_1000 0
force -freeze sim:/segmentedFunction/qs 0800_2000_1000_1000 0
force -freeze sim:/segmentedFunction/ms 0100_9000_2000_3000 0
run
run
run
force -freeze sim:/segmentedFunction/reset 10 0
run
run
run
run
run
run
run
force -freeze sim:/segmentedFunction/in 1000 0
run
run
run
force -freeze sim:/segmentedFunction/in 1800 0
run
run
run
force -freeze sim:/segmentedFunction/in 2000 0
run
force -freeze sim:/segmentedFunction/in 2800 0
run
force -freeze sim:/segmentedFunction/in 3000 0
run
force -freeze sim:/segmentedFunction/in 3800 0
run
force -freeze sim:/segmentedFunction/in 4000 0
run
force -freeze sim:/segmentedFunction/in 4800 0
run
force -freeze sim:/segmentedFunction/in 5000 0
run
force -freeze sim:/segmentedFunction/in 5800 0
run
force -freeze sim:/segmentedFunction/in 6000 0
run
force -freeze sim:/segmentedFunction/in 6800 0
run
force -freeze sim:/segmentedFunction/in 7000 0
run
force -freeze sim:/segmentedFunction/in 7800 0
run
run
run
run
run
run
run
run

*/