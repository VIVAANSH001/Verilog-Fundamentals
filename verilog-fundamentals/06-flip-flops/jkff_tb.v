module jkff_tb;
    reg clk, rst, j, k;
    wire q;

    jkff uut(.clk(clk), .rst(rst), .j(j), .k(k), .q(q));

    initial clk=0;
    always #5 clk=~clk;

    initial begin
        $dumpfile("jkff.vcd");
        $dumpvars(0,jkff_tb);

        rst=1; j=0; k=0;
        #10;
        $display("rst=1 q=%b (expect 0)",q);
        rst=0;

        j=0; k=0;
        #10;
        $display("j=0 k=0 q=%b (expect 0, hold)",q);

        j=1; k=0;
        #10;
        $display("j=1 k=0 q=%b (expect 1, set)",q);

        j=0; k=0;
        #10;
        $display("j=0 k=0 q=%b (expect 1, hold)",q);

        j=0; k=1;
        #10;
        $display("j=0 k=1 q=%b (expect 0, reset)",q);

        j=1; k=1;
        #10;
        $display("j=1 k=1 q=%b (expect 1, toggle)",q);
        #10;
        $display("j=1 k=1 q=%b (expect 0, toggle again)",q);

        $finish;
    end
endmodule