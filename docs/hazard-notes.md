# Week 9: Hazard Notes

separate log from pipeline-notes.md cause phase 4's structural pipeline build (days 50 to 55) is done, this is a new chapter, actually handling the hazards that was stated to come later back on day 50. same core_pipelined.v file gets touched, but the nature of the work is different enough to earn its own log.

## DAY 57: Naive Integration + Demonstrating the Hazard

### what was covered
- first full fetch-to-writeback run of core_pipelined.v with a real program, no nop padding, on purpose
- point of today isnt to fix anything, its to infact prove the hazard is real and nail down exactly where it breaks and where it stops breaking, so day 58's forwarding fix has a clean before/after to compare against
- reused programs/encoder/gen_mem_wb_test.py for this instead of writing a new script, renamed it to encoder.py since its clearly a general purpose toolkit at this point, not a day 55 specific file. functions dont change, only the program list and output filename change per test

### the test program
- producer: add x3, x1, x2 (x3 should be 8)
- 4 consumers all reading x3, spaced at increasing gaps: gap=1 (addi x3+1), gap=2/3/4 (add x3+x3)
- had to add nops between the x1/x2 setup and the producer itself too, first run without them showed x3 come back as x, cause the producer was reading x1/x2 before their writes landed either. same hazard, just one level earlier than i meant to demo, easy miss

### bugs hit
- not a bug exactly but worth logging: first attempt had the producer immediately after x1/x2 setup with zero spacing, so the producer itself got corrupted (x3 = x) instead of just its consumers. fixed by nop padding the setup same as the consumers. good reminder that the hazard doesnt care whether its "the test" or "the thing being tested", any read thats too close to its write breaks the same way

### results
- x3 (producer) = 8, correct once properly spaced
- x4 gap=1, x5 gap=2, x6 gap=3 all came back as x, not stale garbage, straight up x. thats cause regfile is uninitialized until its actual first write in sim time, so a too-early read isnt reading "old data" here, its reading nothing at all
- x7 gap=4 = 16, correct, matches the "4 instructions clears the hazard" math from day 56
- x6 (gap=3) came back as x too, not borderline like i expected, so regfile's same-edge read/write behaves read-before-write (old/undefined value wins), not write-first. good to have that confirmed for real instead of assumed, matters later for exact forwarding cutoffs

### what got built
- programs/encoder/gen_mem_wb_test.py renamed to programs/encoder/encoder.py (git mv, not a plain rename, so history stays clean)
- programs/generated/hazard_test.hex
- tb/core/core_pipelined_hazard_tb.v
- docs/hazard-notes.md started as the week 9 log
- this exact hazard_test.hex is the one to rerun unmodified once forwarding exists day 58, x4/x5/x6 flipping from x to correct values is the proof forwarding works

## DAY 58: Forwarding Unit (EX --> MEM, MEM --> WB) + Regfile Write Through

### what was covered
- built the actual fix for the hazard day 57 demonstrated. two forwarding sources: EX/MEM (most recent) and MEM/WB (older), EX/MEM wins if both match since its the fresher value
- comparison is on register addresses, not values, thats exactly why id_ex_rs1_out/id_ex_rs2_out existed as unused fields since day 51, today they finally get read
- match condition needs 3 things true: producing instruction actually writes a register (reg_write set), rd != x0 (x0 is hardwired zero so a "match" there would be meaningless), and rd equals the EX stage's current rs1/rs2
- reused hazard_test.hex from day 57 completely unmodified on purpose, no new spacing, the whole point is proving the naive-timing failure gets fixed by hardware not by test spacing

### the fix
- new module: rtl/core/forwarding_unit.v, pure combinational, outputs a 2-bit select per operand (forward_a, forward_b): 00 = no forward, 01 = forward from EX/MEM, 10 = forward from MEM/WB
- core_pipelined.v EX stage: instantiated the forwarding unit, then muxed ex_alu_a/ex_alu_b to pick between id_ex_rs1_data_out/id_ex_rs2_data_out (stale regfile read) and the forwarded value (ex_mem_alu_result_out or write_back_data) based on the select
- branch_comp still reads id_ex_rs1_data_out/rs2_data_out directly, unforwarded, on purpose, thats a day 62 problem not a day 58 one

### bugs hit
- ran the hazard test after building just the forwarding unit: x4 (gap=1) and x5 (gap=2) flipped to correct as expected, but x6 (gap=3) stayed x. at first glance looked like forwarding didnt fully work, but it actually did exactly what it was supposed to, by the time x6 reaches EX the producer isnt in EX/MEM or MEM/WB anymore, it already retired straight to the regfile last cycle. nothing left in either pipeline register to forward from, so "no match" is the CORRECT output here
- real problem was one level down in regfile.v itself: x6's ID-stage read of x3 and the producer's WB-stage write of x3 land on the exact same clock edge. day 57 already proved this edge behaves read-before-write (confirmed for real, not assumed), so the async read samples the pre-edge value before the non blocking write lands, reads x cause x3 was never written before this
- this needed a same cycle write-through added inside regfile.v: if write_addr matches the read address on the same cycle as a write, forward write_data straight to the read output instead of reading the stale registers[] array. two lines added to each of read_data1/read_data2
- this fix technically wasnt on the plan for any specific day, decided to just close it today since the mental model was fresh and the change was small, rather than let it sit as an open gap into day 59

### results
- x4 gap=1 addi x3+1 = 9, correct, fixed by EX/MEM forward
- x5 gap=2 add x3+x3 = 16, correct, fixed by MEM/WB forward
- x6 gap=3 add x3+x3 = 16, correct, fixed by regfile write-through, NOT by forwarding
- x7 gap=4 add x3+x3 = 16, correct, untouched by both fixes, good sanity check neither change broke a normal already-settled read
- reran core_pipelined_hazard_tb.v (day 57's tb, unmodified) after both fixes to confirm no regression outside the new tb, same clean result

### what got built
- rtl/core/forwarding_unit.v
- core_pipelined.v: forwarding_unit instance + ex_alu_a/ex_alu_b muxes in EX stage
- regfile.v: same-cycle write-through added to read_data1/read_data2
- tb/core/regfile_writethrough_tb.v, isolates the write-through fix specifically, reuses hazard_test.hex same as day 57's tb
- day 57's hazard_test.hex and core_pipelined_hazard_tb.v reused completely unmodified across both fixes, exactly as planned