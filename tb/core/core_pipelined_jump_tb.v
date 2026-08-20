`timescale 1ns/1ps
module core_pipelined_jump_tb;

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
    wire stall_out, branch_flush_out, jalr_flush_out, jal_flush_out;

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
        .branch_flush_out(branch_flush_out),
        .jalr_flush_out(jalr_flush_out), 
        .jal_flush_out(jal_flush_out));

    instr_mem u_instr_mem (.pc_current(pc_current),.instruction(instruction));
    mem_interface u_mem_interface (.clk(clk),.rst(rst),.addr(mem_addr),.wdata(mem_wdata),.byte_en(mem_byte_en),.mem_write(mem_write),.mem_read(mem_read),.rdata(mem_rdata));

    always #5 clk = ~clk;

    always @(posedge clk)
    begin
        if (!rst)
        begin
            #1;
            $display("cyc=%0d pc=%0d if_id_instr=%h | jal=%b jalr=%b branch_flush=%b stall=%b",cyc,pc_current,if_id_instr_out,jal_flush_out,jalr_flush_out,branch_flush_out,stall_out);
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

        $display("Scenario 1: JAL forward + link");
        $display("x10 (link) = %0d (expect 8)",uut.u_regfile.registers[10]);
        $display("x20 (skipped) = %0d (expect 0)",uut.u_regfile.registers[20]);
        $display("x21 (landed) = %0d (expect 99)",uut.u_regfile.registers[21]);

        $display("Scenario 2: JALR call/return + forwarding + bit0 clear");
        $display("x1 (link) = %0d (expect 20)",uut.u_regfile.registers[1]);
        $display("x29 (return landed) = %0d (expect 222)",uut.u_regfile.registers[29]);
        $display("x7 (odd target) = %0d (expect 41)",uut.u_regfile.registers[7]);
        $display("x8 (jalr link) = %0d (expect 36)",uut.u_regfile.registers[8]);
        $display("x31 (jalr landed, bit0 cleared + forwarded rs1) = %0d (expect 222)",uut.u_regfile.registers[31]);

        $display("Scenario 3: JAL backward (trap loop, steady-state check)");
        $display("x24 (pre-loop marker) = %0d (expect 50)",uut.u_regfile.registers[24]);
        $display("x27 (reached only via backward jal) = %0d (expect 111)",uut.u_regfile.registers[27]);
        $display("x28 (loop body) = %0d (expect 42)",uut.u_regfile.registers[28]);

        $finish;
    end

endmodule