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

        for (i = 0; i < 82; i = i + 1)
        begin
            @(posedge clk);
            #1;
        end

        // BEQ
        $display("x10 (beq taken) = %0d (expect 222)",uut.u_core.u_regfile.registers[10]);
        $display("x11 (beq not taken) = %0d (expect 111)",uut.u_core.u_regfile.registers[11]);
        $display("x12 (beq same reg) = %0d (expect 222)",uut.u_core.u_regfile.registers[12]);

        // BNE
        $display("x13 (bne taken) = %0d (expect 222)",uut.u_core.u_regfile.registers[13]);
        $display("x14 (bne not taken) = %0d (expect 111)",uut.u_core.u_regfile.registers[14]);
        $display("x15 (bne same reg) = %0d (expect 111)",uut.u_core.u_regfile.registers[15]);

        // BLT / BGE signed
        $display("x16 (blt taken, signed) = %0d (expect 222)",uut.u_core.u_regfile.registers[16]);
        $display("x17 (blt not taken) = %0d (expect 111)",uut.u_core.u_regfile.registers[17]);
        $display("x18 (bge taken) = %0d (expect 222)",uut.u_core.u_regfile.registers[18]);
        $display("x19 (bge not taken) = %0d (expect 111)",uut.u_core.u_regfile.registers[19]);

        // BLTU / BGEU unsigned, disagreement pair vs blt/bge which is above
        $display("x20 (bltu taken) = %0d (expect 222)",uut.u_core.u_regfile.registers[20]);
        $display("x21 (bltu not taken, disagrees with blt) = %0d (expect 111)",uut.u_core.u_regfile.registers[21]);
        $display("x22 (bgeu taken, disagrees with bge) = %0d (expect 222)",uut.u_core.u_regfile.registers[22]);
        $display("x23 (bgeu not taken) = %0d (expect 111)",uut.u_core.u_regfile.registers[23]);

        $finish;
    end

endmodule