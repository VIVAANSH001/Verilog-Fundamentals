module register_8bit_tb;
    reg clk , rst , load;
    reg [7:0] d;
    wire [7:0] q;

    register_8bit uut(.clk(clk), .rst(rst), .load(load), .d(d), .q(q));

    initial clk=0;
    always #5 clk=~clk;

    initial begin
        $dumpfile("register_8bit.vcd");
        $dumpvars(0,register_8bit_tb);

        rst=1; load=0; d=8'hAB;
        #10;
        $display("rst=1 load=0 d=AB q=%h (expect 00)",q);

        rst=0; load=0; d=8'hAB;
        #10;
        $display("rst=0 load=0 d=AB q=%h (expect 00, load disabled)",q);

        load=1; d=8'hAB;
        #10;
        $display("rst=0 load=1 d=AB q=%h (expect ab)",q);

        load=0; d=8'hFF;
        #10;
        $display("rst=0 load=0 d=FF q=%h (expect ab, held)",q);

        load=1; d=8'h37;
        #10;
        $display("rst=0 load=1 d=37 q=%h (expect 37)",q);

        load=0;
        #3; 
        rst=1;
        #2;
        $display("async rst mid-cycle q=%h (expect 00, fires immediately)",q);

        $finish;
    end
endmodule