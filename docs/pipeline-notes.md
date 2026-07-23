# Phase 4: Pipeline Notes

Converting the single cycle RV32I core into a 5 stage pipeline (IF/ID/EX/MEM/WB).

# Phase 4: Pipeline Notes

converting the single cycle rv32i core into a 5 stage pipeline (if/id/ex/mem/wb). separate log from testing-notes.md cause phase 3 was proving instructions work one by one, this is a structural rebuild so it needs its own space. mem_interface.v stays exactly as is through all of this, thats the whole point of building that seam back in phase 3, MEM stage just drives it the same way the single cycle core did.

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

## DAY 51: Pipeline Registers (IF/ID, ID/EX, EX/MEM, MEM/WB)

### what was covered
- built the 4 pipeline register modules sketched in day 50
- figured out what signals each one needs to carry, not just for the next stage but for whatever LATER stage still needs it (pc survives to EX for AUIPC, imm survives to WB for LUI)
- kept them standalone for now, not wired into core.v yet, thats days 52 to 55

### if_id_reg.v
- latches instr + pc_current out of IF so ID can decode while IF fetches next

### id_ex_reg.v
- carries rs1_data/rs2_data/imm + rd/rs1/rs2 (addresses too, not just values, EX doesnt need them but week 9 forwarding will need to know WHICH register a value came from)
- carries every control_unit.v signal since control only runs once in ID but EX/MEM/WB downstream each need a subset

### ex_mem_reg.v
- carries alu_result (doubles as mem addr), rs2_data (raw store data, mem_interface.v still does lane positioning), pc/imm/rd for WB, plus reg_write/mem_read/result_src/mem_size/mem_unsigned
- did NOT carry branch_taken, pc redirect is a feedback path handled at top level wiring later, not something that flows forward

### mem_wb_reg.v
- carries alu_result, load_data (already extended), pc, imm, rd, reg_write, result_src, basically just the writeback mux's inputs held one more cycle

### testing
- one testbench (pipeline_regs_tb.v), proved if_id_reg: reset clears to 0, two back to back latches grabbed input values correctly on each edge
- didnt duplicate for the other 3, same always block pattern just more fields, if_id_reg passing proves the pattern works
- compiled clean first try, all checks passed as predicted

### bugs hit
- none

### what got built
- rtl/core/if_id_reg.v, id_ex_reg.v, ex_mem_reg.v, mem_wb_reg.v
- tb/core/pipeline_regs_tb.v
- no core.v/soc.v changes, wiring starts day 52