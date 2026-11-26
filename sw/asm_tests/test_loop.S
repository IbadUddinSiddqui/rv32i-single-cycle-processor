# test_loop.S : loops and backward branches
# Expected: x10=55 (sum 1..10), x11=11, x13=0, x14=20
    .globl _start
_start:
    addi  x10, x0, 0
    addi  x11, x0, 1
    addi  x12, x0, 11
loop1:
    add   x10, x10, x11
    addi  x11, x11, 1
    bne   x11, x12, loop1
    addi  x13, x0, 10
    addi  x14, x0, 0
loop2:
    addi  x14, x14, 2
    addi  x13, x13, -1
    bne   x13, x0, loop2
end:
    jal   x0, end
