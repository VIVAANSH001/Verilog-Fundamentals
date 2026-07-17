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

        for (i = 0; i < 30; i = i + 1)
        begin
            @(posedge clk);
            #1;
        end

        // Test 1: JAL forward, link register + skip proof
        $display("x5 (jal link, Test 1) = %h (expect 00000004)",uut.u_core.u_regfile.registers[5]);
        $display("x30 (Test 1 landed not skipped) = %0d (expect 222)",uut.u_core.u_regfile.registers[30]);

        // Test 2: JAL backward, negative immediate
        $display("x31 (Test 2 backward jal) = %0d (expect 222)",uut.u_core.u_regfile.registers[31]);

        // Test 3: JALR round trip, call via jal ra + return via jalr x0,0(ra)
        $display("x1 (ra, Test 3 call link) = %h (expect 00000024)",uut.u_core.u_regfile.registers[1]);
        $display("x22 (Test 3 inside function) = %0d (expect 333)",uut.u_core.u_regfile.registers[22]);
        $display("x21 (Test 3 returned correctly) = %0d (expect 222)",uut.u_core.u_regfile.registers[21]);

        // Test 4: JALR with nonzero positive immediate (rs1 + imm)
        $display("x24 (Test 4 jalr rs1+imm) = %0d (expect 222)",uut.u_core.u_regfile.registers[24]);

        // Test 5: JALR bit-0 clear, proven via a following jal's link register
        $display("x26 (Test 5 bit0-clear proof) = %h (expect 00000054)",uut.u_core.u_regfile.registers[26]);

        // Test 6: JALR with rd != x0, proves JALR's own link write
        $display("x27 (Test 6 jalr own link) = %h (expect 00000058)",uut.u_core.u_regfile.registers[27]);
        $display("x28 (Test 6 landed, rd!=x0) = %0d (expect 222)",uut.u_core.u_regfile.registers[28]);

        // Test 7: JALR with negative immediate
        $display("x29 (Test 7 jalr negative imm)  = %0d (expect 222)",uut.u_core.u_regfile.registers[29]);

        $finish;
    end

endmodule