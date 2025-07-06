###########################################
# Dev: Ian Rider
# Purpose: Timing constraints
###########################################

# System Clock
create_clock -period 10 -name system_clock [get_ports clkIn]
create_clock -period 8  -name rx_clk_125   [get_ports rxClkIn]

# Generated Clocks
create_generated_clock -name tx_clk_125     -source [get_port clkIn]   -multiply 5      -divide_by 4                [get_pins clks_rsts_inst/mmcm0_inst/inst/mmcm_adv_inst/CLKOUT0]
create_generated_clock -name tx_clk_125_dly -source [get_port clkIn]   -edges {1, 2, 3} -edge_shift {1.5, .5, -.5}  [get_pins clks_rsts_inst/mmcm0_inst/inst/mmcm_adv_inst/CLKOUT1]
create_generated_clock -name clk_250        -source [get_port clkIn]   -multiply 5      -divide_by 2                [get_pins clks_rsts_inst/mmcm0_inst/inst/mmcm_adv_inst/CLKOUT2]
create_generated_clock -name rx_clk_125_dly -source [get_port rxClkIn] -edges {1, 2, 3} -edge_shift {1.5, 5.5, 9.5} [get_pins clks_rsts_inst/mmcm1_inst/inst/mmcm_adv_inst/CLKOUT0]

# False paths
set_false_path -to   [get_ports {*Out}]
set_false_path -from [get_ports {*In}]
set_false_path -to   [get_ports {*Bi}]
set_false_path -from [get_ports {*Bi}]

# CDCs
set_max_delay 4 -from [get_clocks rx_clk_125_dly] -to [get_clocks clk_250] -data_path_only