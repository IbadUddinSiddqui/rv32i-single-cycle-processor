# Quartus Prime 18.x + Cyclone V Guide (RV32I Single-Cycle Core)

> Honest note: the RTL was simulated (Icarus Verilog) and checked for latches (Yosys). The Quartus
> project files were written by hand and were **not** compiled in Quartus by their author. If something
> in Quartus differs from this guide, trust Quartus's messages and the troubleshooting table at the end.
> Pin numbers are for **DE1-SoC / DE10-Standard**; check them against your own board's manual.

---------------------------------------------------------------------------
## 0. What you need
- **Quartus Prime Lite Edition 18.1** (free) with **Cyclone V device support**
- **ModelSim-Intel FPGA Starter Edition** (optional, installed with Quartus; Icarus works too)
- A Cyclone V board + USB cable (USB-Blaster driver installed). Without a board you can still compile,
  check timing and simulate.

---------------------------------------------------------------------------
## 1. Open the ready-made project (fastest)
1. Start Quartus. **File -> Open Project...** and choose `RV32I_SingleCycle/quartus/rv32i.qpf`.
2. In **Project Navigator -> Files** you should see all `../rtl/*.v` files and `rv32i.sdc`.
   Top-level entity = `fpga_top`.
3. Not a DE1-SoC / DE10-Standard? Go to **Assignments -> Device**, select your exact device
   (e.g. `5CEBA4F23C7`), and fix the pin assignments (step 4).

### Or create the project by hand
1. **File -> New Project Wizard**.
2. Working directory: `.../RV32I_SingleCycle/quartus`, project name `rv32i`, top-level entity `fpga_top`.
3. Project type: *Empty project*.
4. Add files: select **all** `.v` files in `rtl/` (including `fpga_top.v`) and `quartus/rv32i.sdc`.
5. Family **Cyclone V**, pick your device from the list (DE1-SoC: `5CSEMA5F31C6`).
6. EDA tool settings: Simulation = ModelSim-Altera (Verilog) -> Finish.

---------------------------------------------------------------------------
## 2. Understand the FPGA wrapper (`rtl/fpga_top.v`)
| Board item | Function |
|---|---|
| `CLOCK_50` | 50 MHz clock |
| `KEY[0]` | **Reset** (buttons are active-low on the board; the wrapper inverts it) |
| `SW[9]` | 0 = slow clock (~1.5 instructions/s, watch it run) / 1 = fast clock (12.5 MHz) |
| `SW[0]` | 0 = LEDs show register **x10 (a0)** / 1 = LEDs show **PC[11:2]** |
| `LEDR[9:0]` | 10 red LEDs |

The program in memory comes from the `INIT_FILE` parameter:
`../sw/compiled_hex/fpga_demo.hex` (an endless counter: x10 = x10 + 1).
The `../` path works because the project lives in `quartus/` (and also resolves from `rtl/`).

---------------------------------------------------------------------------
## 3. Compile
1. **Processing -> Start Compilation** (Ctrl+L). Wait for the four stages
   (Analysis & Synthesis, Fitter, Assembler, Timing Analyzer).
2. Open **Messages** and **Compilation Report -> Flow Summary**.
3. What to look for:
   - **No "inferred latch" messages** in Analysis & Synthesis (this is a rubric item).
   - Warnings you can **ignore**: unused inputs `KEY[3:1]`, `SW[8:1]` (not used by the design).
   - Warnings you should **fix**: "Can't find memory initialization file" (see troubleshooting),
     "Output pins stuck at ..." for LEDs (usually means the program hex failed to load).
4. Memory note: the instruction/data memories and register file use **asynchronous reads**, which the
   M10K block RAMs do not support. Quartus therefore builds them from logic/MLABs, which is fine for a
   1 KB design. Do not enlarge them hugely.

---------------------------------------------------------------------------
## 4. Check pin assignments
1. **Assignments -> Pin Planner**.
2. Confirm each of `CLOCK_50`, `KEY[3:0]`, `SW[9:0]`, `LEDR[9:0]` has a location and I/O standard
   `3.3-V LVTTL`. Compare against your board manual.
3. Edit a pin by double-clicking its **Location** cell. Pin Planner writes the change into `rv32i.qsf`.
4. If you change pins, recompile.

---------------------------------------------------------------------------
## 5. Check timing
1. **Tools -> Timing Analyzer** -> *Update Timing Netlist*, *Read SDC File* (`rv32i.sdc`).
2. **Report Fmax Summary** (Tasks panel). You will see the two derived clocks, `clk_fast` and `clk_slow`.
3. A single-cycle design has a long path: PC -> instruction memory -> register file -> ALU -> data memory
   -> write-back -> register file. Expect a modest Fmax (tens of MHz).
4. If the slack for `clk_fast` (12.5 MHz) is **negative**, use only the slow clock (`SW[9] = 0`), or
   change `cnt[1]` to `cnt[2]` (6.25 MHz) in `fpga_top.v` **and** in the `.sdc`
   (`-divide_by 8`, `{cnt[2]}`).
5. Put the Fmax number and a screenshot in your report (Phase 3 deliverable).

---------------------------------------------------------------------------
## 6. Program the board
1. Connect the board (power on, USB-Blaster cable) and **Tools -> Programmer**.
2. **Hardware Setup...** -> select *USB-Blaster* -> Close. Mode: **JTAG**.
3. Click **Auto Detect** if the chain is empty. DE1-SoC / DE10 show two devices (`SOCVHPS` and the FPGA);
   select the FPGA device row.
4. Make sure the file is `output_files/rv32i.sof`, tick **Program/Configure**, click **Start**.
5. Progress bar should reach 100% (Successful).

### What you should see
- Press **KEY0** once to reset. With `SW[9]=0`, `SW[0]=0` the LEDs count up in binary
  (LEDR0 toggles fastest) about once every 1.3 s (the loop is 2 instructions long at ~1.5 Hz).
- `SW[0]=1`: LEDs show PC[11:2]; the loop alternates between addresses 0x4 and 0x8, so you see
  values 1 and 2 alternating.
- `SW[9]=1`: the counter runs far too fast to see (LEDs look dim/steady).

---------------------------------------------------------------------------
## 7. Run a different program on the board
1. Choose a program: `test_loop.hex`, `test_alu.hex`, `test_loadstore.hex`, `test_branch.hex`, `test_system.hex`
   or your own hex file.
2. Edit `INIT_FILE` in `rtl/fpga_top.v`, e.g. `"../sw/compiled_hex/test_loop.hex"`.
3. **Recompile** and re-program. (The memory image is baked into the bitstream.)
4. Expected LED results (x10, binary on LEDR9..0):
   | Program | x10 | LEDs (LEDR9..LEDR0) |
   |---|---|---|
   | test_loop | 55 | 0000110111 |
   | test_branch | 234 | 0011101010 |
   | test_alu | 80 | 0001010000 |
   | test_loadstore | 0xFFFFFFFE | 1111111110 (only the low 10 bits are shown) |
   | test_system | 0x4E (78) | 0001001110 |
   These programs finish and sit in an infinite loop, so the LEDs hold the final answer.
   With `SW[9]=0` give them a few seconds to finish (about 100 cycles at ~1.5 Hz is more than a minute;
   use `SW[9]=1` to reach the final value instantly).

---------------------------------------------------------------------------
## 8. Simulate from Quartus' ModelSim (optional)
Easiest: use ModelSim directly from the **project root** (so `sw/compiled_hex/...` paths resolve).
1. Start *ModelSim-Intel FPGA Starter Edition*.
2. **File -> Change Directory...** -> `RV32I_SingleCycle` (project root, not `quartus/`).
3. In the Transcript window:
```
vlib work
vlog rtl/mux.v rtl/pc.v rtl/instr_mem.v rtl/reg_file.v rtl/alu.v rtl/branch_cmp.v rtl/imm_gen.v rtl/control.v rtl/data_mem.v rtl/core_top.v tb/tb_core.v
vsim -voptargs=+acc work.tb_core
add wave -r sim:/tb_core/dut/*
run -all
```
4. Expect `##### ALL CORE TESTS PASSED #####` in the transcript, and take waveform screenshots
   into `tb/waves/`.
(Icarus + GTKWave: `sh run_sim.sh` then `gtkwave tb/waves/tb_core.vcd`.)

---------------------------------------------------------------------------
## 9. Getting your report screenshots
- **Compilation Report -> Flow Summary** (device, logic utilisation, registers).
- **Timing Analyzer -> Fmax Summary**.
- **RTL Viewer** (Tools -> Netlist Viewers -> RTL Viewer): top-level block diagram of `core_top`.
- **Photo/video** of the board running the demo.
- Waveforms from GTKWave/ModelSim (ADD, branch taken, store then load).

---------------------------------------------------------------------------
## 10. Troubleshooting
| Symptom | Cause / Fix |
|---|---|
| `Can't open memory initialization file` / `$readmemh` warning | Path is relative. Keep the project in `quartus/`, hex in `../sw/compiled_hex/`, or put an absolute path in `INIT_FILE`. |
| LEDs all off / never change | Press KEY0 (reset). Check SW[9]=0 for slow clock. Check pin assignments. Confirm the hex file really loaded (no warning in Messages). |
| LEDs change but look random | Wrong `SW[0]` selection, or you loaded a program that finished. See section 7. |
| `Error: top-level design entity "fpga_top" is undefined` | `fpga_top.v` missing from the project file list. |
| `Error (10161): object ... is not declared` | A file is missing from the project. Add all `rtl/*.v`. |
| `Critical Warning: Timing requirements not met` | See step 5.4 - use the slow clock or divide the fast clock more. |
| `Warning: No clocks defined / unconstrained clocks` | `rv32i.sdc` is not in the project. Assignments -> Settings -> Timing Analyzer -> add the SDC file. |
| Programmer shows *No Hardware* | Install/repair the USB-Blaster driver, power the board, re-select in Hardware Setup. |
| Programmer shows two devices | Pick the FPGA device row (not `SOCVHPS`). |
| `Inferred latch` message | Some `always @(*)` block misses a default value. All files supplied here have defaults. |
| Different board, wrong pins | Edit the `set_location_assignment` lines in `rv32i.qsf` or use Pin Planner. |

---------------------------------------------------------------------------
## 11. Rubric checklist
- [x] Architecture diagram: `doc/architecture_diagram.pdf` (add a short design-choice paragraph in the report)
- [x] Decode table: `doc/decoding_table.xlsx`
- [x] Modules synthesizable, no latches; unit testbenches in `tb/`
- [x] Core integration + self-checking verification: `tb/tb_core.v`
- [ ] Your waveform screenshots in `tb/waves/` and your `doc/verification_report.pdf`
