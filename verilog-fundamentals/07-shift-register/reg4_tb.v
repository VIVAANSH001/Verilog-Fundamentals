module reg4_tb;
    reg clk, rst, d;
    wire [3:0] q;

    reg4 uut(.clk(clk), .rst(rst), .d(d), .q(q));

    initial clk=0;
    always #5 clk=~clk;

    initial begin
        $dumpfile("reg4.vcd");
        $dumpvars(0,reg4_tb);

        rst=1; d=0;
        #10;
        $display("rst=1 q=%b (expect 0000)",q);

        rst=0;d=1;#10;
        $display("after 1 cycle d=1 q=%b (expect 0001)",q);

        d=0;
        #10;
        $display("after 2 cycles d=0 q=%b (expect 0010)",q);

        d=1;
        #10;
        $display("after 3 cycles d=1 q=%b (expect 0101)",q);

        d=1;#10;
        $display("after 4 cycles d=1 q=%b (expect 1011)",q);

        $finish;
    end
endmodule