# Phase 3 Architecture Notes

## DAY 29: Program Counter Module

### Why PC has to be a register
- if PC was just a wire, PC+4's output would feed straight back into PC's own input, no clock to break the loop. itd just be unstable, never settling.
- register breaks this, holds one stable value all cycle, updates once at the edge. general rule: anything computed from a signals own current value that becomes that same signals next value needs a register. gonna see this again in regfile and pipeline registers.

### Sync vs async reset
- sync reset: rst checked inside always @(posedge clk), not in sensitivity list. only takes effect ON an edge, clean and predictable.
- async reset: separate trigger, fires instantly regardless of clock. needed on real chips cause clock might not be stable yet at power on. risk is metastability if rst releases too close to an edge.
- real chips do "async assert, sync deassert" as a compromise, EMASS (my internship company) relevant not project relevant.
- going sync here cause testbench clock never stops, no power-on problem to solve.

### single cycle vs pipelined mixup
- single cycle: whole instruction (fetch-writeback) done in one clock cycle, bottlenecked by slowest instr (lw).
- pipelined (phase 4): same datapath split into 5 stages (IF/ID/EX/MEM/WB), multiple instrs overlapping. more throughput, way more complexity.

### pc.v stays dumb on purpose
- doesnt decide +4 vs branch vs jump, doesnt check alignment either. just latches pc_next blind.
- architecture rule #1 - control logic stays out of datapath modules. the actual mux gets built day 39 at top level wiring.
- alignment isnt pc.vs job anyway, works out fine once rest of datapath is built right (aligned+4=aligned).

### testbench lesson
- most important case for any register: prove it does NOT update before the edge, not just that it does update after. change input mid cycle, check output hasnt moved, then check after edge. this is the one case that catches an accidental combinational "register."

### what got built
- rtl/core/pc.v: 32 bit PC register, sync reset, pc_next in, pc_current out
- tb/core/pc_tb.v: 7 cases, reset/latch timing/mid-cycle stability/boundary value/re-reset, all passed
- full folder skeleton up: rtl/core, rtl/soc, tb/core, tb/soc, programs, docs
