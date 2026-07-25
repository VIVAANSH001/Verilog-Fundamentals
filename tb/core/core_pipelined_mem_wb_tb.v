`timescale 1ns/1ps
module core_pipelined_mem_wb_tb;

    reg clk, rst;
    integer i;
    wire [31:0] pc_current, instruction;
    wire [31:0] mem_addr, mem_wdata, mem_rdata;
    wire [3:0] mem_byte_en;
    wire mem_write, mem_read;

    core_pipelined uut (
        .clk(clk),
        .rst(rst),
        .instruction(instruction),
        .pc_current(pc_current),
        .mem_rdata(mem_rdata),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_byte_en(mem_byte_en),
        .mem_write(mem_write),
        .mem_read(mem_read));

    instr_mem u_instr_mem (.pc_current(pc_current),.instruction(instruction));
    mem_interface u_mem_interface (.clk(clk),.addr(mem_addr),.wdata(mem_wdata),.byte_en(mem_byte_en),.mem_write(mem_write),.mem_read(mem_read),.rdata(mem_rdata));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("core_pipelined_mem_wb.vcd");
        $dumpvars(0,core_pipelined_mem_wb_tb);

        // RAM powers up uninitialized
        for (i = 0; i < 4096; i = i + 1)
            u_mem_interface.ram.mem[i] = 8'h00;

        clk = 0; rst = 1;
        @(posedge clk); #1;
        rst = 0;

        // preload distinct, non-uniform values into x1/x2 while reset drops
        uut.u_regfile.registers[1] = 32'd77;
        uut.u_regfile.registers[2] = 32'd13;

        // give the pipeline enough cycles for all 8 instructions to clear WB
        for (i = 0; i < 15; i = i + 1)
        begin
            @(posedge clk);
            #1;
        end

        $display("x3 (addi base=100) = %0d (expect 100)",uut.u_regfile.registers[3]);
        $display("x4 (add, ALU writeback) = %0d (expect 90)",uut.u_regfile.registers[4]);
        $display("x5 (lw, load writeback) = %0d (expect 13)",uut.u_regfile.registers[5]);
        $display("x6 (filler) = %0d (expect 0)",uut.u_regfile.registers[6]);
        $display("x7 (lb, byte writeback) = %0d (expect 77)",uut.u_regfile.registers[7]);
        $display("x8 (jal, pc+4 writeback) = %0d (expect 40)",uut.u_regfile.registers[8]);

        $finish;
    end

endmodule