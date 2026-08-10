module traffic_light_tb;
    reg clk, rst;
    wire red, green, yellow;

    traffic_light uut(.clk(clk),.rst(rst),.red(red),.green(green),.yellow(yellow));

    initial clk=0;
    always #5 clk=~clk;

    initial begin
        $dumpfile("traffic_light.vcd");
        $dumpvars(0,traffic_light_tb);

        rst=1;
        #10;
        $display("rst=1:red=%b green=%b yellow=%b (expect 1 0 0)",red,green,yellow);

        rst=0;
        //staying red for 10 cycles
        #100;
        $display("after RED:red=%b grn=%b yel=%b (expect 0 1 0)", red, green, yellow);

        #80;
        //staying green for 8 cycles
        $display("after GREEN:red=%b green=%b yellow=%b (expect 0 0 1)",red,green,yellow);

        //staying yellow for 3 cycles
        #30;
        $display("after YELLOW:red=%b green=%b yellow=%b (expect 1 0 0)",red,green,yellow);

        //making sure the FSM loops
        #100; 
        #80; 
        #30;
        $display("full loop:red=%b green=%b yellow=%b (expect 1 0 0)",red,green,yellow);

        //reset mid state testing
        #40;
        rst=1;
        #10;
        $display("mid rst:red=%b green=%b yellow=%b (expect 1 0 0)",red,green,yellow);
        rst=0;

        $finish;
    end
endmodule