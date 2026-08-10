module counter_updown_tb;
    reg clk, rst, up, en;
    wire [3:0] cnt;

    counter_updown uut(.clk(clk), .rst(rst), .up(up), .en(en), .cnt(cnt) );

    initial clk=0;

    always #5 clk=~clk;

    initial begin

        $dumpfile("counter_updown.vcd");
        $dumpvars(0,counter_updown_tb);

        rst=1; up=0;en=0;
        #10;
        $display("rst=1 cnt=%b (expect 0000)",cnt);

        rst=0; en=1; up=1;
        #10;
        $display("en=1 up=1 cnt=%b (expect 0001)",cnt);
        #10; 
        $display("en=1 up=1 cnt=%b (expect 0010)",cnt);
        #10; 
        $display("en=1 up=1 cnt=%b (expect 0011)",cnt);

        up=0;
        #10; 
        $display("en=1 up=0 cnt=%b (expect 0010)",cnt);
        #10; 
        $display("en=1 up=0 cnt=%b (expect 0001)",cnt);

        en=0;
        #10; 
        $display("en=0 cnt=%b (expect 0001)",cnt);
        #10; 
        $display("en=0 cnt=%b (expect 0001)",cnt);

        $finish;
        
    end
endmodule