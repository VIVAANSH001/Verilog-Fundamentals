def _check_reg(r, label="register"):
    assert 0 <= r <= 31, f"{label} out of range: x{r} (valid: x0-x31)"

def i_type(imm, rs1, funct3, rd, opcode):
    _check_reg(rs1, "rs1"); _check_reg(rd, "rd")
    imm &= 0xfff
    return (imm << 20)|(rs1 << 15)|(funct3 << 12)|(rd << 7)|opcode

def r_type(funct7, rs2, rs1, funct3, rd, opcode):
    _check_reg(rs2, "rs2"); _check_reg(rs1, "rs1"); _check_reg(rd, "rd")
    return (funct7 << 25)|(rs2 << 20)|(rs1 << 15)|(funct3 << 12)|(rd << 7)|opcode

def s_type(imm, rs2, rs1, funct3, opcode):
    _check_reg(rs2, "rs2"); _check_reg(rs1, "rs1")
    imm &= 0xfff
    imm11_5 = (imm >> 5) & 0x7f
    imm4_0 = imm & 0x1f
    return (imm11_5 << 25)|(rs2 << 20)|(rs1 << 15)|(funct3 << 12)|(imm4_0 << 7)|opcode

def j_type(imm, rd, opcode):
    _check_reg(rd, "rd")
    imm20 = (imm >> 20) & 0x1
    imm10_1 = (imm >> 1) & 0x3ff
    imm11 = (imm >> 11) & 0x1
    imm19_12 = (imm >> 12) & 0xff
    return (imm20 << 31)|(imm19_12 << 12)|(imm11 << 20)|(imm10_1 << 21)|(rd << 7)|opcode


OP_ITYPE, OP_RTYPE, OP_LOAD = 0x13, 0x33, 0x03

def b_type(imm, rs2, rs1, funct3, opcode):
    _check_reg(rs2, "rs2"); _check_reg(rs1, "rs1")
    imm12 = (imm >> 12) & 0x1
    imm10_5 = (imm >> 5) & 0x3f
    imm4_1 = (imm >> 1) & 0xf
    imm11 = (imm >> 11) & 0x1
    return (imm12 << 31)|(imm10_5 << 25)|(rs2 << 20)|(rs1 << 15)|(funct3 << 12)|(imm4_1 << 8)|(imm11 << 7)|opcode

OP_BRANCH = 0x63

if __name__ == "__main__":
    program = [
        # Section A: all 6 branch types, same operand pair, taken + not taken
        # x1 = 0xFFFFFFFF (-1 signed, huge unsigned), x2 = 3
        # deliberately picked so signed vs unsigned comparisons disagree on the same operands
        i_type(-1, 0, 0x0, 1, OP_ITYPE), # 0: addi x1, x0, -1
        i_type(3, 0, 0x0, 2, OP_ITYPE), # 4: addi x2, x0, 3
        i_type(0, 0, 0x0, 0, OP_ITYPE), # 8: addi x0,x0,0 (filler)
        i_type(0, 0, 0x0, 0, OP_ITYPE), # 12: addi x0,x0,0 (filler)
        i_type(0, 0, 0x0, 0, OP_ITYPE), # 16: addi x0,x0,0 (filler)

        b_type(12, 2, 1, 0x0, OP_BRANCH), # 20: beq x1,x2,12 --> not taken (-1 != 3)
        i_type(111, 0, 0x0, 10, OP_ITYPE), # 24: addi x10,x0,111 (executes, not flushed)
        i_type(222, 0, 0x0, 11, OP_ITYPE), # 28: addi x11,x0,222 (executes)
        i_type(99, 0, 0x0, 12, OP_ITYPE), # 32: addi x12,x0,99 (executes either way)

        b_type(12, 2, 1, 0x1, OP_BRANCH), # 36: bne x1,x2,12 --> taken, target=48
        i_type(111, 0, 0x0, 13, OP_ITYPE), # 40: addi x13,x0,111 wrong path, flushed
        i_type(222, 0, 0x0, 14, OP_ITYPE), # 44: addi x14,x0,222 wrong path, flushed
        i_type(99, 0, 0x0, 15, OP_ITYPE), # 48: addi x15,x0,99 target, executes

        b_type(12, 2, 1, 0x4, OP_BRANCH), # 52: blt x1,x2,12 (signed) --> taken (-1<3), target=64
        i_type(111, 0, 0x0, 16, OP_ITYPE), # 56: addi x16,x0,111 wrong path, flushed
        i_type(222, 0, 0x0, 17, OP_ITYPE), # 60: addi x17,x0,222 wrong path, flushed
        i_type(99, 0, 0x0, 18, OP_ITYPE), # 64: addi x18,x0,99 target, executes

        b_type(12, 2, 1, 0x5, OP_BRANCH), # 68: bge x1,x2,12 (signed) --> not taken (-1>=3 false)
        i_type(111, 0, 0x0, 19, OP_ITYPE), # 72: addi x19,x0,111 (executes, not flushed)
        i_type(222, 0, 0x0, 20, OP_ITYPE), # 76: addi x20,x0,222 (executes)
        i_type(99, 0, 0x0, 21, OP_ITYPE), # 80: addi x21,x0,99 (executes)

        b_type(12, 2, 1, 0x6, OP_BRANCH), # 84: bltu x1,x2,12 (unsigned) --> not taken (huge<3 false)
        i_type(111, 0, 0x0, 22, OP_ITYPE), # 88: addi x22,x0,111 (executes, not flushed)
        i_type(222, 0, 0x0, 23, OP_ITYPE), # 92: addi x23,x0,222 (executes)
        i_type(99, 0, 0x0, 24, OP_ITYPE), # 96: addi x24,x0,99 (executes)

        b_type(12, 2, 1, 0x7, OP_BRANCH), # 100: bgeu x1,x2,12 (unsigned) --> taken (huge>=3), target=112
        i_type(111, 0, 0x0, 25, OP_ITYPE), # 104: addi x25,x0,111 wrong path, flushed
        i_type(222, 0, 0x0, 26, OP_ITYPE), # 108: addi x26,x0,222 wrong path, flushed
        i_type(99, 0, 0x0, 27, OP_ITYPE), # 112: addi x27,x0,99 target, executes

        # Section B: backward branch, real loop, 3 iterations
        # tests negative immediate redirect + repeated taken flush + a clean
        # not taken exit that falls through to the right place afterward
        i_type(3, 0, 0x0, 30, OP_ITYPE), # 116: addi x30,x0,3 loop counter
        i_type(0, 0, 0x0, 31, OP_ITYPE), # 120: addi x31,x0,0 iteration marker
        i_type(1, 31, 0x0, 31, OP_ITYPE), # 124: LOOP: addi x31,x31,1
        i_type(-1, 30, 0x0, 30, OP_ITYPE), # 128: addi x30,x30,-1 (producer for x30)
        i_type(0, 0, 0x0, 0, OP_ITYPE), # 132: addi x0,x0,0 (filler1)
        i_type(0, 0, 0x0, 0, OP_ITYPE), # 136: addi x0,x0,0 (filler2)
        b_type(-16, 0, 30, 0x1, OP_BRANCH), # 140: bne x30,x0,-16 --> loop back to 124 while x30!=0
        i_type(77, 0, 0x0, 28, OP_ITYPE), # 144: addi x28,x0,77 post loop marker, exit target
    ]

    with open("programs/generated/branch_scenarios_test.hex", "w") as f:
        for instr in program:
            f.write(f"{instr:08x}\n")

    print(f"wrote {len(program)} instructions to branch_scenarios_test.hex")