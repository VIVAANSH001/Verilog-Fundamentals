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

## DAY 47: Store Testing

### what was tested
- all 3 store ops: sw, sh, sb, through core --> mem_interface -- > data_mem, verified via readback with day 46's already-proven lw (rather than trusting stores blind)
- sb tested at all 4 byte lanes individually, each against a FFFFFFFF baseline so any lane mismatch shows up clean
- sh tested at both valid alignments (lanes 0 and 1, lanes 2 and 3)
- deliberately non-uniform values (0xAB, 0x0300) instead of uniform FF patterns, specifically because day 36's mem_interface_tb/data_mem_tb used uniform 0xFFFFFFFF which unfortunately had masked a lane positioning bug
- finally checked if sw worked using a word abcd0123 which came out just fine

### bugs hit
- FOUND ONE. core.v's mem_wdata was `assign mem_wdata = rs2_data;`, raw and unshifted. data_mem.v's write logic assumes wdata is already positioned so the byte/half being stored sits in the same bit slice as the target byte_en lane, sb at lane1 and lane2/3 equivalents came back wrong (wrote 0x00 instead of the actual byte)
- root cause: byte_en (seam1) was fully built, but nothing positioned mem_wdata to match it, an incomplete seam, not a byte_en bug
- fixed by adding a mem_wdata_r mux in core.v, mirrors seam2 (load extend) but runs in the write direction: places rs2_data's low byte/half into the lane byte_en expects instead of leaving it raw
- Had to re run with full 4 lane + 2 alignment coverage after the fix, all 6 checks pass clean
- also had to re run days 44/45/46 tb's just to make sure the seam did not break any other logic all worked just fine

### what got built
- programs/test5.hex: 28 instructions, full sb lane coverage (0 to 3) + sh alignment coverage (0 to 1, 2 to 3) + sw checked with abcd0123
- tb/soc/soc_store_tb.v: 7 checks, readback-based verification using proven loads
- core.v: added mem_wdata_r positioning mux (real RTL fix, not just test infra)

## DAY 48: Branch Testing

### what was tested
- all 6 branch conditions: beq, bne, blt, bge, bltu, bgeu, each in both directions (taken and not taken) with 12 base cases
- this one's structurally different from every day before it cause branches dont write a register on their own, so checking a register after a branch tells you nothing about whether the branch actually fired. had to prove the PC itself went somewhere different
- used the sentinel marker technique: plant a `111` marker instruction on the fall-through path and a `222` marker at the taken target, with a `jal x0` right after the fall-through marker so it cant accidentally fall into the taken marker too
- edge case: same register comparison for beq/bne (rs1 and rs2 both literally x1, not just equal values in two different registers) this proves the comparator handles register aliasing.
- edge case: signed vs unsigned disagreement for blt/bltu and bge/bgeu with x1=0xFFFFFFFF, x2=3 used identically across blt/bltu and bge/bgeu pairs, and they come out opposite each time (blt taken/bltu not taken, bge not taken/bgeu taken), cause 0xFFFFFFFF reads as -1 signed but huge unsigned, same trick as day 44/45's slt/sltu and slti/sltiu edge cases just now proven through actual PC redirection instead of a register value

### results
- all 14 checks passed clean, first try, no bugs

### bugs hit
- none.

### what got built
- programs/test6.hex: 82 instructions, 14 branch test blocks (setup + branch + fall-through marker + skip jump + taken marker) covering all 6 conditions x2 directions + same reg edge case + signed/unsigned disagreement pairs
- tb/soc/soc_branch_tb.v: 14 checks, same hierarchical dot path style as prior days, checks sentinel registers x10 to x23

## DAY 49: Jumps, Upper Immediates, Fibonacci — Phase 3 Complete

### what was tested
- JAL: forward jump with exact link register check (rd = pc+4), backward jump with negative J-type immediate proven through a real jump
- JALR: full call/return round trip using jal ra + jalr x0,0(ra), nonzero-immediate addressing (rs1+imm), bit-0 clear on an odd rs1+imm sum, JALR's own link write with rd != x0, negative immediate
- LUI: basic upper immediate load, all ones upper bits, zero immediate thus proves the passthrough mux (result_src=11) bypasses the ALU cleanly with no leaked garbage
- AUIPC: basic pc + imm computation at a nonzero PC, plus an AUIPC+ADDI composition.
- Fibonacci integration program: iterative fib(10) using a real loop (addi setup, bge exit condition, add for the recurrence, addi moves, backward jal) making this the first time every instruction category from the whole phase had to cooperate in one program instead of being tested in isolation

### results
- jumps: 11/11 checks passed clean, first try
- upper immediates: 5/5 checks passed clean, first try
- fibonacci: 4/4 checks passed clean, first try (a=55, b=89, i=10, N=10)

### bugs hit
- none.

### what got built
- programs/test7.hex: 30 instructions, 7 jump test blocks (JAL forward/backward, JALR round trip/nonzero imm/bit-0 clear/rd!=x0/negative imm)
- tb/soc/soc_jump_tb.v: 11 checks
- programs/test8.hex: 6 instructions, LUI + AUIPC coverage
- tb/soc/soc_upper_tb.v: 5 checks
- programs/fib.hex: 10 static instructions (65 dynamic, 10 loop iterations), first real program run on the CPU
- tb/soc/soc_fib_tb.v: 4 checks

### phase 3 status
single cycle RV32I CPU fully instruction tested, category by category, days 44 to 49. every instruction type proven through the real core --> mem_interface --> data_mem path (or PC redirection path for control flow), not just unit-tested in isolation. one real RTL bug found and fixed along the way (day 47's mem_wdata_r positioning mux). closing out with fib(10)=55 computed correctly by an actual program is the proof this thing works as a whole, not just as a pile of individually passing checks.