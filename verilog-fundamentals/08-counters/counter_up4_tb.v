module counter_up4_tb;
    reg clk, rst;
    wire [3:0] cnt;

    counter_up4 uut(.clk(clk), .rst(rst), .cnt(cnt));

    initial clk=0;
    always #5 clk=~clk;

    initial begin
        $dumpfile("counter_up4.vcd");
        $dumpvars(0,counter_up4_tb);

        rst=1;
        #10;
        $display("rst=1 cnt=%b (expect 0000)",cnt);

        rst=0;
        #10;
        $display("cnt=%b (expect 0001)",cnt);
        #10; 
        $display("cnt=%b (expect 0010)",cnt);
        #10; 
        $display("cnt=%b (expect 0011)",cnt);
        #10; 
        $display("cnt=%b (expect 0100)",cnt);
        #10; 
        $display("cnt=%b (expect 0101)",cnt);

        rst=1;
        #10;
        $display("rst=1 cnt=%b (expect 0000)",cnt);

        $finish;
    end
endmodule