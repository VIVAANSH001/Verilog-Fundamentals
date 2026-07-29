`timescale 1ns/1ps
module core_pipelined_hazard_scenarios_tb;

    reg clk, rst;
    integer i;
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
    wire stall_out;

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
        .stall_out(stall_out));

    instr_mem u_instr_mem (.pc_current(pc_current),.instruction(instruction));
    mem_interface u_mem_interface (.clk(clk),.addr(mem_addr),.wdata(mem_wdata),.byte_en(mem_byte_en),.mem_write(mem_write),.mem_read(mem_read),.rdata(mem_rdata));

    always #5 clk = ~clk;

    // fires whenever a BEQ reaches EX, catches it regardless of how many
    // stall cycles pushed it there, no manual cycle counting needed
    always @(posedge clk) 
    begin
        if (!rst)
        begin
            #1;
            if (id_ex_branch_out)
            begin
                $display("BEQ in EX: rs1=%0d rs2=%0d branch_taken=%b stall=%b (expect rs1=42 rs2=42 taken=1)",id_ex_rs1_data_out,id_ex_rs2_data_out,uut.ex_branch_taken, stall_out);
            end
        end
    end

    initial begin
        $dumpfile("core_pipelined_hazard_scenarios.vcd");
        $dumpvars(0,core_pipelined_hazard_scenarios_tb);

        for (i = 0; i < 4096; i = i + 1)
        begin
            u_mem_interface.ram.mem[i] = 8'h00;
        end

        // word preloads, low byte only (rest already zeroed)
        u_mem_interface.ram.mem[0] = 8'h14; // mem[0] = 20
        u_mem_interface.ram.mem[4] = 8'h07; // mem[4] = 7
        u_mem_interface.ram.mem[8] = 8'h18; // mem[8] = 24 (address value)
        u_mem_interface.ram.mem[12] = 8'h63; // mem[12] = 99
        u_mem_interface.ram.mem[16] = 8'h2A; // mem[16] = 42
        u_mem_interface.ram.mem[24] = 8'h4D; // mem[24] = 77

        clk = 0; rst = 1;
        @(posedge clk); 
        #1;
        rst = 0;

        // 18 instructions + several stall bubbles + fill/drain,thus giving generous headroom
        for (i = 0; i < 40; i = i + 1) 
        begin
            @(posedge clk);
            #1;
        end

        $display("Scenario 1: load feeds rs2, gap=0");
        $display("x5 = %0d (expect 20)",uut.u_regfile.registers[5]);
        $display("x7 = %0d (expect 23)",uut.u_regfile.registers[7]);

        $display("Scenario 2: load feeds both rs1 and rs2");
        $display("x8 = %0d (expect 7)",uut.u_regfile.registers[8]);
        $display("x9 = %0d (expect 14)",uut.u_regfile.registers[9]);

        $display("Scenario 3: chained load-use (address dependency)");
        $display("x10 = %0d (expect 24)",uut.u_regfile.registers[10]);
        $display("x11 = %0d (expect 77)",uut.u_regfile.registers[11]);

        $display("Scenario 4: gap=1 filler, should not stall");
        $display("x12 = %0d (expect 99)",uut.u_regfile.registers[12]);
        $display("x14 = %0d (expect 104)",uut.u_regfile.registers[14]);

        $display("Scenario 5: load feeds branch (see BEQ display above)");

        $display("Scenario 6: two independent hazards back-to-back");
        $display("x20 = %0d (expect 77)",uut.u_regfile.registers[20]);
        $display("x21 = %0d (expect 80)",uut.u_regfile.registers[21]);
        $display("x22 = %0d (expect 7)",uut.u_regfile.registers[22]);
        $display("x23 = %0d (expect 10)",uut.u_regfile.registers[23]);

        $finish;
    end

endmodule