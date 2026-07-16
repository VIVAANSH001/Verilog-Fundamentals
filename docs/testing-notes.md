# Phase 3 Testing Notes Week 7

Verification pass on the single-cycle CPU, going from one instruction category to another
Format: what was tested / results / bugs hit(if any) / what got built.

## DAY 44: R-type Testing

### what was tested
- all 10 R-type ops: add, sub, and, or, xor, sll, srl, sra, slt, sltu
- edge case: slt vs sltu disagreement (x10 = -1 / 0xFFFFFFFF, x11 = 1, same bit pattern reads opposite signed vs unsigned)
- edge case: sra sign extension (shifting -1 right stays -1, proves $signed() intact through alu_control -- > alu)
- edge case: sub producing a genuine zero result at the register level (not the alu_zero flag, which stays unconnected per day 40's decision, cant be probed meaningfully)

### results
- all 11 checks passed clean, first try, no bugs

### bugs hit
- none. only hiccup was mine, ran the old day 41 soc_tb.v by accident instead of the new soc_r_type_tb.v no rtl issue haha.

### what got built
- programs/test2.hex: 15 instructions, r-type coverage + edge cases
- tb/soc/soc_r_type_tb.v: 11 checks, hierarchical dot-path reads same style as soc_tb.v, keeps day 41's soc_tb.v untouched as the permanent single-instruction test
for nostalgia purposes

## DAY 45: I-type Arithmetic Testing

### what was tested
- all 9 I-type arithmetic ops: addi, andi, ori, xori, slti, sltiu, slli, srli, srai
- edge case: ADDI vs ADD disambiguation (x11 = addi with imm = -3, so imm[11:5] is all 1s --> same bit pattern as SUB's funct7[5] = 1, this is the actual day 38 bug case finally proven through a real instruction not just alu_control_tb.v)
- edge case: slti vs sltiu disagreement (x2 = -1 / 0xFFFFFFFF, same bit pattern reads opposite signed vs unsigned, immediate-driven version of day 44's slt/sltu edge case)
- edge case: srai sign extension (shifting -1 right stays -1, same as day 44's sra but shift amount comes from the instruction not a register --> different path through alu_control)
- edge case: andi producing a genuine zero result at the register level

### results
- all 11 checks passed clean, first try, no bugs

### bugs hit
- none.

### what got built
- programs/test3.hex: 14 instructions, I-type arithmetic coverage + edge cases
- tb/soc/soc_i_type_tb.v: 11 checks, same hierarchical dot-path style as soc_r_type_tb.v

## DAY 46: Load Testing

### what was tested
- all 5 load ops: lw, lh, lb, lhu, lbu, through the actual core--> mem_interface --> data_mem path 
- preloaded two known words directly into ram via testbench (word 0 = 0xAABBCCDD, word 4 = 0x12345678) instead of relying on sw, since stores arent tested yet
- edge case: word 0 has mixed sign bits across every byte/half --> lb/lbu and lh/lhu genuinely diverge everywhere (x2/x3, x5/x6, x8/x9)
- edge case: word 4 has every byte's sign bit clear --> lb and lbu (x10/x11) come out identical, proves the day 37 insight that signed vs unsigned only diverges when the top bit is 1
- lane selection across all 4 byte offsets (0,1,2,3) and both half-word offsets (0,2)

### results
- all 12 checks passed clean, first try, no bugs

### bugs hit
- none.

### what got built
- programs/test4.hex: 12 instructions, pure loads off x0 base, no setup instructions needed since memory preloaded directly
- tb/soc/soc_load_tb.v: 12 checks, preloads ram hierarchically same technique as data_mem_tb.v, then reads through the full core