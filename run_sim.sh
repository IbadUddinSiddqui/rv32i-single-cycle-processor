#!/bin/sh
# Run every testbench with Icarus Verilog. Execute from the project root:  sh run_sim.sh
# (fpga_top.v is for Quartus only, so it is left out of simulation)
set -e
RTL=$(ls rtl/*.v | grep -v fpga_top)
mkdir -p build tb/waves
for t in alu reg_file imm_gen data_mem control pc instr_mem mux branch_cmp csr_file; do
    iverilog -g2005 -Wall -o build/tb_$t.vvp tb/tb_$t.v $RTL
    vvp build/tb_$t.vvp
    echo
done
iverilog -g2005 -Wall -o build/tb_core.vvp tb/tb_core.v $RTL
vvp build/tb_core.vvp
