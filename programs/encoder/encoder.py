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
    # set up ALL branch operands up front, with a comfortable gap before they're used
    i_type(5, 0, 0x0, 1, OP_ITYPE), # 0: addi x1, x0, 5
    i_type(5, 0, 0x0, 2, OP_ITYPE), # 4: addi x2, x0, 5
    i_type(7, 0, 0x0, 3, OP_ITYPE), # 8: addi x3, x0, 7
    i_type(3, 0, 0x0, 4, OP_ITYPE), # 12: addi x4, x0, 3
    i_type(5, 0, 0x0, 6, OP_ITYPE), # 16: addi x6, x0, 5
    i_type(9, 0, 0x0, 7, OP_ITYPE), # 20: addi x7, x0, 9
    i_type(0, 0, 0x0, 0, OP_ITYPE), # 24: addi x0,x0,0 (filler)
    i_type(0, 0, 0x0, 0, OP_ITYPE), # 28: addi x0,x0,0 (filler)
    i_type(0, 0, 0x0, 0, OP_ITYPE), # 32: addi x0,x0,0 (filler)
    b_type(12, 2, 1, 0x0, OP_BRANCH), # 36: beq x1, x2, 12 --> taken, target=48
    i_type(111, 0, 0x0, 10, OP_ITYPE), # 40: addi x10, x0, 111 wrong path, must be flushed
    i_type(222, 0, 0x0, 11, OP_ITYPE), # 44: addi x11, x0, 222 wrong path, must be flushed
    i_type(99, 0, 0x0, 12, OP_ITYPE), # 48: addi x12, x0, 99 branch target, must execute
    b_type(12, 4, 3, 0x1, OP_BRANCH), # 52: bne x3, x4, 12 --> taken (7!=3), target=64
    i_type(111, 0, 0x0, 13, OP_ITYPE), # 56: addi x13, x0, 111 wrong path, must be flushed
    i_type(222, 0, 0x0, 14, OP_ITYPE), # 60: addi x14, x0, 222 wrong path, must be flushed
    i_type(88, 0, 0x0, 15, OP_ITYPE), # 64: addi x15, x0, 88 branch target, must execute
    b_type(12, 7, 6, 0x0, OP_BRANCH), # 68: beq x6, x7, 12 --> not taken (5!=9), falls through
    i_type(55, 0, 0x0, 16, OP_ITYPE), # 72: addi x16, x0, 55 normal fallthrough, must execute
    i_type(66, 0, 0x0, 17, OP_ITYPE), # 76: addi x17, x0, 66 normal fallthrough, must execute
]

with open("programs/generated/branch_flush_test.hex", "w") as f:
    for instr in program:
        f.write(f"{instr:08x}\n")

print(f"wrote {len(program)} instructions to branch_flush_test.hex")