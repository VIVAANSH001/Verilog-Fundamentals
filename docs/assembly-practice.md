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