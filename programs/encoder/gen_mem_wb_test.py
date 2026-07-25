def i_type(imm, rs1, funct3, rd, opcode):
    imm &= 0xfff
    return (imm << 20)|(rs1 << 15)|(funct3 << 12)|(rd << 7)|opcode

def r_type(funct7, rs2, rs1, funct3, rd, opcode):
    return (funct7 << 25)|(rs2 << 20)|(rs1 << 15)|(funct3 << 12)|(rd << 7)|opcode

def s_type(imm, rs2, rs1, funct3, opcode):
    imm &= 0xfff
    imm11_5 = (imm >> 5) & 0x7f
    imm4_0 = imm & 0x1f
    return (imm11_5 << 25)|(rs2 << 20)|(rs1 << 15)|(funct3 << 12)|(imm4_0 << 7)|opcode

def j_type(imm, rd, opcode):
    imm20 = (imm >> 20) & 0x1
    imm10_1 = (imm >> 1) & 0x3ff
    imm11 = (imm >> 11) & 0x1
    imm19_12 = (imm >> 12) & 0xff
    return (imm20 << 31)|(imm19_12 << 12)|(imm11 << 20)|(imm10_1 << 21)|(rd << 7)|opcode


OP_ITYPE, OP_RTYPE, OP_LOAD, OP_STORE, OP_JAL = 0x13, 0x33, 0x03, 0x23, 0x6f

program = [
    i_type(100, 0, 0x0, 3, OP_ITYPE),   # addi x3, x0, 100
    i_type(0, 0, 0x0, 0, OP_ITYPE),     # nop (addi x0,x0,0)
    i_type(0, 0, 0x0, 0, OP_ITYPE),     # nop
    r_type(0, 2, 1, 0x0, 4, OP_RTYPE),  # add  x4, x1, x2
    s_type(0, 2, 3, 0x2, OP_STORE),     # sw   x2, 0(x3)
    i_type(0, 3, 0x2, 5, OP_LOAD),      # lw   x5, 0(x3)
    i_type(0, 0, 0x0, 6, OP_ITYPE),     # addi x6, x0, 0 (filler)
    s_type(4, 1, 3, 0x0, OP_STORE),     # sb   x1, 4(x3)
    i_type(4, 3, 0x0, 7, OP_LOAD),      # lb   x7, 4(x3)
    j_type(8, 8, OP_JAL),               # jal x8, 8
]

with open("programs/generated/mem_wb_test.hex", "w") as f:
    for instr in program:
        f.write(f"{instr:08x}\n")