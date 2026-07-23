`timescale 1ns/1ps
module pipeline_regs_tb;

    reg clk, rst;

    // IF/ID
    reg [31:0] instr_in, pc_in;
    wire [31:0] instr_out, pc_out;
    if_id_reg u_ifid (.clk(clk),.rst(rst),.instr_in(instr_in),.pc_in(pc_in),.instr_out(instr_out),.pc_out(pc_out));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("pipeline_regs.vcd");
        $dumpvars(0,pipeline_regs_tb);

        clk = 0; rst = 1;
        instr_in = 32'hFFFFFFFF; pc_in = 32'hAAAAAAAA;
        @(posedge clk); #1;
        $display("reset: instr_out=%h pc_out=%h (expect 0 0)",instr_out,pc_out);

        rst = 0;
        instr_in = 32'h00500093; pc_in = 32'h00000000;
        @(posedge clk); #1;
        $display("latch1: instr_out=%h pc_out=%h (expect 00500093 00000000)",instr_out,pc_out);

        instr_in = 32'h12345678; pc_in = 32'h00000004;
        @(posedge clk); #1;
        $display("latch2: instr_out=%h pc_out=%h (expect 12345678 00000004)",instr_out,pc_out);

        $finish;
    end

endmodule