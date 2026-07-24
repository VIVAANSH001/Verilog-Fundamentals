// core_pipelined.v
// Day 52: first structural piece of the pipelined core. IF stage only,
// pc.v feeding if_id_reg.v. core.v (Phase 3, single-cycle) is untouched
// and stays runnable as the reference to differentiate against once hazards show
// up in week 9.
module core_pipelined (
    input wire clk,
    input wire rst,
    input wire [31:0] instruction,
    output wire [31:0] pc_current,
    output wire [31:0] if_id_instr_out,
    output wire [31:0] if_id_pc_out,
    output wire [4:0] id_ex_rd_out,
    output wire [31:0] id_ex_rs1_data_out,
    output wire [31:0] id_ex_rs2_data_out,
    output wire [31:0] id_ex_imm_out,
    output wire id_ex_reg_write_out,
    output wire id_ex_mem_read_out,
    output wire id_ex_mem_write_out,
    output wire [1:0] id_ex_result_src_out,
    output wire id_ex_branch_out,
    output wire id_ex_jump_out,
    output wire id_ex_alu_src_out,
    output wire [1:0] id_ex_alu_op_out);

    // IF stage
    reg [31:0] pc_next;
    pc u_pc (.clk(clk), .rst(rst), .pc_next(pc_next), .pc_current(pc_current));

    always @(*)
    begin
        pc_next = pc_current + 32'd4;
    end

    // IF/ID pipeline register
    if_id_reg u_if_id (
        .clk(clk),
        .rst(rst),
        .instr_in(instruction),
        .pc_in(pc_current),
        .instr_out(if_id_instr_out),
        .pc_out(if_id_pc_out));
    
    // ID stage
    wire [6:0] opcode;
    wire [4:0] rd,rs1,rs2;
    wire [2:0] funct3;
    wire [6:0] funct7;
    instr_decoder u_decoder (.instr(if_id_instr_out),.opcode(opcode),.rd(rd),.rs1(rs1),.rs2(rs2),.funct3(funct3),.funct7(funct7));

    wire [31:0] imm;
    immgen u_immgen (.instr(if_id_instr_out),.imm(imm));

    wire reg_write, mem_read, mem_write, branch, jump, alu_src, mem_unsigned, alu_a_pc;
    wire [1:0] result_src, alu_op, mem_size;
    control_unit u_control (.opcode(opcode),.funct3(funct3),.reg_write(reg_write),.mem_read(mem_read),.mem_write(mem_write),.branch(branch),.jump(jump),.alu_src(alu_src),.result_src(result_src),.alu_op(alu_op),.mem_size(mem_size),.mem_unsigned(mem_unsigned),.alu_a_pc(alu_a_pc));

    // regfile write port unconnected until WB exists
    wire [31:0] rs1_data, rs2_data;
    regfile u_regfile (.clk(clk),.we(1'b0),.write_addr(5'b0),.write_data(32'b0),.read_addr1(rs1),.read_addr2(rs2),.read_data1(rs1_data),.read_data2(rs2_data));

    // ID/EX pipeline register
    id_ex_reg u_id_ex (
        .clk(clk),
        .rst(rst),
        .pc_in(if_id_pc_out),
        .rs1_data_in(rs1_data),
        .rs2_data_in(rs2_data),
        .imm_in(imm),
        .rd_in(rd),
        .rs1_in(rs1),
        .rs2_in(rs2),
        .funct3_in(funct3),
        .funct7_in(funct7),
        .reg_write_in(reg_write),
        .mem_read_in(mem_read),
        .mem_write_in(mem_write),
        .branch_in(branch),
        .jump_in(jump),
        .alu_src_in(alu_src),
        .result_src_in(result_src),
        .alu_op_in(alu_op),
        .mem_size_in(mem_size),
        .mem_unsigned_in(mem_unsigned),
        .alu_a_pc_in(alu_a_pc),
        .pc_out(),
        .rs1_data_out(id_ex_rs1_data_out),
        .rs2_data_out(id_ex_rs2_data_out),
        .imm_out(id_ex_imm_out),
        .rd_out(id_ex_rd_out),
        .rs1_out(),
        .rs2_out(),
        .funct3_out(),
        .funct7_out(),
        .reg_write_out(id_ex_reg_write_out),
        .mem_read_out(id_ex_mem_read_out),
        .mem_write_out(id_ex_mem_write_out),
        .branch_out(id_ex_branch_out),
        .jump_out(id_ex_jump_out),
        .alu_src_out(id_ex_alu_src_out),
        .result_src_out(id_ex_result_src_out),
        .alu_op_out(id_ex_alu_op_out),
        .mem_size_out(),
        .mem_unsigned_out(),
        .alu_a_pc_out());

endmodule