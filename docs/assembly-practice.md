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

```
0x0000: jal ra, add_five
0x0004: nop
add_five:
0x0100: addi x5, x5, 5
0x0104: jalr x0, 0(ra)
```

- For this next one assume x6 already holds 0x0200 (function pointer style call)

```
0x0000: jalr ra, 0(x6)
0x0004: nop
0x0200: addi x7, x7, -1
0x0204: jalr x0, 0(ra)
```

## Day 26: Factorial (Recursion in Assembly)
- Recursive factorial, n in a0, result returned in a0. RV32I has no MUL instruction as its the base CPU and does not support M type instructions, so the multiply step is done by repeated addition instead.

```
factorial:
    addi t0, x0, 1
    bgt  a0, t0, recurse  #checking if not base case
    addi a0, x0, 1
    jalr x0, 0(ra) # returning 1

recurse:
    addi sp, sp, -8 # free up the stack
    sw   a0, 0(sp) # save value n   
    sw   ra, 4(sp) # save return address         

    addi a0, a0, -1        
    jal  ra, factorial # recursive call   

    lw   t0, 0(sp)                    
    lw   ra, 4(sp)              
    addi sp, sp, 8 # empty the stack           
    
    addi t1, a0, 0 # value to be added repeatedly 
    addi a0, x0, 0 # where final value goes

mul_loop:
    beq  t0, x0, mul_done # branch if multiplication is done
    add  a0, a0, t1 # repeated addtion
    addi t0, t0, -1 # reducing t1 (no. of times u add)
    jal  x0, mul_loop # keep adding
mul_done:

    jalr x0, 0(ra)
```

## Day 26: Linear Search
- Searches array (base in a0, size in a2) for target value (a1). Returns index in a0 if found, -1 if not found. Walks a pointer forward by 4 bytes each iteration instead of recomputing index*4 each time.

```
linear_search:
    addi t0, x0, 0 # starting at index 0
    addi t1, a0, 0 # making the current element address into the base

search_loop:
    bge  t0, a2, not_found # checking if index is not found
    lw   t2, 0(t1) # loading the current element
    beq  t2, a1, found # checking if you found the element
    addi t0, t0, 1 # increasing the index
    addi t1, t1, 4 # increasing current address by 4
    jal  x0, search_loop #looping back

found:
    addi a0, t0, 0 # returning the right index
    jalr x0, 0(ra)

not_found:
    addi a0, x0, -1
    jalr x0, 0(ra)
```