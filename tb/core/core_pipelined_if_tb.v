`timescale 1ns/1ps
module core_pipelined_if_tb;

    reg clk, rst;
    wire [31:0] pc_current;
    wire [31:0] instruction;
    wire [31:0] if_id_instr_out, if_id_pc_out;

    core_pipelined uut (
        .clk(clk),
        .rst(rst),
        .instruction(instruction),
        .pc_current(pc_current),
        .if_id_instr_out(if_id_instr_out),
        .if_id_pc_out(if_id_pc_out));

    instr_mem u_instr_mem (.pc_current(pc_current),.instruction(instruction));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("core_pipelined_if.vcd");
        $dumpvars(0,core_pipelined_if_tb);

        clk = 0; rst = 1;
        @(posedge clk); 
        #1;
        $display("reset: pc=%h if_id_instr=%h if_id_pc=%h (expect 00000000 00000000 00000000)",pc_current,if_id_instr_out,if_id_pc_out);

        rst = 0;
        @(posedge clk); 
        #1;
        $display("cycle1: pc=%h if_id_instr=%h if_id_pc=%h (expect 00000004 00000093 00000000)",pc_current,if_id_instr_out,if_id_pc_out);

        @(posedge clk); 
        #1;
        $display("cycle2: pc=%h if_id_instr=%h if_id_pc=%h (expect 00000008 00100113 00000004)",pc_current,if_id_instr_out,if_id_pc_out);

        @(posedge clk);
        #1;
        $display("cycle3: pc=%h if_id_instr=%h if_id_pc=%h (expect 0000000c 00000213 00000008)",pc_current,if_id_instr_out,if_id_pc_out);

        $finish;
    end

endmodule