# RV32I Single-Cycle Processor (Verilog)

A complete single-cycle RISC-V **RV32I** core in Verilog-2001, covering all **47**
instructions (37 base integer + FENCE/FENCE.I + ECALL/EBREAK + 6 Zicsr CSR
instructions), with unit testbenches, a self-checking core testbench, assembly
test programs and a Quartus Prime 18 project for Cyclone V.

## Repository layout

```
rtl/       12 synthesisable files (pc, imem, reg_file, alu, imm_gen, control,
           dmem, mux, branch_cmp, csr_file, core_top, fpga_top)
tb/        10 unit testbenches + tb_core.v (5 self-checking programs)
sw/        assembly tests, bin2hex.py, pre-built .hex images
sim/       ModelSim run_all.do / wave_core.do
quartus/   rv32i.qpf, .qsf, .sdc
doc/       architecture diagram, decoding table, Quartus guide
run_sim.sh runs every testbench with Icarus Verilog
```

## Quick start

```sh
sh run_sim.sh                  # compile + run all testbenches
gtkwave tb/waves/tb_core.vcd   # inspect waveforms
```

Expected final line: `##### ALL CORE TESTS PASSED #####`.

To build a program, add a `.S` file under `sw/asm_tests/`, run `sh sw/build.sh`
(requires a RISC-V GCC toolchain), and point `INIT_FILE` in `tb/tb_core.v` at the
new hex file.

## Design summary

| Item | Choice |
|---|---|
| Datapath | single cycle, Harvard (separate I/D memories) |
| Instruction memory | 256 words (`IMEM_DEPTH`), async read, `$readmemh` |
| Data memory | 1 KB (`DMEM_DEPTH`), byte enables, async read, sync write |
| Register file | 32 x 32, 2 async read ports, 1 sync write, x0 hard-wired to 0 |
| Next PC | `jalr` uses `(rs1+imm)&~1`; branch/jal use `PC+imm`; else `PC+4` |
| Reset | active-high, asynchronous (PC only) |
| CSRs | mstatus, misa, mtvec, mscratch, mepc, mcause, cycle(h), instret(h), mhartid |

## Verification status

- All 10 unit testbenches and all 5 core programs pass in Icarus Verilog.
- Yosys synthesis check of the full core reports 0 inferred latches.
- The Quartus project has **not** been compiled, timed or run on hardware here;
  follow `doc/quartus_guide.md` and check pin assignments against your board.

## Known limitations

- Machine mode only; no interrupts, no MRET/WFI (decoded as NOP).
- Writes to read-only or unknown CSRs are ignored instead of trapping.
- Misaligned loads/stores are not handled; memory addresses wrap at their size.
- Programs terminate by looping on themselves; the testbench runs a fixed cycle count.

## Documentation

- `doc/architecture_diagram.pdf` — datapath and control block diagram
- `doc/decoding_table.xlsx` — instruction to control-signal mapping
- `doc/quartus_guide.md` — Quartus 18 / Cyclone V build steps
