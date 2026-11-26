# ---------------------------------------------------------------------------
# ModelSim: run the full-core testbench with a ready-made waveform window.
#     cd C:/path/to/RV32I_SingleCycle
#     do sim/wave_core.do
# tb_core runs 4 programs back to back (simulation time):
#     test_alu        0 ns -  ~620 ns
#     test_loop     ~620 ns - ~1640 ns
#     test_loadstore ~1640 ns - ~2060 ns
#     test_branch   ~2060 ns - ~2580 ns   (test_system follows, ~2580 ns - ~3860 ns)
# Use "wave zoom range 20ns 200ns" etc. to look closely, then take screenshots.
# ---------------------------------------------------------------------------
transcript on
catch {quit -sim}
catch {vdel -lib work -all}
vlib work
vmap work work
vlog -work work rtl/mux.v rtl/pc.v rtl/instr_mem.v rtl/reg_file.v rtl/alu.v rtl/branch_cmp.v rtl/imm_gen.v rtl/control.v rtl/csr_file.v rtl/data_mem.v rtl/core_top.v tb/tb_core.v

vsim -voptargs=+acc work.tb_core
onfinish stop

add wave -divider {Clock / reset}
add wave /tb_core/clk
add wave /tb_core/reset
add wave -divider {Fetch}
add wave -radix hexadecimal /tb_core/dut/pc
add wave -radix hexadecimal /tb_core/dut/pc_next
add wave -radix hexadecimal /tb_core/dut/instr
add wave -divider {Decode}
add wave -radix hexadecimal /tb_core/dut/opcode
add wave -radix unsigned    /tb_core/dut/rs1
add wave -radix unsigned    /tb_core/dut/rs2
add wave -radix unsigned    /tb_core/dut/rd
add wave -radix hexadecimal /tb_core/dut/imm
add wave -radix hexadecimal /tb_core/dut/rs1_data
add wave -radix hexadecimal /tb_core/dut/rs2_data
add wave -divider {Control}
add wave /tb_core/dut/reg_write
add wave /tb_core/dut/mem_write
add wave /tb_core/dut/branch
add wave /tb_core/dut/br_taken
add wave /tb_core/dut/jal
add wave /tb_core/dut/jalr
add wave -radix unsigned /tb_core/dut/alu_ctrl
add wave -radix unsigned /tb_core/dut/wb_sel
add wave -divider {Execute / memory / write-back}
add wave -radix hexadecimal /tb_core/dut/alu_result
add wave -radix hexadecimal /tb_core/dut/mem_rdata
add wave -radix hexadecimal /tb_core/dut/wb_data
add wave -divider {CSR / trap}
add wave /tb_core/dut/trap
add wave -radix hexadecimal /tb_core/dut/mtvec
add wave -radix hexadecimal /tb_core/dut/csr_rdata
add wave -divider {Registers}
catch {add wave -radix hexadecimal /tb_core/dut/u_rf/regs}

run -all
wave zoom full
echo "Done. Zoom with:  wave zoom range 20ns 200ns"
