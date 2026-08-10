module dff_sync_tb;
    reg clk, rst, d;
    wire q;

    dff_sync uut(.clk(clk) , .rst(rst), .d(d) , .q(q));

    initial clk=0;

    always #5 clk=~clk;

    initial begin

        $dumpfile("dff_sync.vcd");
        $dumpvars(0, dff_sync_tb);

        rst=1; d=0;
        #10;
        $display("rst=1 d=0 q=%b (expect 0)",q); 

        rst=0; d=1;
        #10;
        $display("rst=0 d=1 q=%b (expect 1)",q);

        d=0;
        #10;
        $display("rst=0 d=0 q=%b (expect 0)",q);

        d=1;
        #5;
        rst=1;
        #2;
        $display("rst=1 mid cycle q=%b (expect 1 sync so no change yet)",q);
        #3;
        $display("rst=1 after clock edge q=%b (expect 0 now it resets)",q);

        $finish;
    end
endmodule