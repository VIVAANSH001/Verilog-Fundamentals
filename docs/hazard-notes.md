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