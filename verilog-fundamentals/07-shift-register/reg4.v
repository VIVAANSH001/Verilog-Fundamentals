module reg4(input clk,rst, d,output [3:0] q);

    dff ff0 (.d(d),.clk(clk), .rst(rst),.q(q[0]));
    dff ff1 (.d(q[0]),.clk(clk), .rst(rst),.q(q[1]));
    dff ff2 (.d(q[1]),.clk(clk), .rst(rst),.q(q[2]));
    dff ff3 (.d(q[2]),.clk(clk), .rst(rst),.q(q[3]));

endmodule