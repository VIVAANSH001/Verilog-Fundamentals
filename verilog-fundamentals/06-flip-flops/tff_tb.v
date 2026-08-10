module tff_tb;
    reg clk, rst, t;
    wire q;

    tff uut(.clk(clk) , .rst(rst), .t(t), .q(q));

    initial clk=0;
    always #5 clk=~clk;

    initial begin
        $dumpfile("tff.vcd");
        $dumpvars(0,tff_tb);

        rst=1; t=0;
        #10;
        $display("rst=1 q=%b (expect 0)",q);

        rst=0; t=0;
        #10;
        $display("t=0 q=%b (expect 0, no toggle)",q);

        t=1;
        #10;
        $display("t=1 q=%b (expect 1, toggled)",q);
        #10;
        $display("t=1 q=%b (expect 0, toggled again)",q);
        t=0;
        #10;
        $display("t=0 q=%b (expect 0, holding)",q);

        $finish;
    end
endmodule