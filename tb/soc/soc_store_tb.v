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

        rst = 1;
        #10;
        rst = 0;

        for (i = 0; i < 28; i = i + 1)
        begin
            @(posedge clk);
            #1;
        end

        // sb: checking is seam 1b works, all 4 lanes --> baseline FFFFFFFF, test to overwrite one lane with 0xAB
        $display("x10 (sb lane0) = %h (expect ffffffab)",uut.u_core.u_regfile.registers[10]);
        $display("x11 (sb lane1) = %h (expect ffffabff)",uut.u_core.u_regfile.registers[11]);
        $display("x12 (sb lane2) = %h (expect ffabffff)",uut.u_core.u_regfile.registers[12]);
        $display("x13 (sb lane3) = %h (expect abffffff)",uut.u_core.u_regfile.registers[13]);

        // sh: using baseline --> FFFFFFFF, overwrite each half with 0x0300
        $display("x14 (sh lanes01) = %h (expect ffff0300)",uut.u_core.u_regfile.registers[14]);
        $display("x15 (sh lanes23) = %h (expect 0300ffff)",uut.u_core.u_regfile.registers[15]);

        // sw: had to make sw works with a random word being abcd0123
        $display("x16 (sw distinct value) = %h (expect abcd0123)",uut.u_core.u_regfile.registers[16]);

        $finish;
    end

endmodule