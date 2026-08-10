module dff_tb;
reg d, clk , rst;
wire q;

dff uut(.clk(clk), .rst(rst) , .d(d) , .q(q));

initial clk=0;
always #5 clk=~clk;

initial begin

    $dumpfile("dff.vcd");
    $dumpvars(0,dff_tb);
    rst=1; d=0;
    #10;
    $display("rst=1 d=0 q=%b (expect 0)",q);

    rst=0; d=1;
    #10;
    $display("rst=0 d=1 q=%b (expect 1)",q);

    d=0;
    #10;
    $display("rst=0 d=0 q=%b (expect 0)",q);

    d=1; #5;
    rst=1; #2;
    $display("rst=1 mid cycle q=%b (expect 0)", q);

    $finish;
end
endmodule