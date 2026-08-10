module sequence_detector_tb;
    reg clk, rst, one;
    wire detect;

    sequence_detector uut(.clk(clk),.rst(rst),.one(one),.detect(detect));

    initial clk=0;

    always #5 clk=~clk;

    task send_bit;
    input bit;
    begin
        one=bit;
        #1; //giving some time for signals to be right
        $display("bit=%b state=%b detect=%b",bit,uut.state,detect);
        #9; //completing the rest of the cycle
    end
    endtask

    initial begin
        $dumpfile("sequence_detector.vcd");
        $dumpvars(0,sequence_detector_tb);

        rst=1; 
        one=0;
        #10;
        rst = 0;

        $display("TEST 1 : CLEAN '1101'");
        send_bit(1);
        send_bit(1);
        send_bit(0);
        send_bit(1);

        $display("TEST 2: NOISE AND THEN '1101'");
        send_bit(0);
        send_bit(0);
        send_bit(1);
        send_bit(1);
        send_bit(0);
        send_bit(1);

        $display("TEST 3 : OVERLAPPING '11011101'");
        send_bit(1);
        send_bit(1);
        send_bit(0);
        send_bit(1);
        send_bit(1);
        send_bit(0);
        send_bit(1);

        $finish;
    end
endmodule