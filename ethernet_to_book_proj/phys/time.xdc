#####################################################################
# Dev: Ian Rider
# Purpose: Timing constraints
#####################################################################

###########################################
# Clock inputs
###########################################
create_clock -period 10 -name system_clock [get_ports clkIn]
create_clock -period 8  -name rx_clk_125   [get_ports rxClkIn]

###########################################
# Generated clocks
###########################################
create_generated_clock -name tx_clk_125     -source [get_ports clkIn]   -multiply 5      -divide_by 4                [get_pins clks_rsts_inst/mmcm0_inst/inst/mmcm_adv_inst/CLKOUT0]
create_generated_clock -name tx_clk_125_dly -source [get_ports clkIn]   -edges {1 2 3} -edge_shift {1.5 .5 -.5}  [get_pins clks_rsts_inst/mmcm0_inst/inst/mmcm_adv_inst/CLKOUT1]
create_generated_clock -name clk_250        -source [get_ports clkIn]   -multiply 5      -divide_by 2                [get_pins clks_rsts_inst/mmcm0_inst/inst/mmcm_adv_inst/CLKOUT2]
create_generated_clock -name rx_clk_125_dly -source [get_ports rxClkIn] -edges {1 2 3} -edge_shift {1.5 5.5 9.5} [get_pins clks_rsts_inst/mmcm1_inst/inst/mmcm_adv_inst/CLKOUT0]

###########################################
# CDC constraints
###########################################
# Set max delay to period of faster clk to ensure CDC bits are stable as async fifo method is not being used
set_max_delay 4 -from [get_clocks rx_clk_125_dly] -to [get_clocks clk_250] -datapath_only
# May need for async fifo method:
# set_false_path  -through [get_cells -hierarchical -filter {NAME =~ "*xpm_fifo_async_inst*" && NAME =~ "*fifo_rd_rst_ic_reg*"}]
