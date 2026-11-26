# test_branch.S : BEQ BNE BLT BLTU BGE BGEU, JAL, JALR
# Expected: x10=234, x5=68 (return address of the JAL)
    .globl _start
_start:
    addi  x1, x0, 5
    addi  x2, x0, 5
    addi  x3, x0, -1
    addi  x10, x0, 0
    beq   x1, x2, L1        # taken
    addi  x10, x10, 1       # skipped
L1: bne   x1, x2, L2        # not taken
    addi  x10, x10, 2       # executed
L2: blt   x3, x1, L3        # taken (signed)
    addi  x10, x10, 4       # skipped
L3: bltu  x3, x1, L4        # not taken (unsigned)
    addi  x10, x10, 8       # executed
L4: bge   x1, x3, L5        # taken (signed)
    addi  x10, x10, 16      # skipped
L5: bgeu  x1, x3, L6        # not taken (unsigned)
    addi  x10, x10, 32      # executed
L6: jal   x5, func          # x5 = 68
    addi  x10, x10, 64      # executed after return
    jal   x0, done
func:
    addi  x10, x10, 128
    jalr  x0, 0(x5)         # return
done:
    jal   x0, done
