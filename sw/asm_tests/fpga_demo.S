# fpga_demo.S : endless counter in x10 (shown on the board LEDs)
    .globl _start
_start:
    addi  x10, x0, 0
loop:
    addi  x10, x10, 1
    jal   x0, loop
