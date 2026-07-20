# Phase 4: Pipeline Notes

Converting the single cycle RV32I core into a 5 stage pipeline (IF/ID/EX/MEM/WB).

# Phase 4: Pipeline Notes

converting the single cycle rv32i core into a 5 stage pipeline (if/id/ex/mem/wb). separate log from testing-notes.md cause phase 3 was proving instructions work one by one, this is a structural rebuild so it needs its own space. mem_interface.v stays exactly as is through all of this, thats the whole point of building that seam back in phase 3, MEM stage just drives it the same way the single cycle core did.

---

## DAY 50: Pipeline Theory + Datapath Sketch

### what was covered
- why pipeline at all in the first place
- the 5 stages and how they map onto stuff i already built
- whats actually changing structurally to make it pipelined
- a heads up on hazards, not solving them today just knowing theyre coming

### why bother pipelining
- single cycle works but its wasteful, one instruction = one full clock cycle, and that cycle has to be as long as the SLOWEST possible instruction (lw, since it touches every single stage). even something as simple as add doesnt need the mem stage at all but still has to sit through that same long cycle doing nothing during that time.
- pipelining fixes this by chopping the datapath into 5 stages and letting 5 different instructions sit in the 5 stages AT THE SAME TIME, one clock behind each other. instr 1 in wb while instr 2 is in mem while instr 3 is in ex etc. basically like an assembly line, one worker doesnt sit around waiting for the whole car before starting the next one.

### the 5 stages arent new hardware
- this is the part that clicked for me, im not building new modules im just time slicing the ones i already have:
- IF (fetch) --> pc.v + instr_mem.v
- ID (decode) --> instr_decoder.v + regfile.v (read side) + immgen.v + control_unit.v
- EX (execute) --> alu.v + alu_control.v + branch_comp.v
- MEM (memory) --> mem_interface.v, staying untouched, literally the reason i built that seam in phase 3 instead of hardwiring ram into the core
- WB (writeback) --> regfile.v (write side)

## whats structurally different
- right now all 5 stages happen combinationally in one clock edge, everything just flows straight through.
- to pipeline it i gotta drop a register IN BETWEEN each stage: if/id reg, id/ex reg, ex/mem reg, mem/wb reg. each one latches that stages output on the clock edge and hands it to the next stage, while that same stage immediately starts working on the next instruction behind it.
- so instead of 1 instruction hogging the whole datapath serially, 5 instructions are literally sitting in 5 different stages at once, each one clock cycle behind the one in front.

## whats coming later
- since 5 instructions are in flight at once, an instr in ex might need a result thats still sitting in mem or wb from an earlier instr that hasnt written back yet --> data hazard.
- branch doesnt resolve till ex, but by then if and id already blindly fetched/decoded the next 2 instrs. if the branch was taken those are garbage, gotta flush --> control hazard.
- both week 9 stuff, today was just getting the stage breakdown and why the pipeline regs go where they go straight in my head first.

### what got built
- started docs/pipeline-notes.md as the phase 4 log
- no rtl changes yet, purely mental model day