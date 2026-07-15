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