# test_loadstore.S : LW LH LHU LB LBU SW SH SB
# Expected: x1=0x12345678 x3=0x12345678 x4=0x78 x5=0x12 x6=-1 x7=0xFFFFFFFF
#           x8=0xFF x9=0xFF x10=-2 x11=0xFFFFFFFE x12=0xFFFE x13=0x5678FFFE
#           x14=0x5678 x15=0x7800
    .globl _start
_start:
    lui   x1, 0x12345
    addi  x1, x1, 0x678
    sw    x1, 64(x0)
    lw    x3, 64(x0)
    lb    x4, 64(x0)
    lb    x5, 67(x0)
    addi  x6, x0, -1
    sb    x6, 68(x0)
    lb    x7, 68(x0)
    lbu   x8, 68(x0)
    lw    x9, 68(x0)
    addi  x10, x0, -2
    sh    x10, 72(x0)
    lh    x11, 72(x0)
    lhu   x12, 72(x0)
    sh    x1, 74(x0)
    lw    x13, 72(x0)
    lh    x14, 74(x0)
    sb    x1, 77(x0)
    lw    x15, 76(x0)
end:
    jal   x0, end
