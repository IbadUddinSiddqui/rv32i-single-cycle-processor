# ---------------------------------------------------------------------------
# Timing constraints for fpga_top
# ---------------------------------------------------------------------------
# 50 MHz board clock
create_clock -name CLOCK_50 -period 20.000 [get_ports CLOCK_50]

# The core runs from divider bits (cnt[24] = slow, cnt[1] = fast).
# Tell the Timing Analyzer about them, otherwise they are "unconstrained clocks".
create_generated_clock -name clk_fast -source [get_ports CLOCK_50] -divide_by 4 \
    [get_registers {cnt[1]}]
create_generated_clock -name clk_slow -source [get_ports CLOCK_50] -divide_by 33554432 \
    [get_registers {cnt[24]}]
# SW[9] selects one or the other, never both at once
set_clock_groups -exclusive -group {clk_fast} -group {clk_slow}

derive_clock_uncertainty

# Push buttons and switches are asynchronous human inputs, LEDs are just indicators
set_false_path -from [get_ports {KEY[*] SW[*]}]
set_false_path -to   [get_ports {LEDR[*]}]
