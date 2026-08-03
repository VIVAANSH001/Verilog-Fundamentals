`timescale 1ns/1ps
module core_pipelined_fib_tb;

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
        for (i = 0; i < 4096; i = i + 1) 
        begin
            u_mem_interface.ram.mem[i] = 8'h00;
        end
        for (i = 0; i < 32; i = i + 1) 
        begin
            uut.u_regfile.registers[i] = 32'h0;
        end

        clk = 0; rst = 1;
        @(posedge clk);
        #1;
        rst = 0;

        for (i = 0; i < 120; i = i + 1)
        begin
            @(posedge clk);
            #1;
        end

        $display("x1 (a, fib result) = %0d (expect 55)",uut.u_regfile.registers[1]);
        $display("x2 (b, fib next term) = %0d (expect 89)",uut.u_regfile.registers[2]);
        $display("x4 (i, loop counter) = %0d (expect 10)",uut.u_regfile.registers[4]);
        $display("x5 (N, loop bound) = %0d (expect 10)",uut.u_regfile.registers[5]);

        $finish;
    end

endmodule