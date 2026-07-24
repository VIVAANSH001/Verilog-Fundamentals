`timescale 1ns/1ps
module core_pipelined_id_tb;

    reg clk, rst;
    wire [31:0] pc_current;
    wire [31:0] instruction;
    wire [31:0] if_id_instr_out, if_id_pc_out;

    wire [4:0] id_ex_rd_out;
    wire [31:0] id_ex_rs1_data_out, id_ex_rs2_data_out, id_ex_imm_out;
    wire id_ex_reg_write_out, id_ex_mem_read_out, id_ex_mem_write_out, id_ex_branch_out, id_ex_jump_out, id_ex_alu_src_out;
    wire [1:0] id_ex_result_src_out, id_ex_alu_op_out;

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
        .id_ex_branch_out(id_ex_branch_out),
        .id_ex_jump_out(id_ex_jump_out),
        .id_ex_alu_src_out(id_ex_alu_src_out),
        .id_ex_result_src_out(id_ex_result_src_out),
        .id_ex_alu_op_out(id_ex_alu_op_out));

    instr_mem u_instr_mem (.pc_current(pc_current),.instruction(instruction));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("core_pipelined_id.vcd");
        $dumpvars(0,core_pipelined_id_tb);

        clk = 0; rst = 1;
        @(posedge clk);
        #1;
        rst = 0;

        // preload distinct, non-uniform values into x1/x2 while reset is dropping
        uut.u_regfile.registers[1] = 32'd77;
        uut.u_regfile.registers[2] = 32'd13;

        // cycle1: instr1 (add) lands in if_id, id stage sees garbage/prev instr, ignore
        @(posedge clk); 
        #1;

        // cycle2: instr1 (add x3,x1,x2) is being decoded in ID now
        @(posedge clk); 
        #1;
        $display("instr1 add x3,x1,x2 --> rd=%0d rs1_data=%0d rs2_data=%0d rw=%b mr=%b mw=%b br=%b jp=%b as=%b rs=%b op=%b",id_ex_rd_out,id_ex_rs1_data_out,id_ex_rs2_data_out,id_ex_reg_write_out,id_ex_mem_read_out,id_ex_mem_write_out,id_ex_branch_out,id_ex_jump_out,id_ex_alu_src_out,id_ex_result_src_out,id_ex_alu_op_out);
        $display("                (expect rd=3 rs1_data=77 rs2_data=13 rw=1 mr=0 mw=0 br=0 jp=0 as=0 rs=00 op=10)");

        @(posedge clk); 
        #1;
        $display("instr2 addi x4,x1,-5 --> rd=%0d rs1_data=%0d imm=%0d rw=%b mr=%b mw=%b br=%b jp=%b as=%b rs=%b op=%b",id_ex_rd_out,id_ex_rs1_data_out,$signed(id_ex_imm_out),id_ex_reg_write_out,id_ex_mem_read_out,id_ex_mem_write_out,id_ex_branch_out,id_ex_jump_out,id_ex_alu_src_out,id_ex_result_src_out,id_ex_alu_op_out);
        $display("                 (expect rd=4 rs1_data=77 imm=-5 rw=1 mr=0 mw=0 br=0 jp=0 as=1 rs=00 op=10)");

        @(posedge clk); 
        #1;
        $display("instr3 lw x5,0(x1) --> rd=%0d rs1_data=%0d imm=%0d rw=%b mr=%b mw=%b br=%b jp=%b as=%b rs=%b op=%b",id_ex_rd_out,id_ex_rs1_data_out,id_ex_imm_out,id_ex_reg_write_out,id_ex_mem_read_out,id_ex_mem_write_out,id_ex_branch_out,id_ex_jump_out,id_ex_alu_src_out,id_ex_result_src_out,id_ex_alu_op_out);
        $display("               (expect rd=5 rs1_data=77 imm=0 rw=1 mr=1 mw=0 br=0 jp=0 as=1 rs=01 op=00)");

        @(posedge clk);
        #1;
        $display("instr4 sw x2,0(x1) --> rs1_data=%0d rs2_data=%0d imm=%0d rw=%b mr=%b mw=%b br=%b jp=%b as=%b rs=%b op=%b",id_ex_rs1_data_out,id_ex_rs2_data_out,id_ex_imm_out,id_ex_reg_write_out,id_ex_mem_read_out,id_ex_mem_write_out,id_ex_branch_out,id_ex_jump_out,id_ex_alu_src_out,id_ex_result_src_out,id_ex_alu_op_out);
        $display("               (expect rs1_data=77 rs2_data=13 imm=0 rw=0 mr=0 mw=1 br=0 jp=0 as=1 rs=00 op=00)");

        @(posedge clk); 
        #1;
        $display("instr5 beq x1,x2,+8 --> rs1_data=%0d rs2_data=%0d rw=%b mr=%b mw=%b br=%b jp=%b as=%b rs=%b op=%b",id_ex_rs1_data_out,id_ex_rs2_data_out,id_ex_reg_write_out,id_ex_mem_read_out,id_ex_mem_write_out,id_ex_branch_out,id_ex_jump_out,id_ex_alu_src_out,id_ex_result_src_out,id_ex_alu_op_out);
        $display("                (expect rs1_data=77 rs2_data=13 rw=0 mr=0 mw=0 br=1 jp=0 as=0 rs=00 op=01)");

        $finish;
    end

endmodule