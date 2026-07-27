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


OP_ITYPE, OP_RTYPE = 0x13, 0x33

program = [
    i_type(5, 0, 0x0, 1, OP_ITYPE),     # addi x1, x0, 5
    i_type(3, 0, 0x0, 2, OP_ITYPE),     # addi x2, x0, 3
    i_type(0, 0, 0x0, 0, OP_ITYPE),     # nop
    i_type(0, 0, 0x0, 0, OP_ITYPE),     # nop
    i_type(0, 0, 0x0, 0, OP_ITYPE),     # nop
    r_type(0, 2, 1, 0x0, 3, OP_RTYPE),  # add x3, x1, x2 producer, x3=8, now safely spaced
    i_type(1, 3, 0x0, 4, OP_ITYPE),     # addi x4, x3, 1 gap=1, expect FAIL (real answer 9)
    r_type(0, 3, 3, 0x0, 5, OP_RTYPE),  # add x5, x3, x3 gap=2, expect FAIL (real answer 16)
    r_type(0, 3, 3, 0x0, 6, OP_RTYPE),  # add x6, x3, x3 gap=3, borderline (real answer 16)
    r_type(0, 3, 3, 0x0, 7, OP_RTYPE),]  # add x7, x3, x3 gap=4, expect PASS (real answer 16)


with open("programs/generated/hazard_test.hex", "w") as f:
    for instr in program:
        f.write(f"{instr:08x}\n")

print(f"wrote {len(program)} instructions to hazard_test.hex")