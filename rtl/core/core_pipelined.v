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
    output wire [1:0] id_ex_alu_op_out,
    output wire [31:0] ex_mem_alu_result_out,
    output wire [31:0] ex_mem_rs2_data_out,
    output wire [31:0] ex_mem_pc_out,
    output wire [31:0] ex_mem_imm_out,
    output wire [4:0] ex_mem_rd_out,
    output wire ex_mem_reg_write_out,
    output wire ex_mem_mem_read_out,
    output wire ex_mem_mem_write_out,
    output wire [1:0] ex_mem_result_src_out,
    output wire [1:0] ex_mem_mem_size_out,
    output wire ex_mem_mem_unsigned_out,
    input wire [31:0] mem_rdata,
    output wire [31:0] mem_addr,
    output wire [31:0] mem_wdata,
    output wire [3:0] mem_byte_en,
    output wire mem_write,
    output wire mem_read,
    output wire [31:0] mem_wb_alu_result_out,
    output wire [31:0] mem_wb_load_data_out,
    output wire [4:0] mem_wb_rd_out,
    output wire mem_wb_reg_write_out,
    output wire [1:0] mem_wb_result_src_out,
    output wire [31:0] write_back_data_out);

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

    wire reg_write, id_mem_read, id_mem_write, branch, jump, alu_src, mem_unsigned, alu_a_pc;
    wire [1:0] result_src, alu_op, mem_size;
    control_unit u_control (.opcode(opcode),.funct3(funct3),.reg_write(reg_write),.mem_read(id_mem_read),.mem_write(id_mem_write),.branch(branch),.jump(jump),.alu_src(alu_src),.result_src(result_src),.alu_op(alu_op),.mem_size(mem_size),.mem_unsigned(mem_unsigned),.alu_a_pc(alu_a_pc));

    wire [31:0] rs1_data, rs2_data;
    regfile u_regfile (.clk(clk),.we(mem_wb_reg_write_out),.write_addr(mem_wb_rd_out),.write_data(write_back_data),.read_addr1(rs1),.read_addr2(rs2),.read_data1(rs1_data),.read_data2(rs2_data));

    wire [31:0] id_ex_pc_out;
    wire [4:0] id_ex_rs1_out, id_ex_rs2_out;
    wire [2:0] id_ex_funct3_out;
    wire [6:0] id_ex_funct7_out;
    wire [1:0] id_ex_mem_size_out;
    wire id_ex_mem_unsigned_out;
    wire id_ex_alu_a_pc_out;
    wire [31:0] mem_wb_pc_out;
    wire [31:0] mem_wb_imm_out;
    
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
        .mem_read_in(id_mem_read),
        .mem_write_in(id_mem_write),
        .branch_in(branch),
        .jump_in(jump),
        .alu_src_in(alu_src),
        .result_src_in(result_src),
        .alu_op_in(alu_op),
        .mem_size_in(mem_size),
        .mem_unsigned_in(mem_unsigned),
        .alu_a_pc_in(alu_a_pc),
        .pc_out(id_ex_pc_out),
        .rs1_data_out(id_ex_rs1_data_out),
        .rs2_data_out(id_ex_rs2_data_out),
        .imm_out(id_ex_imm_out),
        .rd_out(id_ex_rd_out),
        .rs1_out(id_ex_rs1_out),
        .rs2_out(id_ex_rs2_out),
        .funct3_out(id_ex_funct3_out),
        .funct7_out(id_ex_funct7_out),
        .reg_write_out(id_ex_reg_write_out),
        .mem_read_out(id_ex_mem_read_out),
        .mem_write_out(id_ex_mem_write_out),
        .branch_out(id_ex_branch_out),
        .jump_out(id_ex_jump_out),
        .alu_src_out(id_ex_alu_src_out),
        .result_src_out(id_ex_result_src_out),
        .alu_op_out(id_ex_alu_op_out),
        .mem_size_out(id_ex_mem_size_out),
        .mem_unsigned_out(id_ex_mem_unsigned_out),
        .alu_a_pc_out(id_ex_alu_a_pc_out));
    
    // EX stage
    wire [3:0] ex_alu_ctrl;
    alu_control u_alu_control (.alu_op(id_ex_alu_op_out),.funct3(id_ex_funct3_out),.funct7(id_ex_funct7_out),.alu_src(id_ex_alu_src_out),.alu_ctrl(ex_alu_ctrl));

    wire [31:0] alu_a_forwarded = (forward_a == 2'b01) ? ex_mem_alu_result_out : (forward_a == 2'b10) ? write_back_data : id_ex_rs1_data_out;
    wire [31:0] alu_b_forwarded = (forward_b == 2'b01) ? ex_mem_alu_result_out : (forward_b == 2'b10) ? write_back_data : id_ex_rs2_data_out;

    wire [31:0] ex_alu_a = id_ex_alu_a_pc_out ? id_ex_pc_out : alu_a_forwarded;
    wire [31:0] ex_alu_b = id_ex_alu_src_out ? id_ex_imm_out : alu_b_forwarded;

    wire [31:0] ex_alu_result;
    wire ex_alu_zero;
    alu_32 u_alu (.a(ex_alu_a),.b(ex_alu_b),.alu_ctrl(ex_alu_ctrl),.result(ex_alu_result),.zero(ex_alu_zero));

    wire ex_branch_taken;
    branch_comp u_branch_comp (.rs1_data(id_ex_rs1_data_out),.rs2_data(id_ex_rs2_data_out),.funct3(id_ex_funct3_out),.branch_taken(ex_branch_taken));

    // not wired back to PC yet, control hazard handling is Week 9 (Day 62)
    wire ex_branch_taken_final = id_ex_branch_out & ex_branch_taken;

    // EX/MEM pipeline register
    ex_mem_reg u_ex_mem (
        .clk(clk),
        .rst(rst),
        .alu_result_in(ex_alu_result),
        .rs2_data_in(id_ex_rs2_data_out),
        .pc_in(id_ex_pc_out),
        .imm_in(id_ex_imm_out),
        .rd_in(id_ex_rd_out),
        .reg_write_in(id_ex_reg_write_out),
        .mem_read_in(id_ex_mem_read_out),
        .mem_write_in(id_ex_mem_write_out),
        .result_src_in(id_ex_result_src_out),
        .mem_size_in(id_ex_mem_size_out),
        .mem_unsigned_in(id_ex_mem_unsigned_out),
        .alu_result_out(ex_mem_alu_result_out),
        .rs2_data_out(ex_mem_rs2_data_out),
        .pc_out(ex_mem_pc_out),
        .imm_out(ex_mem_imm_out),
        .rd_out(ex_mem_rd_out),
        .reg_write_out(ex_mem_reg_write_out),
        .mem_read_out(ex_mem_mem_read_out),
        .mem_write_out(ex_mem_mem_write_out),
        .result_src_out(ex_mem_result_src_out),
        .mem_size_out(ex_mem_mem_size_out),
        .mem_unsigned_out(ex_mem_mem_unsigned_out));
    
    // MEM stage
    // seam 1b: store data positioning (duplicated from core.v, mem_interface.v stays untouched)
    reg [31:0] mem_wdata_r;
    always @(*)
    begin
        case (ex_mem_mem_size_out)
            2'b00: // byte
                case (ex_mem_alu_result_out[1:0])
                    2'b00: 
                    begin
                        mem_wdata_r = {24'b0, ex_mem_rs2_data_out[7:0]};
                    end
                    2'b01: 
                    begin
                        mem_wdata_r = {16'b0, ex_mem_rs2_data_out[7:0], 8'b0};
                    end
                    2'b10: 
                    begin
                        mem_wdata_r = {8'b0, ex_mem_rs2_data_out[7:0], 16'b0};
                    end
                    2'b11: 
                    begin
                        mem_wdata_r = {ex_mem_rs2_data_out[7:0], 24'b0};
                    end
                endcase
            2'b01: // half
            begin
                mem_wdata_r = ex_mem_alu_result_out[1] ? {ex_mem_rs2_data_out[15:0], 16'b0} : {16'b0, ex_mem_rs2_data_out[15:0]};
            end
            default: // word
            begin
                mem_wdata_r = ex_mem_rs2_data_out;
            end
        endcase
    end
    assign mem_wdata = mem_wdata_r;

    // seam 1: byte_en generator
    reg [3:0] byte_en_r;
    always @(*)
    begin
        case (ex_mem_mem_size_out)
            2'b00: // byte
                case (ex_mem_alu_result_out[1:0])
                    2'b00: 
                    begin
                        byte_en_r = 4'b0001;
                    end
                    2'b01: 
                    begin
                        byte_en_r = 4'b0010;
                    end
                    2'b10: 
                    begin
                        byte_en_r = 4'b0100;
                    end
                    2'b11: 
                    begin
                        byte_en_r = 4'b1000;
                    end
                endcase
            2'b01: // half
            begin
                byte_en_r = ex_mem_alu_result_out[1] ? 4'b1100 : 4'b0011;
            end
            2'b10: // word
            begin
                byte_en_r = 4'b1111;
            end
            default:
            begin
                byte_en_r = 4'b0000;
            end
        endcase
    end
    assign mem_byte_en = byte_en_r;

    assign mem_addr = ex_mem_alu_result_out;
    assign mem_write = ex_mem_mem_write_out;
    assign mem_read = ex_mem_mem_read_out;

    // seam 2: load sign/zero extend (duplicated from core.v)
    // mem_rdata is combinational off mem_addr this same cycle, so this reads live,
    wire [7:0]  load_byte = (ex_mem_alu_result_out[1:0]==2'b00) ? mem_rdata[7:0] : (ex_mem_alu_result_out[1:0]==2'b01) ? mem_rdata[15:8] : (ex_mem_alu_result_out[1:0]==2'b10) ? mem_rdata[23:16] : mem_rdata[31:24];
    wire [15:0] load_half = ex_mem_alu_result_out[1] ? mem_rdata[31:16] : mem_rdata[15:0];

    reg [31:0] load_data;
    always @(*)
    begin
        case (ex_mem_mem_size_out)
            2'b00: 
            begin
                load_data = ex_mem_mem_unsigned_out ? {24'b0, load_byte} : {{24{load_byte[7]}}, load_byte};
            end
            2'b01: 
            begin
                load_data = ex_mem_mem_unsigned_out ? {16'b0, load_half} : {{16{load_half[15]}}, load_half};
            end
            default: 
            begin
                load_data = mem_rdata;
            end
        endcase
    end

    // MEM/WB pipeline register
    mem_wb_reg u_mem_wb (
        .clk(clk),
        .rst(rst),
        .alu_result_in(ex_mem_alu_result_out),
        .load_data_in(load_data),
        .pc_in(ex_mem_pc_out),
        .imm_in(ex_mem_imm_out),
        .rd_in(ex_mem_rd_out),
        .reg_write_in(ex_mem_reg_write_out),
        .result_src_in(ex_mem_result_src_out),
        .alu_result_out(mem_wb_alu_result_out),
        .load_data_out(mem_wb_load_data_out),
        .pc_out(mem_wb_pc_out),
        .imm_out(mem_wb_imm_out),
        .rd_out(mem_wb_rd_out),
        .reg_write_out(mem_wb_reg_write_out),
        .result_src_out(mem_wb_result_src_out));


    // WB stage: writeback mux
    reg [31:0] write_back_data;
    always @(*)
    begin
        case (mem_wb_result_src_out)
            2'b00:
            begin
                write_back_data = mem_wb_alu_result_out;
            end
            2'b01: 
            begin
                write_back_data = mem_wb_load_data_out;
            end
            2'b10: 
            begin
                write_back_data = mem_wb_pc_out + 32'd4; // pc_plus4 recomputed, not latched separately
            end
            2'b11: 
            begin
                write_back_data = mem_wb_imm_out;
            end
            default: 
            begin 
                write_back_data = mem_wb_alu_result_out;
            end
        endcase
    end
    assign write_back_data_out = write_back_data;

    // Day 58: forwarding unit
    wire [1:0] forward_a, forward_b;
    forwarding_unit u_forwarding (
        .id_ex_rs1(id_ex_rs1_out),
        .id_ex_rs2(id_ex_rs2_out),
        .ex_mem_rd(ex_mem_rd_out),
        .ex_mem_reg_write(ex_mem_reg_write_out),
        .mem_wb_rd(mem_wb_rd_out),
        .mem_wb_reg_write(mem_wb_reg_write_out),
        .forward_a(forward_a),
        .forward_b(forward_b));

endmodule