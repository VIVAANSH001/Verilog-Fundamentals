# Modules Built

## Basic Gates
- `and_gate.v` : 2-input AND gate
- `or_gate.v` : 2-input OR gate
- `not_gate.v` : single input NOT gate
- `xor_gate.v` : 2-input XOR gate
- `nand_gate.v` : 2-input NAND gate
- `nor_gate.v` : 2-input NOR gate
- `xnor_gate.v` : 2-input XNOR gate

## Multi-bit
- `and8.v` : 8-bit bitwise AND

## Multiplexers
- `mux2.v` : 2:1 mux using ternary operator
- `mux4.v` : 4:1 mux using three mux2 instances
- `mux8.v` : 8:1 mux using case statement

## Encoders and Decoders
- `decoder3to8.v` : 3-to-8 decoder, activates one of 8 output lines
- `priority_encoder.v` : 8-to-3 priority encoder with valid signal

## Adders
- `half_adder.v` : adds two single bits, outputs sum and carry
- `full_adder.v` : adds two bits plus carry in, built using two half adders
- `ripple_carry_adder.v` : 4-bit adder using four full adders chained together, carry ripples through each stage

## Comparators and Subtractors
- `comparator4.v` : 4-bit comparator, outputs eq, lt, gt using Verilog comparison operators
- `ripplecarry8.v` : 8-bit ripple carry adder with cin port for reusability
- `subtractor8.v` : 8-bit two's complement subtractor built using ripplecarry8 with ~b and cin=1

## Flip Flops
- `dff.v` : D flip flop with asynchronous reset, captures d on rising clock edge
- `dff_sync.v` : D flip flop with synchronous reset, reset only takes effect on clock edge
- `notes.md` : personal notes on difference between always @(*) and always @(posedge clk)

## Sequential
- `tff.v` : T flip-flop, toggles output when t=1 on rising clock edge
- `jkff.v` : JK flip-flop, set/reset/toggle/hold based on j and k inputs
- `d_latch.v` : D latch, transparent when enable is high, holds value when low
- `shift_register.v` : 4-bit shift register, shifts right on each clock edge
- `counter_up.v` : 4-bit binary up counter with async reset
- `counter_updown.v` : 4-bit up-down counter with enable and async reset
- `register8.v` : 8-bit register with load enable and async reset
- `register_file.v` : 8 registers, 2 async read ports, 1 sync write port, x0 hardwired to 0

## FSM
- `traffic_light.v` : Moore FSM, RED 10 cycles, GREEN 8 cycles, YELLOW 3 cycles
- `sequence_detector.v` : Mealy FSM, detects overlapping sequence "1101"

## ALU
- `alu8.v` : 8-bit ALU supporting ADD, SUB, AND, OR, XOR, SLL, SRL, SLT, SLTU with zero flag

## ISA Notes
- `docs/isa-notes.md` : personal notes on RV32I ISA: registers, instruction formats
- `docs/images/` : handwritten diagrams for instruction formats