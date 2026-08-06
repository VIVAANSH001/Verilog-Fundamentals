# Day 66: CPI Measurement

CPI = cycles / instructions retired. "retired" = id_ex_valid high (a real, non-bubble instruction sitting in EX that cycle), see hazard-notes.md day 66 entry for why this heuristic is safe here, breaks only on unmapped opcodes and none of the test programs use those

ideal steady-state CPI on this 5-stage pipeline is 1, no stalls no flushes, ignoring the one-time pipeline fill at the start

## full-program CPI

|           Program         | Cycles | Instructions |  CPI  |
|---------------------------|--------|--------------|-------|
|      fib_pipeline.hex     |  110   |      97      | 1.134 |
| hazard_scenarios_test.hex |   24   |      18      | 1.333 |
| branch_scenarios_test.hex |   52   |      41      | 1.268 |
|   jump_pipeline_test.hex  |  149   |     108      | 1.380 (truncated before steady-state trap loop, see below) |

- hazard_scenarios_test.hex has no setup preamble, dense hazard content from instruction 1, so full-program IS the interesting portion for that one, no separate window taken

## windowed (steady-state, one loop iteration) CPI

|                   Program                 | Window (cycles) | Cycles | Instructions |  CPI  |
|-------------------------------------------|-----------------|--------|--------------|-------|
|        fib_pipeline.hex (loop body)       |      14–23      |   10   |       9      | 1.111 |
| branch_scenarios_test.hex (Section B loop)|      41–47      |    7   |       5      | 1.400 |
|     jump_pipeline_test.hex (trap loop)    |      22–25      |    4   |       3      | 1.333 |

## reading the results

- worst to best full-program CPI: hazard (1.333) > jump (1.380 truncated) > branch (1.268) > fib (1.134). matches prediction, hazard_scenarios_test.hex is deliberately dense with back to back load-use stalls so it should be the worst hazard-per-instruction ratio of the batch, and it does come out on top
- jump loop's steady-state (1.333) is worse than fib's full-program average (1.134) despite being just 3 tiny instructions repeating forever. root cause is jal resolving in ID not IF (day 65), so every single pass through the loop IF fetches one wrong-path instruction (pc+4) one cycle before the redirect lands, gets flushed as a bubble. 1 wasted cycle out of every 4-cycle iteration is exactly a 25% CPI penalty on top of ideal, matches the observed 1.333
- fib_pipeline.hex has the best CPI of the batch both full-program and windowed, consistent with it being the most realistic/hazard-light program here. though the gap-padding nops from day 65's fix (visible as back to back id_ex_valid=0 cycles in its trace) do drag this up a bit above what a hand-optimized version could hit, not a "best case" number, just a realistic one
- branch_scenarios_test.hex's Section B window (1.400) is the single worst per-iteration number measured today, makes sense, every iteration is a taken backward branch and every taken branch flushes the pipeline the same way jal does, just with one more wasted cycle per flush than jal's

## known simplification (carried from hazard-notes.md)

- id_ex_valid is a heuristic not a general "instruction valid" bit, an unmapped opcode would look identical to a bubble under this method (control_unit's default case also zeroes all four signals). safe for every test program run today since none use unmapped opcodes, but this is a real engineering tradeoff, reusing existing observability vs threading a dedicated valid bit through every pipeline register, not the "correct" general solution

# Day 69: Single-Cycle vs Pipelined Performance Comparison

comparing cycle count needed to run the same program (fib_pipeline.hex, same dynamic instruction stream) on both cores. single-cycle has no pipeline registers so CPI=1 is true by construction, not measured, no id_ex_valid-style signal to watch, so completion is instead detected by pc_current reaching the address right after the program's last instruction, see single_cycle_cycles_tb.v

this is a cycle-count comparison only. no timing/critical-path modeling exists anywhere in this project, so the results below say nothing about wall-clock time or real hardware throughput, only CPI x clock period = time, and only the CPI side was ever measured here

## bug found before any comparison could run

running fib_pipeline.hex on the single-cycle core hung the sim outright, infinite delta-cycle, not just slow.The root cause being: regfile.v's day 58 same-cycle write-through bypass (we && write_addr==read_addr ? write_data : registers[...]) assumes write and read come from different instructions, true in the pipeline (WB retiring vs ID reading a newer instruction), false in single-cycle where they're the same instruction. any self-referencing ALU op (rd==rs1, e.g. addi x4,x4,1, exactly fib_pipeline.hex's loop counter) turns into read_data1 --> alu_a --> alu_result --> write_data --> read_data1, a real combinational loop, no register anywhere to break it

fix: added a BYPASS_WRITE parameter to regfile.v, default 1 so core_pipelined.v is untouched, instantiated as BYPASS_WRITE(0) in core.v only. single-cycle never needed the bypass, the write is still synchronous so reading the old registers[] value this cycle is correct. confirmed fixed, x1=55 x2=89 matches pipelined

latent since day 58, single-cycle core.v hadn't been re-tested against a self-referencing ALU op since before that regfile change went in

## cycle count comparison

|      Core     | Cycles | Instructions |  CPI  |
|----------------|--------|--------------|-------|
|  single-cycle  |   97   |      97      | 1.000 |
|    pipelined   |  110   |      97      | 1.134 |

## reading the results

- same program, same 97 dynamic instructions, pipelined still takes 110/97 = 1.134x the cycles. all 13 extra cycles are stall/flush overhead single-cycle structurally can't have, it has no pipeline to stall or flush, it just burns exactly one cycle per instruction unconditionally
- the id_ex_valid=0 dips in the pipelined trace, one per loop iteration (cyc 15, 25, 35...), are the wrong-path instruction getting flushed after jal, same day-65 mechanism as jump_pipeline_test.hex's trap loop from day 66. 10 loop passes x 1 flushed cycle each accounts for a large chunk of the 110 vs 97 gap on its own
- cycle count alone makes single-cycle look like the "winner" here, that's not the real takeaway. pipelining's actual payoff is a shorter clock period since each stage does less work per cycle, never modeled in this project, so today's numbers can't speak to that side of the equation at all

## bonus: fib_pipeline.hex's fillers are now dead weight

day 65 added filler nops to satisfy branch_comp's pre-day-68 forwarding gap. day 68 fixed that gap directly (branch_comp now reads alu_a_forwarded/alu_b_forwarded). tested a trimmed version with the fillers removed and branch/jump offsets re-encoded (programs/generated/fib_pipeline_trimmed.hex) on the pipelined core:

|          Program          | Cycles | Instructions |  CPI  |
|----------------------------|--------|--------------|-------|
| fib_pipeline.hex           |  110   |      97      | 1.134 |
| fib_pipeline_trimmed.hex   |   79   |      66      | 1.197 |

still correct, x1=55 x2=89 x4=10. higher CPI is expected, not a regression, same fixed stall/flush overhead now amortized over fewer instructions. confirms the fillers were purely a workaround for a bug that's since fixed. not swapping the main fib_pipeline.hex file over today, other testbenches implicitly depend on it staying put, just noting it's provably safe to do later

## known simplification (single-cycle completion detection)

- single_cycle_cycles_tb.v's completion signal is a fixed landmark address (pc_current reaching the instruction right after the program's known last instruction), not a general "program done" detector. works cleanly here because fib_pipeline.hex's control flow is fully known and static, would need reworking (or a dedicated halt instruction/signal) for a program whose exit point isn't known ahead of time

# Extra Day: Real Gate-Level Timing (Nangate45, yosys + OpenSTA)

first real synthesis + STA run, replacing the CPI-only numbers from days 66/69 with
actual gate delay on a real 45nm liberty library.

|      Core     | Critical path | Worst-hop fanout | Slack (10ns clock) |
|----------------|----------------|-------------------|----------------------|
|  single-cycle  |     2.70ns     |         62        |    7.27ns (MET)      |
|    pipelined   |     9.06ns*    |        787        |    0.90ns (MET)      |

*not trustworthy, see below

## why the pipelined number is a synthesis artifact

one pipeline stage boundary (IF/ID --> ID/EX) reporting more delay than single-cycle's
entire datapath is architecturally impossible if real, there's strictly less logic
between any two pipeline registers than across the whole single-cycle path. this alone
proves the number is inflated, not evidence pipelining is slower.

root cause: two unbuffered high-fanout nets off u_if_id's register (787 fanout/3.23ns,
206 fanout/4.76ns) account for ~8ns of the 9.06ns. almost certainly stall/flush driving
hundreds of gates directly, zero buffering, a physical-design gap in this flow.

tried fanout-aware abc mapping (`map -F 16`): didn't fix it. dominant fanout barely
moved, total delay improved incidentally (9.06 --> 7.76ns) from unrelated restructuring.
real fix needs a max_fanout constraint before synthesis proper, not retrofitted after.

## conclusion

- single-cycle's 2.70ns is real, cite directly
- pipelined's true critical path is unknown, not measured further, this is a known toolchain limitation (no buffer insertion / no P&R), not a CPU design flaw
- the "shorter clock period compensates for more cycles" half of the pipelining argument can't be demonstrated with real numbers from this flow. day 69's cycle-count tradeoff (1.134x more cycles) remains the only solid measured number on the pipelining tradeoff
- staying open going into phase 5 (polish/ship), not chasing further per plan