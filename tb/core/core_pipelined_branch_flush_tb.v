`timescale 1ns/1ps
module core_pipelined_branch_flush_tb;

    reg clk, rst;
    integer i;
    integer cyc;
    wire [31:0] pc_current, instruction;
    wire [31:0] mem_addr, mem_wdata, mem_rdata;
    wire [3:0] mem_byte_en;
    wire mem_write, mem_read;
    wire [31:0] if_id_instr_out, if_id_pc_out;
    wire [4:0] id_ex_rd_out;
    wire [31:0] id_ex_rs1_data_out, id_ex_rs2_data_out, id_ex_imm_out;
    wire id_ex_reg_write_out, id_ex_mem_read_out, id_ex_mem_write_out, id_ex_branch_out, id_ex_jump_out, id_ex_alu_src_out;
    wire [1:0] id_ex_result_src_out, id_ex_alu_op_out;
    wire [31:0] ex_mem_alu_result_out, ex_mem_rs2_data_out, ex_mem_pc_out, ex_mem_imm_out;
    wire [4:0] ex_mem_rd_out;
    wire ex_mem_reg_write_out, ex_mem_mem_read_out, ex_mem_mem_write_out;
    wire [1:0] ex_mem_result_src_out, ex_mem_mem_size_out;
    wire ex_mem_mem_unsigned_out;
    wire [31:0] mem_wb_alu_result_out, mem_wb_load_data_out;
    wire [4:0] mem_wb_rd_out;
    wire mem_wb_reg_write_out;
    wire [1:0] mem_wb_result_src_out;
    wire [31:0] write_back_data_out;
    wire stall_out, branch_flush_out;

    core_pipelined uut (
        .clk(clk),
        .rst(rst),
        .instruction(instruction),
        .pc_current(pc_current),
        .if_id_instr_out(if_id_instr_out),
        .if_id_pc_out(if_id_pc_out),
        .id_ex_rd_out(id_ex_rd_out),
        .id_ex_rs1_data_out(id_ex_rs1_data_out),
        .id_ex_rs2_data_out(id_ex_rs2_data_out),
        .id_ex_imm_out(id_ex_imm_out),
        .id_ex_reg_write_out(id_ex_reg_write_out),
        .id_ex_mem_read_out(id_ex_mem_read_out),
        .id_ex_mem_write_out(id_ex_mem_write_out), 
        .id_ex_result_src_out(id_ex_result_src_out),
        .id_ex_branch_out(id_ex_branch_out), 
        .id_ex_jump_out(id_ex_jump_out),
        .id_ex_alu_src_out(id_ex_alu_src_out), 
        .id_ex_alu_op_out(id_ex_alu_op_out),
        .ex_mem_alu_result_out(ex_mem_alu_result_out), 
        .ex_mem_rs2_data_out(ex_mem_rs2_data_out),
        .ex_mem_pc_out(ex_mem_pc_out), 
        .ex_mem_imm_out(ex_mem_imm_out), 
        .ex_mem_rd_out(ex_mem_rd_out),
        .ex_mem_reg_write_out(ex_mem_reg_write_out), 
        .ex_mem_mem_read_out(ex_mem_mem_read_out),
        .ex_mem_mem_write_out(ex_mem_mem_write_out), 
        .ex_mem_result_src_out(ex_mem_result_src_out),
        .ex_mem_mem_size_out(ex_mem_mem_size_out), 
        .ex_mem_mem_unsigned_out(ex_mem_mem_unsigned_out),
        .mem_rdata(mem_rdata), 
        .mem_addr(mem_addr), 
        .mem_wdata(mem_wdata),
        .mem_byte_en(mem_byte_en), 
        .mem_write(mem_write), 
        .mem_read(mem_read),
        .mem_wb_alu_result_out(mem_wb_alu_result_out), 
        .mem_wb_load_data_out(mem_wb_load_data_out),
        .mem_wb_rd_out(mem_wb_rd_out), 
        .mem_wb_reg_write_out(mem_wb_reg_write_out),
        .mem_wb_result_src_out(mem_wb_result_src_out),
        .write_back_data_out(write_back_data_out), 
        .stall_out(stall_out),
        .branch_flush_out(branch_flush_out));

    instr_mem u_instr_mem (.pc_current(pc_current),.instruction(instruction));
    mem_interface u_mem_interface (.clk(clk),.rst(rst),.addr(mem_addr),.wdata(mem_wdata),.byte_en(mem_byte_en),.mem_write(mem_write),.mem_read(mem_read),.rdata(mem_rdata));

    always #5 clk = ~clk;

    always @(posedge clk)
    begin
        if (!rst)
        begin
            #1;
            $display("cyc=%0d pc=%0d if_id_instr=%h | id_ex_branch=%b ex_branch_taken=%b branch_flush=%b | stall=%b",cyc,pc_current,if_id_instr_out,id_ex_branch_out,uut.ex_branch_taken,branch_flush_out,stall_out);
            cyc = cyc + 1;
        end
    end

    initial begin
        cyc = 0;
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

        for (i = 0; i < 32; i = i + 1)
        begin
            @(posedge clk);
            #1;
        end

        $display("Branch 1 (beq, taken)");
        $display("x10 = %0d (expect 0, flushed wrong path)",uut.u_regfile.registers[10]);
        $display("x11 = %0d (expect 0, flushed wrong path)",uut.u_regfile.registers[11]);
        $display("x12 = %0d (expect 99, branch target executed)",uut.u_regfile.registers[12]);

        $display("Branch 2 (bne, taken)");
        $display("x13 = %0d (expect 0, flushed wrong path)",uut.u_regfile.registers[13]);
        $display("x14 = %0d (expect 0, flushed wrong path)",uut.u_regfile.registers[14]);
        $display("x15 = %0d (expect 88, branch target executed)",uut.u_regfile.registers[15]);

        $display("Branch 3 (beq, not taken)");
        $display("x16 = %0d (expect 55, normal fallthrough)",uut.u_regfile.registers[16]);
        $display("x17 = %0d (expect 66, normal fallthrough)",uut.u_regfile.registers[17]);

        $finish;
    end

endmodule