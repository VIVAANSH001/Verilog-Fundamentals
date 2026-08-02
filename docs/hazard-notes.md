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

## DAY 59: Test Forwarding With Dependent Sequences

### what was covered
- day 58 built forwarding and fixed the regfile write-through bug, today's job is just to actually stress test it properly instead of trusting the single hazard_test.hex chain from day 57
- hazard_test.hex only ever proved forward_a, off one producer feeding four isolated consumers at different gaps. never proved: a real back to back chain where forward_a has to flip correctly every single cycle, forward_a and forward_b firing together in the same instruction, or the EX/MEM vs MEM/WB tie break actually picking the right one when both could match at once
- wrote one new hex, forwarding_chain_test.hex, covering all of that plus a deliberate load-use case, in 4 sections

### the test program
- section A: 3 back to back add's off a single chain (x3 --> x4 --> x5 --> x6), every single one is gap=1 off the one before it, forces forward_a to flip to a different register every cycle instead of just proving it once
- section B: two independent producers (x10, x11) feeding one consumer that needs both operands forwarded at the same time, from two different distances, x10 is gap=2 (MEM/WB) and x11 is gap=1 (EX/MEM), so forward_a and forward_b are both active on the same instruction from different sources
- section C: two writes to the same register back to back (x13 = 50, then x13 = 999) immediately followed by a consumer. this forces ex_mem_rd and mem_wb_rd to both match x13 at the same time, real tie between the two forwarding sources, not just theoretical
- section D: lw x17 immediately followed by add x18, x17, x2. deliberately not spaced, this is the confirmed load-use gap from day 58's writeup, put in on purpose to document the failure rather than dodge it

### bugs hit
- none in the RTL, everything passed on the first real run. only issue was that I forgot to repoint instr_mem.v's $readmemh path after generating the new hex.

### results
- section A: x4=11, x5=14, x6=17, all correct, forward_a held up across 3 consecutive gap=1 dependencies in a row
- section B: x12=300, correct, forward_a (MEM/WB) and forward_b (EX/MEM) both fired correctly in the same instruction from two different pipeline stages
- section C: x14=1002, correct. this is the important one, if the ex/mem-first priority in the forwarding unit was ever wrong or got flipped, this would've silently come back as 53 instead. real proof the tie break works, not just a formality
- section D: x18=3, exactly as predicted going in. real answer shouldve been 53 (50 loaded + 3), got 3 instead cause forwarding grabbed the address computed in EX (0) instead of the actual loaded value, which doesnt exist yet at that point since MEM hasnt run for that instruction. this is the confirmed, reproducible load-use hazard, not a new bug, just documented now instead of accidentally tripped over later. exactly what day 60 exists to fix

### what got built
- programs/encoder/encoder.py: added new program list for forwarding_chain_test.hex, same i_type/r_type helper functions reused unmodified
- programs/generated/forwarding_chain_test.hex
- tb/core/core_pipelined_forwarding_tb.v
- instr_mem.v repointed to forwarding_chain_test.hex via the readmemh path
- day 58's forwarding_unit.v and regfile.v write-through, both untouched, this was purely a testing day proving what already got built actually holds up under real dependent sequences

## DAY 60: Load-Use Hazard Detection + Stall Logic

### what was covered
- day 59 closed out with section D of forwarding_chain_test.hex confirmed broken on purpose, x18 = 3 instead of 53. today's job was actually fixing that, not just documenting it
- forwarding cant solve this one no matter how its wired. ex_mem_alu_result_out only ever holds what EX computed, and for a load that's just the address (rs1+imm), not the loaded data. the real value doesnt exist until MEM runs, which is one cycle after a gap=1 consumer would need it forwarded. no forwarding path fixes a value that doesnt exist yet, so the only real fix is stalling the consumer for one cycle so the load has time to reach MEM first
- this is a genuinely different comparison window than forwarding_unit.v. forwarding looks backward, EX's current operands vs EX/MEM and MEM/WB. hazard detection looks the opposite direction, the load thats currently in EX (id_ex_mem_read_out / id_ex_rd_out) vs the instruction thats currently in ID, still sitting as raw rs1/rs2 off if_id_instr_out, not even latched into ID/EX yet

### the fix
- new module: rtl/core/hazard_detect.v, pure combinational, single stall output. condition is id_ex_mem_read && (id_ex_rd != 0) && (id_ex_rd == if_id_rs1 || id_ex_rd == if_id_rs2). same rd != x0 guard as the forwarding unit, for the same reason, x0 matching is meaningless
- one stall signal drives three separate things, all in core_pipelined.v:
  - pc.v gets a new stall input, holds pc_current instead of advancing to pc_next
  - if_id_reg.v gets a new stall input, holds instr_out/pc_out instead of latching the next fetched instruction, so the consumer just sits there and gets re-decoded next cycle
  - id_ex_reg.v gets a new flush input, ORed into the same reset condition, so on the stall cycle the consumer gets squashed into a bubble (all-zero control signals) instead of actually entering EX with its now-stale operands
- freezing PC+IF/ID and bubbling ID/EX at the same time is the actual mechanism, PC/IF-ID hold the instruction in place for one cycle while ID/EX makes sure nothing wrong executes in the meantime

### bugs hit
- none in the RTL logic itself, first compile and first run came back correct
- non-RTL thing worth logging anyway: reran core_pipelined_forwarding_tb.v unmodified like the plan says to, but the old wait loop (25 cycles from day 59) wasnt enough headroom anymore, since the stall adds a bubble cycle the pipeline needs extra time to drain before section D's regfile reads are valid. bumped it to 30.
- section D's $display string was still written like the bug was expected, said "EXPECTED WRONG" even after the fix landed and the value came back correct. not an RTL bug but a stale comment/message that couldve been confusing to reread later, fixed the wording to match reality

### results
- x16 (base addr) = 0, correct
- x17 (lw result) = 50, correct
- x18 add x17+x2 = 53, correct, flipped from day 59's confirmed-wrong 3. this is the actual proof the stall works
- sections A, B, C (forward_a chaining, forward_a+forward_b simultaneous, EX/MEM vs MEM/WB tie break) all still came back correct on the same rerun, so the stall logic sitting on top of forwarding doesnt break anything forwarding was already handling

### what got built
- rtl/core/hazard_detect.v
- pc.v: stall input added
- if_id_reg.v: stall input added
- id_ex_reg.v: flush input added, ORed into the reset condition
- core_pipelined.v: hazard_detect instance wired in, stall/flush fanned out to pc.v, if_id_reg.v, id_ex_reg.v
- tb/core/core_pipelined_forwarding_tb.v: wait loop bumped 25 to 30, section D display text updated to match the fix
- day 61 per the plan is dedicated load-use scenario testing, this single lw-then-add case proved the mechanism works but hasnt been stress tested yet the way day 59 stress tested forwarding

## DAY 61: Test Load-Use Hazard Scenarios

### what was covered
- day 60 I built the stall fix and proved it works on exactly one case, lw immediately followed by an add using the loaded value. today's job was stress testing it the way day 59 stress tested forwarding, one lw-then-add case isnt the same as proving the mechanism generally
- wrote hazard_scenarios_test.hex covering 6 cases: load feeding rs2 instead of rs1, load feeding both rs1 and rs2 of the same consumer, a chained load-use (load result used as the address of the next load), a gap=1 filler that should not stall (forwarding should already handle it, this is the negative case), a load feeding a branch operand, and two independent load-use hazards back to back

### bugs hit
- none in the stall/hazard_detect logic itself, all 6 register value checks came back correct first run
- one thing flagged, not fixed: the branch scenario's diagnostic print showed rs1=x at the moment BEQ hit EX, even though branch_taken should've been 1 off a correct 42==42 compare. This is something I look to tackle on day 62.

### results
- x5=20, x7=23 correct (load on rs2, stalled correctly)
- x8=7, x9=14 correct (load on both operands, stalled correctly)
- x10=24, x11=77 correct (chained load-use, stalled correctly)
- x12=99, x14=104 correct (gap=1, correctly did not stall, forwarding handled it same as day 59)
- x20=77, x21=80, x22=7, x23=10 correct (two independent hazards back to back, no interference between them)
- branch scenario: register level result path untested today since branch redirect doesnt exist yet

### what got built
- programs/generated/hazard_scenarios_test.hex
- tb/core/core_pipelined_hazard_scenarios_tb.v
- day 60's hazard_detect.v, pc.v, if_id_reg.v, id_ex_reg.v all untouched, purely a testing day same as day 59 was for forwarding

## DAY 62: Control Hazard - Branch Flushing

### what was covered
- branch_comp has existed since day 39/52, its been computing branch_taken correctly this whole time, but ex_branch_taken_final was always a dead end wire, nothing downstream ever used it. taken branches had zero actual effect on control flow, pipeline just kept fetching sequentially regardless
- today's job was making a taken branch actually do something: redirect fetch to the real target, and kill the two instructions that get wrongly fetched off the sequential path while the branch is resolving (one sitting in ID, one currently being fetched in IF)
- this is a one cycle pulse problem, not a stall problem. branch resolves in EX, ex_branch_taken_final is high for exactly that one cycle, and both wrong-path instructions have to get squashed off the same pulse, simultaneously, not staggered across two cycles like stall/flush handles load-use

### the fix
- core_pipelined.v: pc_next mux extended, branch_target = id_ex_pc_out + id_ex_imm_out (both already sitting in id_ex_reg, no new plumbing needed there), muxed against the existing pc_current+4 default based on ex_branch_taken_final
- if_id_reg.v: needed a genuinely new port, flush, separate from stall. stall means hold current output, flush means zero it out. reused the same rst style zeroing, just OR'd flush into the same branch as rst
- id_ex_reg.v: no new port needed, its flush input already existed from day 60's stall logic. just changed the instantiation to flush(stall |ex_branch_taken_final) instead of flush(stall) alone, same bubble mechanism, now with two independent triggers feeding it
- both if_id_reg's new flush and id_ex_reg's extended flush get driven off the exact same ex_branch_taken_final wire, same edge, so the ID-stage instruction and the IF stage instruction both get killed in the same cycle instead of needing the flush to persist
- added branch_flush_out as a new observability port on core_pipelined, mirrors day 60's stall_out, same reasoning, needed a direct signal to confirm flush timing in the tb instead of inferring it from register values after the fact

### bugs hit
- none.

### results
- branch 1 (beq, taken): x10=0, x11=0 (both wrong path instructions correctly flushed, never executed), x12=99 (branch target correctly executed)
- branch 2 (bne, taken): x13=0, x14=0 (flushed), x15=88 (target executed), second branch type confirms it wasnt a beq specific fluke
- branch 3 (beq, not taken): x16=55, x17=66, normal sequential fallthrough, no flush fired. this one matters as much as the taken cases, proves flush doesnt fire unconditionally on every branch regardless of outcome
- branch_flush_out confirmed high for exactly one cycle on both taken branches, 0 everywhere else including the not taken branch, timing matches design intent exactly

### what got built
- rtl/core/if_id_reg.v: flush input added, same priority level as rst
- rtl/core/core_pipelined.v: branch_target wire + pc_next mux, if_id_reg's flush wired to ex_branch_taken_final, id_ex_reg's flush extended to stall | ex_branch_taken_final, branch_flush_out port added
- programs/encoder/encoder.py: program list replaced for branch_flush_test.hex, same i_type/r_type/b_type helpers reused unmodified
- programs/generated/branch_flush_test.hex
- tb/core/core_pipelined_branch_flush_tb.v
- still open: branch_comp itself is still unforwarded, same gap day 61 flagged. today just made sure that gap doesnt corrupt the flush test, didnt fix the gap itself. next real fix is either extending stall to 2 cycles specifically for load-into-branch, or giving branch_comp its own forward_a/forward_b paths same shape as the ALU's. not today's problem, but its the next thing sitting on top of this

## DAY 64: Test Branch Flushing Thoroughly

### what was covered
- day 62 built the flush mechanism and proved it on exactly 3 cases: beq taken, bne taken, beq not taken. today's job was stress testing it the way day 59 stress tested forwarding and day 61 stress tested the stall, one demo case isnt the same as proving the mechanism generally
- two things day 62 never touched: the other 4 branch types (blt, bge, bltu, bgeu), and a backward branch. every branch in day 62's test only ever jumped forward. real loops jump backward, so a redirect that only handles positive immediates correctly would still pass day 62 and be silently broken
- wrote branch_scenarios_test.hex, two sections: all 6 branch types off one shared operand pair, then a real 3 iteration backward-branching loop

### the test program
- section A: x1 = 0xFFFFFFFF (-1 signed, huge unsigned), x2 = 3, chosen specifically so signed and unsigned comparisons disagree on the exact same operands. blt taken (-1 < 3 signed) but bltu not taken (huge not < 3 unsigned) off the identical x1/x2 pair, same disagreement-pair trick from the original soc_branch_tb.v, just now proving the pipelined + flushed version handles it too, not just the single-cycle core
- section B: backward branch loop, x30 counts down from 3, bne branches back to the loop start while x30 != 0, x31 counts how many times the loop body actually ran, x28 is a marker only reachable by falling through the final not-taken exit
- kept the day 62 lesson in mind setting this up: 3 filler instructions between x1/x2 setup and the first branch, same reason as before, branch_comp still has no forwarding

### bugs hit
- real logic bug this time, not a test mistake: the loop initially had only the standard 3-instruction gap I'd been using out of habit between the counter decrement and the branch that reads it. worked out the actual minimum needed instead of just reusing 3 out of habit, turned out 2 fillers is the exact minimum for this specific gap (decrement enters EX at cycle N, commits at N+2, branch needs to read it during ID at cycle N+2 or later, so branch has to be at least 3 instruction slots after the decrement, meaning 2 fillers in between). used exactly 2 to prove I understood the timing precisely instead of just overpadding and hoping

### results
- BEQ (not taken): x10=111, x11=222, x12=99, correct, normal fallthrough, nothing flushed
- BNE (taken): x13=0, x14=0 (flushed), x15=99 (target), correct
- BLT (taken, signed): x16=0, x17=0 (flushed), x18=99 (target), correct, -1 < 3 evaluated correctly
- BGE (not taken, signed): x19=111, x20=222, x21=99, correct, -1>=3 correctly false
- BLTU (not taken, unsigned): x22=111, x23=222, x24=99, correct, huge<3 correctly false, this is the one that would've broken if signed/unsigned wires were ever crossed
- BGEU (taken, unsigned): x25=0, x26=0 (flushed), x27=99 (target), correct, huge>=3 correctly true, direct disagreement confirmed against BLT's result off the same x1/x2
- loop: x30=0 (counted all the way down), x31=3 (looped exactly 3 times, not 2 or 4), x28=77 (correct continuation after the final not-taken exit)
- branch_flush_out fired on exactly the 5 taken branches across the whole run (bne, blt, bgeu in section A, plus the two taken loop iterations in section B) and stayed 0 on every not-taken branch, timing matched design intent on every single one, no exceptions

### what got built
- programs/encoder/encoder.py: program list replaced for branch_scenarios_test.hex
- programs/generated/branch_scenarios_test.hex
- tb/core/core_pipelined_branch_scenarios_tb.v
- no RTL changed today, purely a testing day same as day 59 and day 61 were, day 62's if_id_reg.v/core_pipelined.v changes untouched and confirmed to hold up under full branch type + backward branch coverage
- still open, same as day 61/62: branch_comp itself still has no forwarding. today's test worked around it correctly (filler spacing everywhere operands are used) but the gap itself is unfixed. next concept session is queued to cover this properly, likely either a targeted 2-cycle stall for load/alu-into-branch or giving branch_comp its own forward_a/forward_b paths

## DAY 65: Test Jumps With Pipeline + Fibonacci Integration

### what was covered
- id_ex_jump_out existed since day 51 but nothing ever consumed it, jumps had zero effect on control flow, same dead wire situation branches were in pre day 62
- jal and jalr resolve at different stages so needed two different fixes, not one copy pasted off branch flush. jal is unconditional, no register read, resolves in ID off if_id_pc_out + imm. jalr needs rs1+imm then bit0 forced to 0, cant resolve before EX, same timing branch_comp already has
- flush shape follows resolution point not the other way round. jal only kills 1 bubble (IF), jalr kills 2 (IF+ID) same as branch

### the fix
- pc_next mux extended again, priority now branch, then jalr, then jal, then pc+4
- id_jal = jump && !alu_src, alu_src is only set for jalr so thats enough to tell them apart without a new control signal
- jalr_taken_final = id_ex_jump_out & id_ex_alu_src_out, target reuses ex_alu_result directly instead of building separate hardware, so jalr gets EX stage forwarding for free off the existing forward_a mux. branch_comp still doesnt get this, still open since day 61
- if_id_reg flush extended to branch | jalr | jal
- id_ex_reg flush extended to stall | branch | jalr only, jal deliberately left out, the jal instruction itself is sitting in ID when id_jal fires and has to latch through normally not get squashed
- added jalr_flush_out and jal_flush_out as new observability ports same reasoning as day 62's branch_flush_out

### bugs hit
- not an RTL bug, a test program one. tried running the old fib.hex (day 49, single cycle) unmodified on the pipeline as the integration test and it just didnt work, x1/x2/x4 stuck at their init values, loop never ran
- turned out to be the exact branch_comp gap flagged open since day 61/62/64, just actually triggered for real this time instead of theoretical. addi x5,x0,10 immediately followed by bge x4,x5 is gap 0, branch read x5 before its writeback landed, saw 0 instead of 10, 0>=0 fired true and exited the loop on iteration 0
- fix is the same call as day 62/64, pad the program dont touch branch_comp. reordered setup so x4/x5 get produced first with enough gap, and added 3 fillers before the backward jump so the re-check next iteration also clears gap=3 (day 58's write-through math again)
- new file fib_pipeline.hex, original fib.hex left untouched, still correct for the single cycle core

### results
- jump test, all 3 sections correct first real run once it compiled clean:
  - forward jal + link: x10=8, x20=0 (flushed), x21=99
  - jalr call/return + forwarded rs1 + bit0 clear all in one shot, gap=0 into the jalr on purpose: x1=20, x29=222, x7=41, x8=36, x31=222
  - backward jal: x24=50, x27=111 (only reachable via the backward jump), x28=42, settled into steady state by cycle 22
- fib integration, repointed at fib_pipeline.hex: x1=55, x2=89, x4=10, x5=10, all correct. first real end to end proof the pipeline works as a whole cpu, not just isolated hazard mechanisms tested one at a time

### what got built
- core_pipelined.v: jal/jalr target wires, pc_next mux extended, if_id_reg and id_ex_reg flush extended, jalr_flush_out/jal_flush_out ports added
- programs/handcoded/jump_pipeline_test.hex
- tb/core/core_pipelined_jump_tb.v
- programs/handcoded/fib_pipeline.hex
- tb/core/core_pipelined_fib_tb.v
- day 49's fib.hex untouched, kept as the single cycle reference
- still open, same as day 61/62/64: branch_comp still has no forwarding. jalr's fix shows the pattern of reusing the forwarded ALU operand works, but it doesnt port over directly since branch_comp doesnt go through the ALU at all
- new flag, not fixed: hazard_detect reads if_id_rs1/rs2 off a fixed slice regardless of instruction format. for jal those bits are actually immediate bits not registers, so a load 2 instructions before a jal could in theory false trigger a stall. todays tests had zero loads in them so this never actually got hit, same bucket as day 64's x40 wraps to x8 bug