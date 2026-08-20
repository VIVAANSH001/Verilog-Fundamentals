`timescale 1ns/1ps
module regfile_writethrough_tb;

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
    mem_interface u_mem_interface (.clk(clk),.rst(rst),.addr(mem_addr),.wdata(mem_wdata),.byte_en(mem_byte_en),.mem_write(mem_write),.mem_read(mem_read),.rdata(mem_rdata));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("regfile_writethrough.vcd");
        $dumpvars(0,regfile_writethrough_tb);

        clk = 0; rst = 1;
        @(posedge clk);
        #1;
        rst = 0;

        for (i = 0; i < 15; i = i + 1)
        begin
            @(posedge clk);
            #1;
        end

        $display("x1 = %0d (expect 5)",uut.u_regfile.registers[1]);
        $display("x2 = %0d (expect 3)",uut.u_regfile.registers[2]);
        $display("x3 producer add x1+x2 = %0d (expect 8)",uut.u_regfile.registers[3]);
        $display("x4 gap=1 addi x3+1 = %0d (expect 9, fixed by forwarding)",uut.u_regfile.registers[4]);
        $display("x5 gap=2 add x3+x3 = %0d (expect 16, fixed by forwarding)",uut.u_regfile.registers[5]);
        $display("x6 gap=3 add x3+x3 = %0d (expect 16, fixed by regfile write-through)",uut.u_regfile.registers[6]);
        $display("x7 gap=4 add x3+x3 = %0d (expect 16, was already correct via spacing)",uut.u_regfile.registers[7]);

        $finish;
    end

endmodule