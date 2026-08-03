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