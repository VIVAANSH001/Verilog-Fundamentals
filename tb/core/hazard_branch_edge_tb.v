`timescale 1ns/1ps
module hazard_branch_edge_tb;

    reg clk, rst;
    integer i;
    wire [31:0] pc_current, instruction, if_id_instr_out;
    wire [31:0] mem_addr, mem_wdata, mem_rdata;
    wire [3:0] mem_byte_en;
    wire mem_write, mem_read;
    wire stall_out, branch_flush_out;

    core_pipelined uut (
        .clk(clk), .rst(rst),
        .instruction(instruction),
        .pc_current(pc_current),
        .if_id_instr_out(if_id_instr_out),
        .mem_rdata(mem_rdata), 
        .mem_addr(mem_addr), 
        .mem_wdata(mem_wdata),
        .mem_byte_en(mem_byte_en), 
        .mem_write(mem_write), 
        .mem_read(mem_read),
        .stall_out(stall_out), 
        .branch_flush_out(branch_flush_out));

    instr_mem u_instr_mem (.pc_current(pc_current),.instruction(instruction));
    mem_interface u_mem_interface (.clk(clk),.addr(mem_addr),.wdata(mem_wdata),.byte_en(mem_byte_en),.mem_write(mem_write),.mem_read(mem_read),.rdata(mem_rdata));

    always #5 clk = ~clk;

    always @(posedge clk)
    begin
        if (!rst)
        begin
            #1;
            if (stall_out)
            begin
                $display("cyc stall=1 (load-use bubble inserted)");
            end
            if (uut.id_ex_branch_out)
            begin
                $display("BEQ in EX: rs1_data=%0d rs2_data=%0d branch_taken=%b branch_flush=%b (real x5=42 x6=42, SHOULD take)",uut.id_ex_rs1_data_out,uut.id_ex_rs2_data_out,uut.ex_branch_taken,branch_flush_out);
            end
        end
    end

    initial begin
        for (i = 0; i < 4096; i = i + 1) 
        begin
            u_mem_interface.ram.mem[i] = 8'h00;
        end
        for (i = 0; i < 32; i = i + 1) 
        begin
            uut.u_regfile.registers[i] = 32'h0;
        end

        // preload mem[0] = 42, the load target
        u_mem_interface.ram.mem[0] = 8'h2a;
        u_mem_interface.ram.mem[1] = 8'h00;
        u_mem_interface.ram.mem[2] = 8'h00;
        u_mem_interface.ram.mem[3] = 8'h00;

        clk = 0; rst = 1;
        @(posedge clk); 
        #1;
        rst = 0;

        for (i = 0; i < 25; i = i + 1) 
        begin 
            @(posedge clk); 
            #1; 
        end

        $display("---------------------------------------------");
        $display("x5 (lw result, real value) = %0d (expect 42)",uut.u_regfile.registers[5]);
        $display("x6 (branch operand) = %0d (expect 42)",uut.u_regfile.registers[6]);
        $display("x10 = %0d, x11 = %0d --> nonzero means branch NOT taken (fallthrough ran = BUG reproduced)",uut.u_regfile.registers[10],uut.u_regfile.registers[11]);
        $display("x20 = %0d --> 99 means branch WAS taken correctly, 0 means it wasn't",uut.u_regfile.registers[20]);
        $display("x21 (always runs) = %0d (expect 55)",uut.u_regfile.registers[21]);

        $finish;
    end

endmodule