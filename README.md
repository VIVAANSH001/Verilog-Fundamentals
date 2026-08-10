# RISC-V CPU: A 5-Stage Pipelined RV32I Core

A pipelined RV32I RISC-V processor built from scratch in Verilog, alongside a complete single-cycle implementation kept as a permanent reference, and a core architecture deliberately designed to grow into a microcontroller.

---

## Overview

This repository contains a fully pipelined RV32I RISC-V processor, implemented from the ground up in Verilog. It is accompanied by a complete single-cycle implementation of the same instruction set, not an early draft that was abandoned once the pipeline worked, but a finished, independently tested core that exists on purpose, as the baseline every pipelining decision was measured against.

The core is the product of a deliberate progression, not an isolated exercise: gates, multiplexers, decoders, adders, comparators, flip-flops, counters, a register file, FSMs, and a small ALU were built first as reusable building blocks (see `verilog-fundamentals/`), with the CPU itself assembled only once that foundation was solid.

Three things distinguish this project from a typical from-scratch RV32I build:

**The hazards are actually solved.** A pipelined datapath is not a working pipelined CPU until data and control hazards are handled correctly. This core implements a full forwarding unit (EX/MEM and MEM/WB into EX), load-use hazard detection with stall and bubble insertion, and branch/jump flushing across all six branch types plus JAL and JALR, each verified against dedicated hazard test programs, not assumed correct by inspection.

**Two cores, not one.** Building the pipeline second, with the single-cycle core still intact and runnable, means every claim about the pipeline's cost and benefit is backed by a direct one to one comparison rather than a single number in isolation.

**It's built to be extended, not just finished.** The core communicates with memory exclusively through a single address-decoded interface, with an address range permanently reserved for memory-mapped peripherals. Nothing here assumes the CPU is the whole system, it's designed as the starting point for one.

---

## Results

A single-cycle CPU pays a fixed cost on every instruction: the clock period has to be long enough for the slowest instruction in the entire ISA to finish, which means a simple register-to-register `addi` sits idle for the same window a full memory load needs to complete. Pipelining exists to close that gap, different instructions occupy different stages simultaneously, so the clock only has to be as long as the slowest *single stage*, not the slowest *entire instruction*.

| Metric | Single-Cycle | Pipelined |
|---|---|---|
| CPI | 1.000 | 1.134 |
| Critical path (synthesis) | 2.70 ns | *not reliable, see note below* |

CPI was measured directly via `tb/core/cpi_tb.v` across the project's test programs. The single-cycle result of 1.000 is architectural, not measured behavior: by construction, exactly one instruction retires every cycle, no exceptions. The pipelined result of 1.134 is the real, measured cost of correctness: every load-use stall and every flushed branch or jump shows up in that number as overhead above the ideal CPI of 1.0.

**A note on timing.** The single-cycle critical path of 2.70 ns comes from a full synthesis and static timing analysis flow (Yosys, OpenSTA, Nangate45 standard cells) and is solid enough to cite directly. The same flow run against the pipelined core reports figures in the 7 to 9 ns range, and that number is not trustworthy. It's an artifact of unbuffered high-fanout nets in the synthesis output, not a measurement of how fast the pipelined design actually runs. Rather than present a number that looks precise but isn't, this is documented as an open limitation. See [Future Work / Limitations](#future-work--limitations).

The honest takeaway: pipelining here costs roughly 13% in CPI to buy the ability to run at a fundamentally higher clock frequency, a trade that only pays off once the clock speedup from shorter per-stage logic outweighs that 13%, which single-stage synthesis alone can't yet confirm for this design.

## Architecture

Both cores share the same five-stage breakdown of work: fetch, decode, execute, memory, writeback, they differ only in whether that work happens in one clock cycle or is split across five overlapping ones. The diagrams below show each version's datapath, followed by a note on how the core reaches memory and where peripherals will eventually plug in.

### Single-Cycle Datapath

![Single-cycle datapath](docs/images/architecture-single-cycle.svg)

Every instruction moves through all five stages combinationally within a single clock edge: `regfile` reads and `alu_32` computes in the same cycle that `branch_comp` resolves a branch and feeds `pc` directly, with no pipeline registers, no hazards, and no forwarding required anywhere. The tradeoff is that the clock period has to accommodate the slowest instruction in the ISA: a load, which touches every stage, even when running something as simple as `addi`.

### Pipelined Datapath

![Pipelined datapath](docs/images/architecture-pipelined.svg)

The pipelined version breaks that same datapath into five stages separated by pipeline registers — `if_id_reg`, `id_ex_reg`, `ex_mem_reg`, `mem_wb_reg`, allowing up to five instructions to be in flight at once. The overlap isn't free: the orange blocks are what pay for it. `hazard_detect` freezes fetch and decode for a cycle whenever a load's result isn't available yet, and `forwarding_unit` reroutes ALU results and load data back into the execute stage before they've reached the register file, avoiding a stall wherever forwarding alone can resolve the dependency.

### Memory and the Path to Extensibility

Both cores reach memory through the same seam. `mem_interface.v` sits between the core's memory port and the data RAM, and every load, store, and instruction fetch passes through it rather than touching RAM directly. Today it decodes exactly two ranges: `0x0000_0000` to `0x0000_0FFF` forwards to the 4KB data RAM, and everything at `0x1000_0000` and above is reserved and stubbed out. Nothing lives in that upper range yet, but because every memory access already flows through this one decoder, adding a peripheral later means writing the peripheral and giving it an address range, not touching the core, the pipeline, or the hazard logic. See [Extensibility](#extensibility) for how that seam is meant to get used.

## The Pipeline in Depth

The five stages shown above aren't new hardware, they're the same modules from the single-cycle core, now separated by pipeline registers so up to five instructions can be in flight simultaneously. **Fetch** reads the next instruction while **Decode** extracts operands and control signals for the instruction one cycle ahead of it, **Execute** runs the ALU or resolves a branch for the instruction two cycles ahead, **Memory** services a load or store for the instruction three cycles ahead, and **Writeback** commits a result to the register file for the instruction that entered the pipeline four cycles earlier. On paper this quadruples throughput. In practice, instructions in flight together aren't independent, one stage's output is often another stage's input before it's actually ready, and handling that correctly is most of what separates a pipelined datapath from a pipelined CPU.

### Forwarding

The common case is a data hazard: an instruction needs a register value that a very recent instruction hasn't written back yet. Stalling until the write actually lands would erase most of the pipeline's benefit, so `forwarding_unit.v` instead intercepts the value one cycle early and routes it directly into the ALU's inputs.

Two sources are checked, both compared by register **address**, not value: `id_ex_rs1`/`id_ex_rs2` (the operands the instruction currently in Execute needs) against `ex_mem_rd` (the destination of the instruction one stage ahead, still sitting in Memory) and `mem_wb_rd` (the destination of the instruction two stages ahead, sitting in Writeback). If both match the same register, EX/MEM wins over MEM/WB, since it's the more recent value. `x0` is excluded from both checks, a write to `x0` never has meaning, so a coincidental address match there would forward a value that doesn't need forwarding at all.

This mechanism resolves the overwhelming majority of data hazards in a single cycle, with no stall and no bubble.

### Load-Use Stalls

Forwarding has one case it structurally cannot fix: a load immediately followed by an instruction that consumes the loaded value. The reason isn't a bug in the forwarding logic, it's timing, `ex_mem_alu_result` only ever holds what the ALU computed in Execute, and for a load that's just the memory *address*, not the data at that address. The real value doesn't exist until Memory actually runs, one cycle later than a back-to-back consumer would need it forwarded.

`hazard_detect.v` catches this case by comparing the load currently in Execute (`id_ex_mem_read`, `id_ex_rd`) against the raw, not-yet-latched operands of the instruction sitting in Decode. On a match, one stall signal does three things at once: `pc.v` holds the current program counter instead of advancing, `if_id_reg.v` holds its output instead of latching the next fetched instruction, and `id_ex_reg.v` is forced into a bubble, an all-zero, no-op instruction, so nothing incorrect enters Execute. One cycle later, the load has reached Memory, its result is available for forwarding, and the stalled instruction proceeds normally.

### Branch and Jump Flushing

Branches and jumps introduce a different kind of hazard: by the time a branch resolves, the pipeline has already speculatively fetched and begun decoding the two instructions immediately after it, assuming execution just continues sequentially. If the branch is taken, those two instructions were fetched from the wrong path entirely and have to be discarded before they can do any damage.

All six branch types (`BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`) resolve in Execute, alongside `JALR`. `JAL` is the exception, since it's unconditional and needs no register read, it resolves a stage earlier, in Decode. Whichever stage triggers the flush, the same two pipeline registers get cleared: `if_id_reg` (killing the wrong-path instruction still in Fetch) and, for branches and `JALR`, `id_ex_reg` as well (killing the wrong-path instruction that had already reached Decode). `JAL` only needs the one-instruction flush, since nothing wrong has reached Decode yet by the time it resolves.

`JALR`'s target has one additional wrinkle the other three don't: because it's computed as `rs1 + imm` rather than a fixed offset from the program counter, the result can land on an odd address even when the inputs look fine. Since RISC-V instructions are required to be 2-byte aligned, `JALR` forces bit 0 of the computed target to zero before it's used, per spec.

One of these mechanisms surfaced a real bug during development: `hazard_detect.v` originally read `rs1`/`rs2` off a fixed instruction slice regardless of instruction format. `JAL` reads no registers at all, but its immediate happens to occupy exactly the bit positions the decoder was treating as `rs1`, so a load a few instructions earlier could false-trigger a stall against garbage that was never actually a register. The fix gates the stall condition per-operand, checking whether the instruction in Decode genuinely uses `rs1`/`rs2` at all before comparing against them.