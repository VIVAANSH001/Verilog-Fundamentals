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

        for (i = 0; i < 15; i = i + 1) 
        begin
            @(posedge clk);
            #1;
        end

        // basic R type instructions
        $display("x3 (add) = %0d (expect 8)",uut.u_core.u_regfile.registers[3]);
        $display("x4 (sub) = %0d (expect 2)",uut.u_core.u_regfile.registers[4]);
        $display("x5 (and) = %0d (expect 1)",uut.u_core.u_regfile.registers[5]);
        $display("x6 (or) = %0d (expect 7)",uut.u_core.u_regfile.registers[6]);
        $display("x7 (xor) = %0d (expect 6)",uut.u_core.u_regfile.registers[7]);
        $display("x8 (sll) = %0d (expect 96)",uut.u_core.u_regfile.registers[8]);
        $display("x9 (srl) = %0d (expect 12)",uut.u_core.u_regfile.registers[9]);

        // checking the disagreements and the edge cases (VERY IMPORTANT)
        $display("x14 (sra) = %0d (expect -1,i.e. 4294967295 unsigned)",uut.u_core.u_regfile.registers[14]);
        $display("x12 (slt) = %0d (expect 1, signed -1<1)",uut.u_core.u_regfile.registers[12]);
        $display("x13 (sltu) = %0d (expect 0, unsigned huge<1)",uut.u_core.u_regfile.registers[13]);
        $display("x15 (sub to zero) = %0d (expect 0)",uut.u_core.u_regfile.registers[15]);

        $finish;
    end

endmodule