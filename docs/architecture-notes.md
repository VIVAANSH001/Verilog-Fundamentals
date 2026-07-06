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

## DAY 30: Instruction Memory

### why instruction memory is read only
- imem holds the program, and the program doesnt change while the cpu runs it.only ever needs a read path, no write port, no we(write enable) signal.
- data memory is different story, that one needs writes (sw etc), different module, different job.

### combinational, not registered
- single cycle rule comes into play again here, instruction gotta be available on the wire same cycle the pc points to it, no waiting a cycle for it to show up.

### byte address vs word index mismatch
- pc counts in bytes (0-->4-->8...) cause thats how riscv addresses memory.
- imem array is word indexed (0-->1-->2...) since each slot holds one full 32 bit instruction, not a byte.
- convert byte addr --> word index by dropping bottom 2 bits: pc_current[11:2]. slicing not dividing cause division is expensive in hardware, slicing is literally free (just wiring).
- also finally clicked why pc is 32 bits even tho imem is only 1024 words (10 bits worth of addressing needed for imem). pc width = full address space width, doesnt shrink just cause imem is small today. matters later once mmio/peripherals get mapped into higher addresses as pc doesnt change, just more of it starts getting used.

### $readmemh and the hex file
- hex file (programs/test1.hex) is just plain text, hand written, one instruction per line, 8 hex digits each. no headers, no syntax.
- $readmemh runs inside an initial block, fires at time 0 before sim clock even starts moving. loads line 1 into mem[0], line 2 into mem[1], etc, in order.

### testbench lesson
- no clock needed here, just drive pc_current directly and check output settles right after, cause its combinational.
- used !== instead of != for checks. if readmemh path is wrong, output comes back as x, and != against x gives x back too (useless, not true/false). !== gives a clean 0/1 even against undefined bits, actually catches the failure instead of silently doing nothing.

### what got built
- rtl/core/instr_mem.v: 1024x32 word memory, combinational read, $readmemh loaded, address sliced [11:2] for word indexing
- programs/test1.hex: 3 hand encoded instructions including addi x1,x0,5 / addi x2,x0,10 / addi x3,x0,15.
- tb/core/instr_mem_tb.v: 3 cases, pc=0/4/8, all passed

## DAY 31: Instruction Decoder

### why the decoder is just slicing, no logic
- decoder's only job is pulling opcode, rd, rs1, rs2, funct3, funct7 out of the raw 32 bit instruction. pure wiring, no always block, no case statement, no decisions.
- outputs all 6 fields unconditionally every time, regardless of what format the instruction actually is. decoder doesnt know or care what format its looking at.

### fixed field positions across formats
- opcode [6:0], rd [11:7], rs1 [19:15], rs2 [24:20], funct3 [14:12], funct7 [31:25] stay in the same bit position whenever they exist in a given format. thats what makes unconditional slicing safe, no muxing needed.
- immediate is the one thing that doesnt sit still, scrambles around depending on format (esp B and J type). thats explicitly NOT this modules job.

### three way split, not a chain
- decoder: raw instr --> 6 fixed fields, no logic
- immgen (day 34): raw instr --> immediate value, reads raw instr directly, not through decoder
- control unit (day 37): reads decoders outputs (opcode/funct3/funct7) --> control signals, decides but doesnt execute
- immgen and decoder both independently slice the same raw instr for different things, not decoder feeding immgen. CU is the one thing that actually consumes decoders output, keeps the "one seam" rule intact instead of two modules re-slicing the same bits.

### garbage-in-context is fine
- ran addi x1,x0,5 through it, rs2 output showed up as 5. thats not a real register read, thats the immediate bits sitting in the rs2 slot for I-type. decoder doesnt know that and outputs it anyway.
- correct behavior tho, decoder isnt supposed to know format. its on immgen (reading raw instr) and CU (knowing opcode = I-type) to actually treat that field as garbage for this instruction.

### what got built
- rtl/core/instr_decoder.v: fixed slice decoder, 6 outputs (opcode/rd/rs1/rs2/funct3/funct7), pure combinational assigns
- tb/core/instr_decoder_tb.v: 3 cases (addi, add, sub), verified field extraction incl. funct7 distinguishing add vs sub