// core.v
// Day 39: top-level core. Instantiates every module built Days 29-38 and
// wires them together, plus the glue logic that didn't exist anywhere yet:
// byte_en gen, load extend, AUIPC A-mux, branch/jump adder, pc_next mux,
// JALR bit-0 clear. instr_mem and the memory interface/decoder live in
// soc.v, not here as the core only exposes a clean memory port + fetch port.

module core (input wire clk,input wire rst,input wire [31:0] instruction,input wire [31:0] mem_rdata,output wire [31:0] pc_current,output wire [31:0] mem_addr,output wire [31:0] mem_wdata,output wire [3:0] mem_byte_en,output wire mem_write,output wire mem_read);

    // FETCH
    reg [31:0] pc_next;
    pc u_pc (.clk(clk),.rst(rst),.pc_next(pc_next),.pc_current(pc_current));

    // DECODE
    wire [6:0] opcode;
    wire [4:0] rd, rs1, rs2;
    wire [2:0] funct3;
    wire [6:0] funct7;
    instr_decoder u_decoder (.instr(instruction),.opcode(opcode),.rd(rd),.rs1(rs1),.rs2(rs2),.funct3(funct3),.funct7(funct7));

    wire [31:0] imm;
    immgen u_immgen (.instr(instruction),.imm(imm));

    wire reg_write, branch, jump, alu_src, mem_unsigned, alu_a_pc;
    wire [1:0] result_src, alu_op, mem_size;
    control_unit u_control(.opcode(opcode),.funct3(funct3),.reg_write(reg_write),.mem_read(mem_read),.mem_write(mem_write),.branch(branch),.jump(jump),.alu_src(alu_src),.result_src(result_src),.alu_op(alu_op),.mem_size(mem_size),.mem_unsigned(mem_unsigned),.alu_a_pc(alu_a_pc));

    // REGISTER FILE
    wire [31:0] rs1_data, rs2_data;
    reg  [31:0] write_back_data;
    regfile u_regfile (.clk(clk),.we(reg_write),.write_addr(rd),.write_data(write_back_data),.read_addr1(rs1),.read_addr2(rs2),.read_data1(rs1_data),.read_data2(rs2_data));

    // ALU
    wire [3:0] alu_ctrl;
    alu_control u_alu_control(.alu_op(alu_op),.funct3(funct3),.funct7(funct7),.alu_src(alu_src),.alu_ctrl(alu_ctrl));

    // seam 3: AUIPC needs PC on ALU input A instead of rs1
    wire [31:0] alu_a = alu_a_pc ? pc_current : rs1_data;
    wire [31:0] alu_b = alu_src ? imm : rs2_data; // for deciding input b as rs2 or imm

    wire [31:0] alu_result;
    wire alu_zero;
    alu_32 u_alu (.a(alu_a),.b(alu_b),.alu_ctrl(alu_ctrl),.result(alu_result),.zero(alu_zero));

    // Branch Compare
    wire branch_taken;
    branch_comp u_branch_comp (.rs1_data(rs1_data),.rs2_data(rs2_data),.funct3(funct3),.branch_taken(branch_taken));

    // seam 4: branch/jump target adder (shared for jump and branch as both are just PC+imm,
    // immgen already picked the right imm format for whichever opcode is active)
    wire [31:0] pc_plus4 = pc_current + 32'd4;
    wire [31:0] pc_pc_imm = pc_current + imm;

    // seam 6: JALR reuses the ALU's rs1+imm (alu_src=1, alu_op=00 already
    // does this for JALR) just forces bit 0 to zero
    wire [31:0] jalr_target = {alu_result[31:1], 1'b0};

    wire branch_taken_final = branch & branch_taken; // checking if the branch is confirmed

    // seam 5: pc_next priority mux
    always @(*)
    begin
        if (branch_taken_final) // For any branch
        begin
            pc_next = pc_pc_imm;
        end
        else if (jump && alu_src) // JALR: alu_src=1 only set for JALR among jumps
        begin
            pc_next = jalr_target;
        end
        else if (jump) // JAL
        begin
            pc_next = pc_pc_imm;
        end
        else
        begin
            pc_next = pc_plus4; // default case of pc=pc+4
        end
    end

    // Memory address / data out
    assign mem_addr = alu_result;   // LOAD/STORE address = rs1+imm, computed by ALU
    // assign mem_wdata = rs2_data; --> buggy code does not align the word for storing
    
    // seam 1b: store data positioning (similar to seam 1's byte_en generator).
    reg [31:0] mem_wdata_r;
    always @(*)
    begin
        case (mem_size)
            2'b00: // byte
                case (alu_result[1:0])
                    2'b00: 
                    begin
                        mem_wdata_r = {24'b0, rs2_data[7:0]};
                    end
                    2'b01: 
                    begin
                        mem_wdata_r = {16'b0, rs2_data[7:0], 8'b0};
                    end
                    2'b10: 
                    begin
                        mem_wdata_r = {8'b0, rs2_data[7:0], 16'b0};
                    end
                    2'b11: 
                    begin
                        mem_wdata_r = {rs2_data[7:0], 24'b0};
                    end
                endcase
            2'b01: // half
            begin
                mem_wdata_r = alu_result[1] ? {rs2_data[15:0], 16'b0} : {16'b0, rs2_data[15:0]};
            end
            default: // word
            begin
                mem_wdata_r = rs2_data;
            end
        endcase
    end
    assign mem_wdata = mem_wdata_r;


    // seam 1: byte_en generator
    reg [3:0] byte_en_r;
    always @(*)
    begin
        case (mem_size)
            2'b00: // byte
                case (alu_result[1:0])
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
                byte_en_r = alu_result[1] ? 4'b1100 : 4'b0011;
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

    // seam 2: load sign/zero extend (two steps: lane-select first, then extend)
    wire [7:0]  load_byte = (alu_result[1:0]==2'b00) ? mem_rdata[7:0] : (alu_result[1:0]==2'b01) ? mem_rdata[15:8] : (alu_result[1:0]==2'b10) ? mem_rdata[23:16]: mem_rdata[31:24];
    wire [15:0] load_half = alu_result[1] ? mem_rdata[31:16] : mem_rdata[15:0];
    
    reg [31:0] load_data;
    always @(*)
    begin
        case (mem_size)
            2'b00: 
            begin
                load_data = mem_unsigned ? {24'b0, load_byte} : {{24{load_byte[7]}}, load_byte};
            end
            2'b01: 
            begin
                load_data = mem_unsigned ? {16'b0, load_half} : {{16{load_half[15]}}, load_half};
            end
            2'b10: 
            begin
                load_data = mem_rdata;
            end
            default: 
            begin
                load_data = mem_rdata;
            end
        endcase
    end

    // Writeback mux
    always @(*)
    begin
        case (result_src)
            2'b00:
            begin
                write_back_data = alu_result;
            end
            2'b01: 
            begin
                write_back_data = load_data;
            end
            2'b10:
            begin
                write_back_data = pc_plus4;
            end
            2'b11:
            begin
                write_back_data = imm;
            end
            default:
            begin
                write_back_data = alu_result;
            end
        endcase
    end

endmodule