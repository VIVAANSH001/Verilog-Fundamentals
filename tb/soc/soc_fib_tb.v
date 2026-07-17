`timescale 1ns/1ps
module soc_tb;
    reg clk, rst;
    integer i;

    soc uut (.clk(clk),.rst(rst));

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("soc_tb.vcd");
        $dumpvars(0,soc_tb);

        rst = 1;
        #10;
        rst = 0;

        // 4 setup instructions + 10 loop iterations x 6 instructions each
        // + 1 final branch check that exits the loop = 65 dynamic instructions,
        // give it some headroom as well
        for (i = 0; i < 80; i = i + 1)
        begin
            @(posedge clk);
            #1;
        end

        $display("x1 (a, fib result) = %0d (expect 55)",uut.u_core.u_regfile.registers[1]);
        $display("x2 (b, fib next term) = %0d (expect 89)",uut.u_core.u_regfile.registers[2]);
        $display("x4 (i, loop counter) = %0d (expect 10)",uut.u_core.u_regfile.registers[4]);
        $display("x5 (N, loop bound) = %0d (expect 10)",uut.u_core.u_regfile.registers[5]);

        $finish;
    end

endmodule