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

        // ram powers up uninitialized, zero it first
        for (i = 0; i < 4096; i = i + 1)
        begin
            uut.u_mem_interface.ram.mem[i] = 8'h00;
        end

        // preload word 0 = 0xAABBCCDD, little-endian byte layout
        uut.u_mem_interface.ram.mem[0] = 8'hDD;
        uut.u_mem_interface.ram.mem[1] = 8'hCC;
        uut.u_mem_interface.ram.mem[2] = 8'hBB;
        uut.u_mem_interface.ram.mem[3] = 8'hAA;
        // preload word 4 = 0x12345678, all bytes sign-bit 0 on purpose
        uut.u_mem_interface.ram.mem[4] = 8'h78;
        uut.u_mem_interface.ram.mem[5] = 8'h56;
        uut.u_mem_interface.ram.mem[6] = 8'h34;
        uut.u_mem_interface.ram.mem[7] = 8'h12;

        rst = 1;
        #10;
        rst = 0;

        for (i = 0; i < 12; i = i + 1)
        begin
            @(posedge clk);
            #1;
        end

        // full word load
        $display("x1 (lw) = %h (expect aabbccdd)",uut.u_core.u_regfile.registers[1]);

        // byte loads, signed vs unsigned, word 0
        $display("x2 (lb lane0) = %h (expect ffffffdd)",uut.u_core.u_regfile.registers[2]);
        $display("x3 (lbu lane0) = %h (expect 000000dd)",uut.u_core.u_regfile.registers[3]);
        $display("x4 (lb lane1) = %h (expect ffffffcc)",uut.u_core.u_regfile.registers[4]);

        // half loads, both aligned offsets
        $display("x5 (lh lanes01) = %h (expect ffffccdd)",uut.u_core.u_regfile.registers[5]);
        $display("x6 (lhu lanes01) = %h (expect 0000ccdd)",uut.u_core.u_regfile.registers[6]);
        $display("x7 (lh lanes23) = %h (expect ffffaabb)",uut.u_core.u_regfile.registers[7]);

        // more byte loads
        $display("x8 (lb lane3) = %h (expect ffffffaa)",uut.u_core.u_regfile.registers[8]);
        $display("x9 (lbu lane3) = %h (expect 000000aa)",uut.u_core.u_regfile.registers[9]);

        // word 4, all sign bits 0, lb/lbu must agree
        $display("x12 (lw word4) = %h (expect 12345678)",uut.u_core.u_regfile.registers[12]);
        $display("x10 (lb word4 lane0) = %h (expect 00000078)",uut.u_core.u_regfile.registers[10]);
        $display("x11 (lbu word4 lane0) = %h (expect 00000078, matches x10)",uut.u_core.u_regfile.registers[11]);

        $finish;
    end

endmodule