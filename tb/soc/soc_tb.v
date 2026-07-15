`timescale 1ns/1ps
module soc_tb;

    reg clk, rst;
    soc uut(.clk(clk),.rst(rst));

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("soc_tb.vcd");
        $dumpvars(0,soc_tb);

        rst = 1;
        #10;
        rst = 0;

        @(posedge clk);
        #1;
        $display("x1 = %0d (expect 5)",uut.u_core.u_regfile.registers[1]); // addressing the register 1 --> registers --> regfile --> core --> soc

        $finish;
    end

endmodule