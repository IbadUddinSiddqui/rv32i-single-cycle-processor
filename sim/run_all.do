# ---------------------------------------------------------------------------
# ModelSim: compile and run ALL testbenches.
# In the ModelSim Transcript window:
#     cd C:/path/to/RV32I_SingleCycle        (project ROOT, no spaces in path)
#     do sim/run_all.do
# ---------------------------------------------------------------------------
transcript on
catch {quit -sim}
catch {vdel -lib work -all}
vlib work
vmap work work

vlog -work work rtl/mux.v rtl/pc.v rtl/instr_mem.v rtl/reg_file.v rtl/alu.v rtl/branch_cmp.v rtl/imm_gen.v rtl/control.v rtl/csr_file.v rtl/data_mem.v rtl/core_top.v tb/tb_alu.v tb/tb_reg_file.v tb/tb_imm_gen.v tb/tb_data_mem.v tb/tb_control.v tb/tb_pc.v tb/tb_instr_mem.v tb/tb_mux.v tb/tb_branch_cmp.v tb/tb_csr_file.v tb/tb_core.v

foreach t {alu reg_file imm_gen data_mem control pc instr_mem mux branch_cmp csr_file core} {
    echo "==================== tb_$t ===================="
    vsim -voptargs=+acc work.tb_$t
    onfinish stop
    run -all
    quit -sim
}
echo "Finished. Expect: ALL TESTS PASSED x10, then ALL CORE TESTS PASSED."
