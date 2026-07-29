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


OP_ITYPE, OP_RTYPE, OP_LOAD = 0x13, 0x33, 0x03

def b_type(imm, rs2, rs1, funct3, opcode):
    imm12 = (imm >> 12) & 0x1
    imm10_5 = (imm >> 5) & 0x3f
    imm4_1 = (imm >> 1) & 0xf
    imm11 = (imm >> 11) & 0x1
    return (imm12 << 31)|(imm10_5 << 25)|(rs2 << 20)|(rs1 << 15)|(funct3 << 12)|(imm4_1 << 8)|(imm11 << 7)|opcode

OP_BRANCH = 0x63

program = [
    i_type(0, 0, 0x0, 1, OP_ITYPE), # addi x1, x0, 0 (base addr)
    i_type(0, 1, 0x2, 5, OP_LOAD), # lw x5, 0(x1) = 20
    i_type(3, 0, 0x0, 2, OP_ITYPE), # addi x2, x0, 3
    r_type(0, 5, 2, 0x0, 7, OP_RTYPE), # add x7, x2, x5 stall, gap=0, load on rs2
    i_type(4, 1, 0x2, 8, OP_LOAD), # lw x8, 4(x1) = 7
    r_type(0, 8, 8, 0x0, 9, OP_RTYPE), # add x9, x8, x8  stall, load on both operands
    i_type(8, 1, 0x2, 10, OP_LOAD), # lw x10, 8(x1) = 24
    i_type(0, 10, 0x2, 11, OP_LOAD), # lw x11, 0(x10) stall, chained address dependency
    i_type(12, 1, 0x2, 12, OP_LOAD), # lw x12, 12(x1) = 99
    i_type(5, 0, 0x0, 13, OP_ITYPE), # addi x13, x0, 5 filler, no dependency
    r_type(0, 13, 12, 0x0, 14, OP_RTYPE), # add x14, x12, x13 no stall expected, gap=1
    i_type(42, 0, 0x0, 24, OP_ITYPE), # addi x24, x0, 42
    i_type(16, 1, 0x2, 15, OP_LOAD), # lw x15, 16(x1) = 42
    b_type(8, 24, 15, 0x0, OP_BRANCH), # beq x15, x24, 8 stall, load feeds branch rs1
    i_type(24, 1, 0x2, 20, OP_LOAD), # lw x20, 24(x1) = 77
    r_type(0, 2, 20, 0x0, 21, OP_RTYPE), # add x21, x20, x2 stall (hazard A)
    i_type(4, 1, 0x2, 22, OP_LOAD), # lw x22, 4(x1) = 7
    r_type(0, 2, 22, 0x0, 23, OP_RTYPE), # add x23, x22, x2 stall (hazard B)
]

with open("programs/generated/hazard_scenarios_test.hex", "w") as f:
    for instr in program:
        f.write(f"{instr:08x}\n")

print(f"wrote {len(program)} instructions to hazard_scenarios_test.hex")