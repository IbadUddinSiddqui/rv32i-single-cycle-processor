# test_system.S : FENCE, FENCE.I, ECALL, EBREAK and the 6 CSR instructions
#   CSRRW CSRRS CSRRC CSRRWI CSRRSI CSRRCI  (using mscratch, mtvec, mepc, mcause, cycle, instret, misa)
    .globl _start
_start:
    la    x1, handler
    csrrw x0, mtvec, x1          # mtvec = handler (x1 = handler address)

    # ---------------- CSR register forms (mscratch) ----------------
    addi  x2, x0, 0x55
    csrrw x3, mscratch, x2       # x3 = old = 0      ; mscratch = 0x55
    csrrs x4, mscratch, x0       # x4 = 0x55         ; (no write, rs1 = x0)
    addi  x5, x0, 0x0F
    csrrs x6, mscratch, x5       # x6 = 0x55         ; mscratch = 0x5F (set bits)
    addi  x7, x0, 0x11
    csrrc x8, mscratch, x7       # x8 = 0x5F         ; mscratch = 0x4E (clear bits)
    csrrs x9, mscratch, x0       # x9 = 0x4E

    # ---------------- CSR immediate forms ----------------
    csrrwi x10, mscratch, 21     # x10 = 0x4E        ; mscratch = 21
    csrrsi x11, mscratch, 10     # x11 = 21          ; mscratch = 31
    csrrci x12, mscratch, 3      # x12 = 31          ; mscratch = 28
    csrrs  x13, mscratch, x0     # x13 = 28

    # ---------------- FENCE / FENCE.I (no-ops) ----------------
    fence
    fence.i
    addi  x14, x0, 7             # still executes normally

    # ---------------- read-only CSRs ----------------
    csrrs x20, cycle, x0         # cycle counter, twice, one nop apart -> difference 2
    nop
    csrrs x21, cycle, x0
    sub   x22, x21, x20          # x22 = 2
    csrrs x23, instret, x0
    nop
    csrrs x24, instret, x0
    sub   x25, x24, x23          # x25 = 2
    csrrs x26, misa, x0          # x26 = 0x40000100 (RV32I)

    # ---------------- ECALL ----------------
ecall_here:
    ecall                        # -> handler (mcause = 11, mepc = address of this ecall)
    csrrs x28, mepc, x0          # x28 = address of ecall_here
    csrrs x29, mcause, x0        # x29 = 11

    # ---------------- EBREAK ----------------
    ebreak                       # -> handler (mcause = 3)
    addi  x18, x0, 99            # reached after the handler returns
end:
    jal   x0, end

    # ---------------- trap handler ----------------
    # no MRET in the base set: read mepc, add 4, jump back with JALR
handler:
    csrrs x15, mcause, x0        # x15 = last cause
    csrrs x16, mepc, x0
    add   x19, x19, x15          # x19 = sum of causes (11 + 3 = 14)
    addi  x17, x17, 1            # x17 = number of traps (2)
    addi  x16, x16, 4
    jalr  x0, 0(x16)             # return to the instruction after the trap
