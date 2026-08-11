`timescale 1ns/1ps
module core_pipelined_branch_scenarios_tb;

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
    mem_interface u_mem_interface (.clk(clk),.addr(mem_addr),.wdata(mem_wdata),.byte_en(mem_byte_en),.mem_write(mem_write),.mem_read(mem_read),.rdata(mem_rdata));

    always #5 clk = ~clk;

    always @(posedge clk)
    begin
        if (!rst)
        begin
            #1;
            if (id_ex_branch_out)
            begin
                $display("cyc=%0d branch in EX: funct3=%b rs1_data=%0d rs2_data=%0d branch_taken=%b branch_flush=%b",cyc,uut.id_ex_funct3_out,id_ex_rs1_data_out,id_ex_rs2_data_out,uut.ex_branch_taken, branch_flush_out);
            end
            cyc = cyc + 1;
        end
    end

    initial begin
        $dumpfile("core_pipelined_branch_scenarios.vcd");
        $dumpvars(0,core_pipelined_branch_scenarios_tb);
        
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

        for (i = 0; i < 60; i = i + 1)
        begin
            @(posedge clk);
            #1;
        end

        $display("Section A: all 6 branch types (x1=-1, x2=3)");
        $display("BEQ (not taken): x10=%0d x11=%0d (expect 111,222, executes normally) | x12=%0d (expect 99)",uut.u_regfile.registers[10],uut.u_regfile.registers[11],uut.u_regfile.registers[12]);
        $display("BNE (taken): x13=%0d x14=%0d (expect 0,0, flushed) | x15=%0d (expect 99)",uut.u_regfile.registers[13],uut.u_regfile.registers[14],uut.u_regfile.registers[15]);
        $display("BLT (taken): x16=%0d x17=%0d (expect 0,0, flushed) | x18=%0d (expect 99)",uut.u_regfile.registers[16],uut.u_regfile.registers[17],uut.u_regfile.registers[18]);
        $display("BGE (not taken): x19=%0d x20=%0d (expect 111,222, executes normally) | x21=%0d (expect 99)",uut.u_regfile.registers[19],uut.u_regfile.registers[20],uut.u_regfile.registers[21]);
        $display("BLTU (not taken): x22=%0d x23=%0d (expect 111,222, executes normally) | x24=%0d (expect 99)",uut.u_regfile.registers[22],uut.u_regfile.registers[23],uut.u_regfile.registers[24]);
        $display("BGEU (taken): x25=%0d x26=%0d (expect 0,0, flushed) | x27=%0d (expect 99)",uut.u_regfile.registers[25],uut.u_regfile.registers[26],uut.u_regfile.registers[27]);

        $display("Section B: backward branch loop (3 iterations)");
        $display("x30 (final counter) = %0d (expect 0)",uut.u_regfile.registers[30]);
        $display("x31 (loop trip count) = %0d (expect 3)",uut.u_regfile.registers[31]);
        $display("x28 (post loop marker) = %0d (expect 77, correct exit continuation)",uut.u_regfile.registers[28]);

        $finish;
    end

endmodule