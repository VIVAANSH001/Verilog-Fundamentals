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

program = [
    # Section A: continuous forward_a chain, gap=1 every cycle
    i_type(5, 0, 0x0, 1, OP_ITYPE), # addi x1, x0, 5
    i_type(3, 0, 0x0, 2, OP_ITYPE), # addi x2, x0, 3
    r_type(0, 2, 1, 0x0, 3, OP_RTYPE), # add  x3, x1, x2 = 8
    r_type(0, 2, 3, 0x0, 4, OP_RTYPE), # add  x4, x3, x2 = 11, forward_a EX/MEM
    r_type(0, 2, 4, 0x0, 5, OP_RTYPE), # add  x5, x4, x2 = 14, forward_a EX/MEM
    r_type(0, 2, 5, 0x0, 6, OP_RTYPE), # add  x6, x5, x2 = 17, forward_a EX/MEM, thus repeated forward_a

    # Section B: forward_a and forward_b simultaneously, different distances
    i_type(100, 0, 0x0, 10, OP_ITYPE), # addi x10, x0, 100
    i_type(200, 0, 0x0, 11, OP_ITYPE), # addi x11, x0, 200
    r_type(0, 11, 10, 0x0, 12, OP_RTYPE), # add  x12, x10, x11 = 300, forward_a MEM/WB, forward_b EX/MEM

    # Section C: EX/MEM vs MEM/WB tie-break, same destination reg
    i_type(50, 0, 0x0, 13, OP_ITYPE), # addi x13, x0, 50 (D)
    i_type(999, 0, 0x0, 13, OP_ITYPE), # addi x13, x0, 999 (E)
    r_type(0, 2, 13, 0x0, 14, OP_RTYPE), # add x14, x13, x2 = 1002 if EX/MEM wins (correct), 53 if bug

    # Section D: deliberate load-use failure, flagged for Day 60
    # Should work today in day 60 after load-use hazard detection
    i_type(0, 0, 0x0, 16, OP_ITYPE), # addi x16, x0, 0
    i_type(0, 16, 0x2, 17, OP_LOAD), # lw x17, 0(x16)
    r_type(0, 2, 17, 0x0, 18, OP_RTYPE), # add x18, x17, x2
]

with open("programs/generated/forwarding_chain_test.hex", "w") as f:
    for instr in program:
        f.write(f"{instr:08x}\n")

print(f"wrote {len(program)} instructions to forwarding_chain_test.hex")