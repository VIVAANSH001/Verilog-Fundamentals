`timescale 1ns/1ps
module core_pipelined_ex_tb;

    reg clk, rst;
    wire [31:0] pc_current;
    wire [31:0] instruction;
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
        .ex_mem_mem_unsigned_out(ex_mem_mem_unsigned_out));

    instr_mem u_instr_mem (.pc_current(pc_current),.instruction(instruction));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("core_pipelined_ex.vcd");
        $dumpvars(0,core_pipelined_ex_tb);

        clk = 0; rst = 1;
        @(posedge clk); 
        #1;
        rst = 0;

        // preload distinct, non-uniform values into x1/x2 while reset is dropping
        uut.u_regfile.registers[1] = 32'd77;
        uut.u_regfile.registers[2] = 32'd13;

        // cycle1: instr1 (add) lands in if_id
        @(posedge clk); 
        #1;

        // cycle2: instr1 is being decoded in ID now
        @(posedge clk); 
        #1;

        // cycle3: instr1's EX result lands in ex_mem_reg
        @(posedge clk); 
        #1;
        $display("instr1 add x3,x1,x2 --> alu_result=%0d rd=%0d rw=%b (expect 90 rd=3 rw=1)",ex_mem_alu_result_out,ex_mem_rd_out,ex_mem_reg_write_out);

        @(posedge clk); 
        #1;
        $display("instr2 sub x4,x1,x2 --> alu_result=%0d rd=%0d (expect 64 rd=4)",ex_mem_alu_result_out,ex_mem_rd_out);

        @(posedge clk); 
        #1;
        $display("instr3 addi x5,x1,-7 --> alu_result=%0d rd=%0d (expect 70 rd=5)",ex_mem_alu_result_out,ex_mem_rd_out);

        @(posedge clk); 
        #1;
        $display("instr4 and x6,x1,x2 --> alu_result=%0d rd=%0d (expect 13 rd=6)",ex_mem_alu_result_out,ex_mem_rd_out);

        // instr5 (auipc) lands in ex_mem here; instr6 (beq) is combinationally
        // in EX right now too
        @(posedge clk); 
        #1;
        $display("instr5 auipc x7,1 --> alu_result=%0d pc_in=%0d rd=%0d (expect 4112 pc_in=16 rd=7)",ex_mem_alu_result_out,ex_mem_pc_out,ex_mem_rd_out);
        $display("instr6 beq x1,x2,8 (in EX now) --> branch=%b branch_taken_final=%b (expect branch=1 taken=0, 77 != 13)",id_ex_branch_out,uut.ex_branch_taken_final);

        $finish;
    end

endmodule