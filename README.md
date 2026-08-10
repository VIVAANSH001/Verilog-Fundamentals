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