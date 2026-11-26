# Verification Report - RV32I Single-Cycle Processor
Name / Roll No: ______    Date: ______

## 1. Tools
Icarus Verilog __ , GTKWave __ , RISC-V GCC __ , Quartus Prime 18.1 Lite

## 2. Unit test results
| Module | Testbench | What is checked | Result |
|---|---|---|---|
| ALU | tb_alu.v | all 11 ALU operations, wrap-around, signed/unsigned compare, SRA vs SRL | PASS |
| Register file | tb_reg_file.v | write/read, x0 hard-wired, write-enable | PASS |
| Imm. generator | tb_imm_gen.v | I, S, B, U, J immediates, positive and negative | PASS |
| Data memory | tb_data_mem.v | LW/LH/LHU/LB/LBU, SW/SH/SB, byte merging | PASS |
| Control unit | tb_control.v | control word for each opcode, SUB/SRAI/ADDI(neg) | PASS |
| Program counter | tb_pc.v | async reset, counts by 4, loads target, holds between clock edges | PASS |
| Instruction memory | tb_instr_mem.v | words read from hex file, byte offset ignored, unused = NOP | PASS |
| Multiplexers | tb_mux.v | mux2/mux4 every select, parameterised width | PASS |
| Branch comparator | tb_branch_cmp.v | all 6 branch conditions, signed vs unsigned, invalid funct3 | PASS |
| CSR file | tb_csr_file.v | CSRRW/RS/RC semantics, rs1=x0 no-write, trap registers, read-only CSRs, counters, reset | PASS |

## 3. Core test results (tb_core.v)
| Program | Instructions exercised | Expected key results | Result |
|---|---|---|---|
| test_alu | all R/I ALU ops, LUI, AUIPC | x3=2, x4=8, x23=0x1058, x24=0x12345678 ... | PASS |
| test_loop | ADDI, ADD, BNE (backward) | x10=55, x14=20 | PASS |
| test_loadstore | LW LH LHU LB LBU SW SH SB | registers x13=0x5678FFFE, x15=0x00007800 ... AND data memory words 0x40-0x4C checked directly | PASS |
| test_branch | BEQ BNE BLT BLTU BGE BGEU JAL JALR | x10=234, x5=68 | PASS |
| test_system | FENCE, FENCE.I, ECALL, EBREAK, CSRRW/S/C, CSRRWI/SI/CI | x28=0x6C (mepc), x29=11 (mcause), x15=3, x17=2 traps, x19=14, x18=99 | PASS |

(Paste the log from `tb/sim_results.txt`.)

## 3b. Instruction coverage
All 47 instructions are implemented (see `doc/decoding_table.xlsx`): 37 base + FENCE, FENCE.I, ECALL, EBREAK + 6 CSR. Each appears in at least one test program.

## 4. Waveforms (screenshots in tb/waves/)
Add at least: (a) PC counting by 4, (b) an ADD instruction showing rs1/rs2/ALU/write-back,
(c) a taken branch showing PC jump, (d) a store followed by a load.
Explain each in 2-3 sentences (which signals, which cycle, why the value is correct).

## 5. Synthesis (Quartus)
Device, logic utilisation, Fmax (from Timing Analyzer), latch check (none), photo of FPGA demo.
