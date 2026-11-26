# test_alu.S : every R-type and I-type ALU instruction, LUI, AUIPC, x0 behaviour
# Expected: x1=5 x2=-3 x3=2 x4=8 x5=5 x6=0xFFFFFFFD x7=0xFFFFFFF8 x8=1 x9=0
#           x10=80 x11=15 x12=0xFFFFFFFF x13=3 x14=40 x15=0x1FFFFFFF x16=0xFFFFFFFF
#           x17=1 x18=1 x19=250 x20=117 x21=13 x22=0x12345000 x23=0x1058
#           x24=0x12345678 x25=0
    .globl _start
_start:
    addi  x1,  x0, 5
    addi  x2,  x0, -3
    add   x3,  x1, x2
    sub   x4,  x1, x2
    and   x5,  x1, x2
    or    x6,  x1, x2
    xor   x7,  x1, x2
    slt   x8,  x2, x1
    sltu  x9,  x2, x1
    slli  x10, x1, 4
    srli  x11, x2, 28
    srai  x12, x2, 28
    addi  x13, x0, 3
    sll   x14, x1, x13
    srl   x15, x2, x13
    sra   x16, x2, x13
    slti  x17, x2, 0
    sltiu x18, x1, 10
    xori  x19, x1, 0xFF
    ori   x20, x1, 0x70
    andi  x21, x2, 0xF
    lui   x22, 0x12345
    auipc x23, 1              # this instruction is at address 0x58
    addi  x24, x22, 0x678
    addi  x0,  x0, 7          # writing x0 must be ignored
    add   x25, x0, x0
end:
    jal   x0, end
