`timescale 1ns/1ps
module jal_false_stall_tb;

    reg clk, rst;
    integer i;
    wire [31:0] pc_current, instruction;
    wire [31:0] mem_addr, mem_wdata, mem_rdata;
    wire [3:0] mem_byte_en;
    wire mem_write, mem_read;
    wire [31:0] if_id_instr_out;
    wire id_ex_mem_read_out;
    wire [4:0] id_ex_rd_out;
    wire stall_out;

    core_pipelined uut (
        .clk(clk),
        .rst(rst),
        .instruction(instruction),
        .pc_current(pc_current),
        .if_id_instr_out(if_id_instr_out),
        .id_ex_mem_read_out(id_ex_mem_read_out),
        .id_ex_rd_out(id_ex_rd_out),
        .mem_rdata(mem_rdata),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_byte_en(mem_byte_en),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .stall_out(stall_out));

    instr_mem u_instr_mem (.pc_current(pc_current),.instruction(instruction));
    mem_interface u_mem_interface (.clk(clk),.addr(mem_addr),.wdata(mem_wdata),.byte_en(mem_byte_en),.mem_write(mem_write),.mem_read(mem_read),.rdata(mem_rdata));

    always #5 clk = ~clk;

    always @(posedge clk)
    begin
        if (!rst)
        begin
            #1;
            $display("cyc pc=%0d if_id_instr=%h id_ex_mem_read=%b id_ex_rd=%0d stall=%b",pc_current,if_id_instr_out,id_ex_mem_read_out,id_ex_rd_out,stall_out);
        end
    end

    initial begin
        for (i = 0; i < 4096; i = i + 1)
        begin
            u_mem_interface.ram.mem[i] = 8'h00;
        end
        u_mem_interface.ram.mem[0] = 8'h2a; // mem[0] = 42, the load target
        for (i = 0; i < 32; i = i + 1)
        begin
            uut.u_regfile.registers[i] = 32'h0;
        end

        clk = 0; rst = 1;
        @(posedge clk);
        #1;
        rst = 0;

        for (i = 0; i < 8; i = i + 1)
        begin
            @(posedge clk);
            #1;
        end

        $display("---------------------------------------------");
        $display("x5 (lw result) = %0d (expect 42, load itself should be unaffected either way)",uut.u_regfile.registers[5]);
        $display("check the per-cycle trace above: does stall=1 fire on the cycle where id_ex_rd=5 and if_id_instr is the jal (0002806f)? if so, that's the false stall, jal reads no registers.");

        $finish;
    end

endmodule