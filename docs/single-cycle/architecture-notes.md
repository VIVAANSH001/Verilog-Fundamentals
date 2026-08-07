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

## DAY 32: Register File

### why async read + sync write
- alu needs both operand values same cycle it reads them, single cycle rule again, so reads gotta be combinational (async). if reads were registered youd need an extra cycle just to get values out, breaks the whole one-instruction-per-cycle thing.
- writes are different, gotta be sync (only commit on posedge) cause otherwise a new result could stomp a register mid cycle while something else is still reading it. way safer to only ever change state on a clean edge.

### x0 hardwire, write-block vs read-mask
- two ways to keep x0 always reading 0: block writes from ever reaching regs[0], or let writes land wherever but mask the read output for addr 0 regardless of whats actually stored.
- went with read-mask only, no write block. reasoning: if some future control/decode bug accidentally sends a write to x0, write-block "protects" you by silently eating it, which just hides the bug. read-mask means even if garbage lands in regs[0] the read output still forces 0, doesnt matter what happened on the write side. defensive against bugs you havent written yet, not just the ones you're thinking about now.

### uninitialized on purpose, no reset
- regs array has no reset logic and starts uninitialized. considered giving it a reset that zeros everything, decided against it.
- riscv spec doesnt require gprs to hold any specific value at power on anyway (only x0 has to be 0, which is handled separately by the read mask).
- more importantly: if a test program reads a register before ever writing to it, thats a bug in the program, and uninitialized regs show X in gtkwave for that, screaming at you that something's wrong. a reset that zeros everything would quietly turn that same bug into a plausible looking 0, hides it instead of catching it.

### same cycle read-before-write ordering
- what happens if you read and write the same register in the same cycle, like add x1,x1,x2? does the read see old x1 or new x1?
- answer: old value, and this falls out for free from the async/sync split, no extra forwarding logic needed at this level. read is combinational off whatevers currently in regs[], write hasnt committed yet (wont till the edge), so read just naturally sees stale data until after the posedge lands.
- tb explicitly covers this: point read_addr at the same reg being written, sample right before the edge (expect old value), sample right after (expect new value).

### what got built
- rtl/core/regfile.v: 32x32 reg file, 2 async read ports, 1 sync write port, x0 masked on read only, no reset
- tb/core/regfile_tb.v: 6 cases incl. x0 read, basic write/read, write-to-x0 attempt, same cycle read-before-write ordering, dual port read, all passed

## DAY 33: ALU

### 10 ops, one case statement
- alu takes two 32 bit operands (a, b) and a 4 bit alu_ctrl select, does one of 10 ops, spits out a 32 bit result plus a zero flag.
- ADD, SUB, AND, OR, XOR, SLL, SRL, SLT, SLTU, SRA. pure combinational, always @(*) with a case on alu_ctrl, no clock involved at all. purely reactive to whatever inputs show up.
- like the decoder, alu doesnt know or care what instruction its serving. doesnt know funct3/funct7, doesnt know riscv encoding exists. alu_ctrl is its own clean encoding, mapping funct3/funct7 --> alu_ctrl is the ALU control units job (day 38), not this modules.

### SRA vs SRL, side by side proof
- ran the same negative number (0xFFFFFFFF, which is -1) thru both ops on the same shift amount.
- SRL: 0xFFFFFFFF >> 1 = 0x7FFFFFFF. zero fills the top regardless of what the sign bit was doing.
- SRA: 0xFFFFFFFF >>> 1 = 0xFFFFFFFF. sign bit keeps refilling, stays negative.

### SLT vs SLTU, same trick
- picked a and b where signed and unsigned interpretation straight up disagree: a=0xFFFFFFFF, b=1.
- as signed, a is -1, so a<b is true (SLT = 1).
- as unsigned, a is 4294967295, way bigger than 1, so a<b is false (SLTU = 0).
- same bit pattern, opposite answer depending which operation reads it. this is the case that would catch a bug instantly if $signed() got left off somewhere, cause every other test case that isnt deliberately negative wouldnt even notice.

### testbench approach
- no clock here either, alu is combinational so just drive inputs, wait a beat (#10), check output against a hand written expected value in the $display.
- covered all 10 ops, but the two that actually matter for edge cases (SLT/SLTU, SRL/SRA) I made sure to check whether the signed and unsigned disagree which was infact the case.

### what got built
- rtl/core/alu.v: 32 bit ALU, all 10 RV32I ops, alu_ctrl select via case statement, zero flag, $signed() used correctly for SRA (a only) and SLT (both operands)
- tb/core/alu_32_tb.v: 11 checks covering all 10 ops incl. zero flag on SUB, SRL vs SRA on the same negative number, SLT vs SLTU on the same disagreeing bit pattern, all passed

## DAY 34: Immediate Generator

### what immgen actually does
- reads raw instr same as decoder, doesnt go through it. figures out format off opcode[6:0], then slices + sign extends the immediate for whatever format it is.
- 6 formats total but R-type has no immediate at all, so really only 5 real cases plus a default that just spits 0.

### why the bits are scrambled in the first place
- Within the raw instruction opcode/rs1/rs2 stay pinned to the same bit position across every format, thats the whole reason decoder could slice unconditionally on day 31 without checking format first.
- immediate is whats left over after those fixed fields eat their spots, so it gets pushed into leftover bit ranges instead of sitting clean and contiguous. worse for immgen, better for rs1/rs2 reads starting instantly without waiting on format detection first. tradeoff made on purpose.
- B and J type are the two that actually scramble. I/S/U stay contiguous or close to it.

### concatenation vs replication, two different curly brace
- outer {a,b} is straight concatenation, glues pieces together msb to lsb in the order written.
- inner {N{expr}} is replication, repeats expr N times then concats all N copies. {20{instr[31]}} = sign bit copied 20 times, thats how I did sign extension by hand.
- widths gotta add up to exactly 32 every time, no automatic extension happening, I am constructing the full 32 bits myself field by field.

### Needed assistance on making the encoded instructions for the testbench
- The instructions needed in the testbench were very long and hard to make for the testing so it was important to get them right to test the immgen properly.
- I thus had to resort to the online forces to help build my encoded instructions which I then used to make my testbench work after a few errors in the encoding the module was correct all along.

### what got built
- rtl/core/immgen.v: pure combinational immgen, all 6 formats, case on opcode, sign extension via replication, B/J bit reassembly per spec
- tb/core/immgen_tb.v: 13 cases, positive+negative per format (I/S/B/U/J) plus R type default, all passed after fixing 3 bad instr encodings in the tb itself

## DAY 36: Data Memory + Memory Interface (Address Decoder)

### why data memory is byte addressed, not word addressed
- instr_mem only ever needed word indexing cause every instruction is a fixed 32 bit chunk, no smaller access ever happens to it.
- data memory is different, sb/lb need to touch exactly 1 byte, sh/lh need exactly 2, sw/lw need all 4. if the array was declared word-wide there'd be no way to cleanly address a single byte inside a word.
- so mem is declared as reg [7:0] mem [0:4095], 4KB, byte indexed. smallest addressable unit has to match the smallest access size the isa actually uses.

### word groups and lanes
- any given byte address falls into a "word group" (which 4-byte chunk it belongs to) and a "lane" within that group (its position 0 to 3 inside that chunk).
- word group is addr/4, lane is addr%4, but in hardware thats addr[11:2] and addr[1:0] respectively, bit slicing not actual division so that the hardware is simpler and cheaper as explained before.
- example: address 9 is word group 2 (bytes 8 to 11), lane 1.

### byte_en masking on writes
- writes are masked with a 4 bit byte_en signal, one bit per lane. sb only sets 1 bit, sh sets 2 adjacent bits, sw sets all 4. this is what keeps a byte write from touching the other 3 bytes sitting in the same word group.

### endianness, same concat pattern as immgen
- riscv is little endian, lowest address holds the least significant byte. storing 32'hAABBCCDD at address 0 means mem[0]=DD, mem[3]=AA.
- reading a word back out is straight concatenation like immgen's sign extension, just byte by byte instead of bit replication: {mem[base+3], mem[base+2], mem[base+1], mem[base]}. highest address goes leftmost cause concatenation builds msb to lsb left to right, same rule from day 34, different use case.

### combinational read, clocked write thus the same split as regfile
- reads are async/combinational, same single cycle reasoning as regfile's read ports from day 32, address in data out same cycle, no waiting a cycle for it to show up.
- writes are sync, only commit on posedge, same reasoning as regfile's write port, keeps two things from fighting over the same byte mid cycle.

### the memory interface / address decoder (SCALABILITY!!)
- this sits between the cpu's memory port and data_mem itself, doesnt replace data_mem, wraps it.
- address map locked in the plan is 0x0000_0000 to 0x0000_0FFF is RAM, 0x1000_0000+ is reserved for future peripherals (mmio), everything else unmapped.
- today it just forwards ram-range addresses straight to data_mem and stubs everything else, mmio/unmapped reads return 0, writes get dropped silently. nothing lives in the mmio range yet, just reserved so ram never gets handed that address space by accident.
- mem_write only ever reaches data_mem when the address decodes as ram. tested this directly, wrote to 0x1000_0000, confirmed address 0 was still untouched after.
- this is a very important component as it allows me to scale this project beyond if thats ever required.

### what got built
- rtl/core/data_mem.v: 4KB byte-addressed RAM, byte/half/word access via byte_en mask, clocked writes, combinational reads
- tb/core/data_mem_tb.v: 5 cases (sw, sb lane isolation, sh neighbor-byte preserved, mem_read=0 gating, unwritten address), all passed
- rtl/core/mem_interface.v: address decoder, ram range forwarding + mmio/unmapped stubs, write gated by is_ram
- tb/core/mem_interface_tb.v: 7 cases (ram write/read, upper boundary at 0xFFC, stray write to mmio rejected + ram confirmed untouched, mmio stub, unmapped stub), all passed

## DAY 37: Branch Comparator + Control Unit

### why branch comparator is separate hardware, not reused ALU
- could technically do beq/bne/blt etc by running rs1-rs2 through the alu and checking the zero flag or sign bit, some single cycle designs actually do this.
- went with dedicated comparator hardware instead, cause the alu's job list stays exactly what it was on day 33 (10 ops, alu_ctrl driven), no branch-specific hijacking of the zero flag or extra muxing on alu inputs just to serve branches.
- comparator takes rs1_data, rs2_data straight from regfile plus funct3 (funct3 already encodes which branch type it is, beq=000 up to bgeu=111), one case statement, one output: branch_taken. pure combinational, same as everything else built so far.

### control unit is the actual "main decoder"
- reads opcode straight off instr_decoder (day 31), thats the seam CU was always meant to consume, decoder doesnt know about CU and CU doesnt re-slice the instruction itself.
- one big case statement on opcode, sets a pile of control signals: reg_write, mem_read, mem_write, branch, jump, alu_src, result_src, alu_op, mem_size, mem_unsigned.
- CU decides, doesnt execute. same architecture rule as pc.v on day 29, control logic and datapath logic stay in separate modules, CU just raises flags, doesnt touch a single data value itself.

### result_src grew a 4th case i didnt expect
- started with 3: 00=alu result, 01=mem data, 10=pc+4 (for jal/jalr link register).
- lui broke the pattern. alu_32 only has 10 defined ops (add through sra), no "just output b" op exists. first pass had lui setting alu_op to a made up passthrough code, but theres no alu_ctrl value on the day 33 side to actually catch it.
- fixed by giving result_src a 4th value instead, 11 = immediate passthrough. lui skips the alu completely, regfile write data comes straight from immgen. cleaner than teaching the alu a fake op just for one instruction.

### mem_size/mem_unsigned exist but dont plug into anything yet
- mem_interface (day 36) wants a byte_en[3:0] straight up, not a size code. CU only sees opcode+funct3, has no visibility into the address, so it literally cant compute byte_en itself, that needs addr[1:0] too (which lane) not just the size.
- so CU outputs the funct3-derived size (00/01/10 = byte/half/word) and mem_unsigned (for lbu/lhu zero extend vs sign extend), leaves the actual byte_en generation and load sign/zero extend mux as open datapath work, not built yet.
- keeps the same seam discipline as everything else so far, decoder doesnt know about mem, CU doesnt know about addressing, data_mem doesnt know about ram vs mmio. each piece stays ignorant of what it doesnt need to know.

### auipc has a known gap, flagged not fixed
- auipc needs pc+imm, not rs1+imm like every other alu_src=1 case. alu only takes two data operands (a,b) off the datapath, no pc input wired to it yet.
- CU decodes auipc structurally the same as the other alu_src=1 cases for now, real fix is an alu input-a mux (rs1 vs pc) that has to happen at top level wiring, not something CU alone can solve. noted in the code, not resolved yet, day 39 problem.

### what got built
- rtl/core/branch_comp.v: standalone branch comparator, 6 branch types off funct3, signed compares for blt/bge, unsigned for bltu/bgeu
- tb/core/branch_comp_tb.v: 13 checks include taken+not-taken for every branch type, signed/unsigned disagreement case, invalid funct3 safety default, all passed
- rtl/core/control_unit.v: main decoder, opcode-driven case covering r-type/i-type/load/store/branch/jal/jalr/lui/auipc, outputs reg_write/mem_read/mem_write/branch/jump/alu_src/result_src/alu_op/mem_size/mem_unsigned
- tb/core/control_unit_tb.v: 11 checks, one per opcode class plus an unmapped-opcode safety default, all passed
- known open seams for day 39: byte_en generator (mem_size + addr[1:0] -> byte_en), load sign/zero extend mux (mem_unsigned), alu input-a pc mux (auipc)

## DAY 38: ALU Control Unit

### what alu_control actually decides
- takes control_unit's alu_op[1:0] (day 37) plus funct3/funct7 straight off instr_decoder (day 31), doesnt reslice the instruction itself, same seam discipline as everything else.
- alu_op=00 is dead simple, load/store/jalr/auipc all just want base+offset, alu_ctrl=ADD no matter what funct3/funct7 happen to contain, they're not even looked at.
- alu_op=01 (branch) reaches alu_control too but doesnt matter, branch_comp does the actual compare on separate hardware (day 37), nothing ever reads the alu's output for a branch instruction. alu_ctrl defaults to ADD here purely so the signal isnt left undriven, not a real answer.
- alu_op=10 is the only branch that actually needs funct3/funct7 to figure out the real op, r-type and i-type ALU-op instructions both land here.

### the bug alu_src catches
- funct3=000 covers 3 different instructions depending on context: r-type ADD, r-type SUB, and i-type ADDI. funct3 alone cant tell them apart.
- naive fix is check funct7[5], 0=ADD 1=SUB, works fine for r-type. breaks immediately for ADDI though, cause instr_decoder slices funct7=instr[31:25] unconditionally regardless of format (day 31 rule, decoder doesnt know format), and for i-type that bit range isnt a real funct7 at all, its just leftover immediate bits. addi x1,x2,-1 has an all-1s immediate, funct7[5] reads as 1, would get silently misread as SUB.
- fix: gate the funct7[5] check behind alu_src==0 (r-type only, alu_src comes straight off control_unit, no new signal needed). if alu_src==1 (i-type) at funct3=000, its ADDI, funct7 bits are garbage, dont even look at them, default straight to ADD.

### funct3=101 breaks the pattern, funct7 is real on both sides
- same funct3 collision shows up again, r-type SRL vs SRA. but this time the i-type version (SRLI/SRAI) is NOT garbage-in-that-slot like ADDI was.
- shift amount is only 5 bits (instr[24:20]), leaves instr[31:25] unused, and riscv spec deliberately fixes those bits (0000000=SRLI, 0100000=SRAI), same position and meaning as r-type funct7. so funct7[5] is legit here regardless of alu_src, no i/r-type gate needed for this one line, unlike funct3=000.
- point being alu_src alone isnt a blanket "trust funct7 or not" switch, it depends on which i-type instruction specifically, ADDI/ANDI/ORI/etc funct7 bits are fake, SLLI/SRLI/SRAI funct7 bits are real. funct3 is what tells you which situation youre in.

### what got built
- rtl/core/alu_control.v: alu_op + funct3 + funct7 + alu_src --> alu_ctrl, outer case on alu_op, inner case on funct3 for the alu_op=10 branch, funct7[5] gated by alu_src only where it needs to be (funct3=000), ungated where funct7 is always legit (funct3=101)
- tb/core/alu_control_tb.v: 12 cases covering alu_op=00 passthrough, r-type ADD/SUB, the "ADDI with garbage funct7" case specifically (proves the alu_src gate works), i-type SRLI/SRAI (proves funct7 stays trusted there), remaining no ambiguity ops (SLL/SLT/SLTU/XOR/OR/AND), branch dont care case

## DAY 39: Core + SoC Top Level Wiring

### core vs soc split, why instr_mem/mem_interface live outside core
- core.v is the cpu itself, all logic, zero memory besides regfile. soc.v is the box around it, just wiring, that plugs core's two ports (fetch port, mem port) into instr_mem and mem_interface.
- reason for the split: portability and testability. if instr_mem/mem_interface were inside core.v, swapping ram size or adding a peripheral means editing the cpu itself. keeping them out means core never changes, only the soc around it does. also means core can get testbenched with fake instruction/mem_rdata inputs directly, no real memory needed.
- regfile is the one exception, lives inside core, but thats a different kind of memory, tiny/fast/directly wired into the datapath every cycle, not something the cpu "reaches out for" the way it does ram.

### seam 1: byte_en generator needs address AND size, not just one
- mem_size alone only says how many lanes get enabled, doesnt say which ones. alu_result[1:0] is what actually picks the starting lane, same bottom-2-bits-of-address logic from day 36's data_mem, just now on the producer side instead of the consumer side.
- word stores (sw) dont even look at alu_result[1:0], byte_en just goes straight to 4'b1111 regardless, only byte/half stores need lane selection at all.

### seam 2: load extend is two stage, lane select then sign/zero extend
- data_mem always hands back the entire 32 bit word on a read, never just the requested byte/half. so alu_result[1:0] gets reused a second time here, same bits, different job: on write it picked which lanes to enable, on read it picks which lane to actually keep out of mem_rdata.
- after lane select, mem_unsigned decides zero extend (lbu/lhu, pad with 0) vs sign extend (lb/lh, replicate the sign bit into the top bits). mixing these up doesnt crash anything, just silently turns negative numbers positive, exact same category of bug as forgetting $signed() back on day 33's alu.

### seam 3: auipc a-mux, closes the day 37 gap
- day 37 flagged this and left it open on purpose, alu only takes two data operands off the datapath, no pc input existed yet.
- fix is one wire: alu_a = alu_a_pc ? pc_current : rs1_data. alu_a_pc is a new 1 bit signal off control_unit, set only for auipc. every other instruction alu_a just falls through to rs1_data like before, nothing else changes.
- lui also sets alu_src=1 same as auipc but does NOT set alu_a_pc, cause lui's result never even touches the alu, result_src=11 routes imm straight to writeback (the day 37 fix). alu_a_pc genuinely doesnt matter for lui since nothing reads alu_result for it.

### seam 4: branch/jump adder shared on purpose
- pc_pc_imm = pc_current + imm gets used by both branches and jal. not a coincidence, both instructions are computing the literal same formula, only difference is which imm format immgen picked upstream (b-type vs j-type) and whether the result actually gets taken (branch_taken gates it, jal always takes it).
- same "one piece of hardware, control logic decides how its used" pattern as the alu itself back on day 33, alu_op picks behavior instead of 10 separate op-specific circuits, here one adder gets reused instead of two.

### seam 5 + 6: pc_next mux and the jalr coupling (flagging this like day 38 flagged funct7)
- pc_next is a priority mux: branch taken > jalr > jal > default pc+4. jalr_target is NOT the return address, thats a mixup worth remembering, jalr_target is just where pc jumps to next (alu_result with bit 0 forced to 0 per spec). return address is a totally separate value, pc_plus4, going to a totally separate place, the writeback mux via rd. jal/jalr set the return addr via result_src=10, pc_next mux has nothing to do with that side.
- the actual thing worth flagging: jalr gets detected in the mux as `jump && alu_src`, not a dedicated signal. this works today ONLY because jalr happens to be the sole instruction where both jump=1 and alu_src=1 are true simultaneously, its an implicit coupling between two signals that each mean something else on their own (jump = "this is a jump", alu_src = "alu's second input is imm"), not an explicit "this is jalr" signal.
- works correctly today because of what currently exists in the isa, not because the code says so directly. if the isa ever grows (rv32m, compressed instrs, anything else that could land on alu_src=1 + jump=1 without being jalr) this silently breaks with no warning, just wrong pc_next.

### alu_zero, unused and thats fine
- alu_32 still outputs a zero flag, wired up, never read anywhere in core.v. not a bug, just a leftover from the alu's original generic design before branch_comp existed as dedicated hardware (day 37). branch_comp made alu_zero redundant for branch detection, some single-cycle designs do use the alu+zero-flag trick for beq but I went the dedicated comparator route instead.
- -Wall didnt actually flag this on recompile, worth keeping an eye on rather than assuming day 40's warning pass catches it automatically.

### what got built
- rtl/core/core.v: top level cpu, instantiates every day 29-38 module, all six day 39 seams (byte_en gen, load extend mux, auipc a-mux, branch/jump adder, pc_next mux, jalr bit-0 clear)
- rtl/soc/soc.v: core + instr_mem + mem_interface, pure wiring, no logic, no changes needed for the deferred jalr fix since jump never leaves core.v
- control_unit.v: added alu_a_pc output, set only in OP_AUIPC case, control_unit_tb.v updated and re-passed including the new auipc check
- verification status: structural only, all 13 files elaborate clean under iverilog -Wall, zero errors zero warnings. no functional test run yet, no testbench exists for core.v/soc.v, thats day 41's job (day 40 is warning cleanup first)

## DAY 40: Warning Cleanup Pass

### the whole day in one line
- ran the full repo compile, came back clean both times, nothing to actually fix. Spent most of the time making sure "clean" was real and not just -Wall missing stuff again like it did with alu_zero.

### -Wall alone isnt enough, already proved that
- day 39 handoff flagged that -Wall didnt catch alu_zero being dead, so cant just trust one clean compile and call it done. ran two passes instead: plain `-Wall` and `-Wall -g2012` (stricter 2012 SystemVerilog checking). both came back silent, zero errors zero warnings across all 12 rtl files.

### manual sweep, since the compiler wont catch everything
- went through core.v's full wire list by hand, checked every signal actually gets consumed somewhere downstream instead of just trusting the compiler.
- everything traced through clean except the one already known case: alu_zero. wired up off alu_32, never read anywhere in core.v. confirms day 39s note was right and that this is the only loose end in the whole module.

### alu_zero decision, closing the loop from day 39
- two options going in: strip the zero port off alu_32.v entirely, or leave it defined but unconnected in core.v.
- went through with leaving it unconnected. alu_32.v is closed out day 33 work, ripping the port out means reopening a finished module for a signal thats not actually causing a problem. also might genuinely want an alu-based zero check down the line if the design ever changes, cheap to keep the option open.
- documenting this here so its clearly a decision, not an oversight that got missed twice.

### what got built
- no new rtl, no new testbenches, day 40 is pure verification
- confirmed clean compile under `iverilog -Wall -o sim_top $(find rtl -name "*.v")` and `iverilog -Wall -g2012 -o sim_top $(find rtl -name "*.v")`, both zero warnings zero errors, all 12 files
- manual signal sweep of core.v, confirmed alu_zero is the only unread signal in the module
- decision made: alu_zero stays defined in alu_32.v, stays unconnected in core.v, not a bug, documented and deliberate
- day 41 is next: first real functional test, addi x1,x0,5 through the pipeline

## DAY 41: First Functional Instruction (soc_tb, formal)

### hierarchical dot path referencing
- testbench cant just probe a top level port for this, x1s value lives buried inside regfile inside core inside soc, none of that is exposed at soc_tb's level normally.
- icarus lets you reach straight through instance names from the tb: uut.u_core.u_regfile.registers[1]. each dot is one level deeper into the module hierarchy, uut(soc) --> u_core(core) --> u_regfile(regfile) --> registers[1](the actual reg array slot).
- from what I learnt this only works in simulations not in actual synthesis so that was a important note I took.

### hhat was day 41 for
- today I ran only one instruction (addi x1,x0,5), proper $display with inline expect comment, single clean pass, x1 = 5 (expect 5) confirmed.
- the main goal for today was to make sure my cpu works but on one instruction only and thankfully it worked perfectly.

### what got built
- tb/soc/soc_tb.v: single instruction test, addi x1,x0,5, hierarchical dot path read of registers[1], $display with expect comment, single @(posedge clk) + #1 settle
- programs/test1.hex: 1 instruction (00500093)
- result: x1 = 5 (expect 5), confirmed pass, $readmemh range warning present as always, expected/harmless