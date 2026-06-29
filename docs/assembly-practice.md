# Assembly Practice

These are assembly snippets from the ISA learning phase. I created this new file so that the isa-notes.md file can stay strictly for content and this is where you can find my assembly.

## Day 20: Array Copy
- Copies a 4 element word array from the src (x1) to the dst(x2) using only the LW and SW instructions,no branches yet cause I havent learnt them yet. x3 used as scratch.

```
lw x3, 0(x1)
sw x3, 0(x2)
lw x3, 4(x1)
sw x3, 4(x2)
lw x3, 8(x1)
sw x3, 8(x2)
lw x3, 12(x1)
sw x3, 12(x2)
```
## Day 22: JAL/JALR practice
- Basic call/return using JAL, then an indirect call through a register using JALR. add_five just does x5 = x5 + 5, the function pointer one does x7 = x7 - 1.

0x0000: jal ra, add_five
0x0004: nop
add_five:
0x0100: addi x5, x5, 5
0x0104: jalr x0, 0(ra)

- For this next one assume x6 already holds 0x0200 (function pointer style call)

0x0000: jalr ra, 0(x6)
0x0004: nop
0x0200: addi x7, x7, -1
0x0204: jalr x0, 0(ra)