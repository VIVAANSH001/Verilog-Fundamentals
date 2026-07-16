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

        for (i = 0; i < 14; i = i + 1)
        begin
            @(posedge clk);
            #1;
        end

        // basic I-type arithmetic
        $display("x10 (addi) = %0d (expect 15)",uut.u_core.u_regfile.registers[10]);
        $display("x11 (addi neg imm, ADD/SUB disambig) = %0d (expect 2)",uut.u_core.u_regfile.registers[11]);
        $display("x12 (andi) = %0d (expect 240)",uut.u_core.u_regfile.registers[12]);
        $display("x13 (ori) = %0d (expect 240)",uut.u_core.u_regfile.registers[13]);
        $display("x14 (xori) = %h (expect ffffff00)",uut.u_core.u_regfile.registers[14]);

        //slti/sltiu disagreement + shifts
        $display("x15 (slti) = %0d (expect 1, signed -1<1)",uut.u_core.u_regfile.registers[15]);
        $display("x16 (sltiu) = %0d (expect 0, unsigned huge<1)",uut.u_core.u_regfile.registers[16]);
        $display("x17 (slli) = %0d (expect 16)",uut.u_core.u_regfile.registers[17]);
        $display("x18 (srli) = %h (expect 0fffffff)",uut.u_core.u_regfile.registers[18]);
        $display("x19 (srai) = %0d (expect -1, i.e. 4294967295 unsigned)",uut.u_core.u_regfile.registers[19]);

        // zero-result check
        $display("x20 (andi to zero) = %0d (expect 0)",uut.u_core.u_regfile.registers[20]);

        $finish;
    end

endmodule