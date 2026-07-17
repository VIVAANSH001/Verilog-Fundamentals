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

        for (i = 0; i < 6; i = i + 1)
        begin
            @(posedge clk);
            #1;
        end

        // LUI testing
        $display("x5 (lui basic) = %h (expect abcde000)",uut.u_core.u_regfile.registers[5]);
        $display("x6 (lui all-ones upper) = %h (expect fffff000)",uut.u_core.u_regfile.registers[6]);
        $display("x7 (lui zero) = %h (expect 00000000)",uut.u_core.u_regfile.registers[7]);

        // AUIPC testing
        $display("x8 (auipc basic) = %h (expect 0000100c)",uut.u_core.u_regfile.registers[8]);
        $display("x9 (auipc + addi composed) = %h (expect 00002133)",uut.u_core.u_regfile.registers[9]);

        $finish;
    end

endmodule