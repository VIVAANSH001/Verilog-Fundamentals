module d_latch_tb;
    reg en, d;
    wire q;

    d_latch uut(.en(en) , .d(d), .q(q));

    initial begin
        $dumpfile("d_latch.vcd");
        $dumpvars(0,d_latch_tb);

        en=1; d=1; #10;
        $display("en=1 d=1 q=%b (expect 1, transparent)",q);

        en=1; d=0; #10;
        $display("en=1 d=0 q=%b (expect 0, transparent)",q);

        en=0; d=1; #10;
        $display("en=0 d=1 q=%b (expect 0, holding last value)",q);

        en=0; d=0; #10;
        $display("en=0 d=0 q=%b (expect 0, still holding)",q);

        en=1; d=1; #10;
        $display("en=1 d=1 q=%b (expect 1, transparent again)",q);

        $finish;
    end
endmodule