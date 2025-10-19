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
create_generated_clock -name tx_clk_125     -source [get_ports clkIn]   -multiply 5    -divide_by 4              [get_pins clks_rsts_inst/mmcm0_inst/inst/mmcm_adv_inst/CLKOUT0]
create_generated_clock -name tx_clk_125_dly -source [get_ports clkIn]   -edges {1 2 3} -edge_shift {1.5 .5 -.5}  [get_pins clks_rsts_inst/mmcm0_inst/inst/mmcm_adv_inst/CLKOUT1]
create_generated_clock -name clk_250        -source [get_ports clkIn]   -multiply 5    -divide_by 2              [get_pins clks_rsts_inst/mmcm0_inst/inst/mmcm_adv_inst/CLKOUT2]
create_generated_clock -name rx_clk_125_dly -source [get_ports rxClkIn] -edges {1 2 3} -edge_shift {1.5 5.5 9.5} [get_pins clks_rsts_inst/mmcm1_inst/inst/mmcm_adv_inst/CLKOUT0]

###########################################
# CDC constraints
###########################################
# Set max delay to period of faster clk to ensure CDC bits are stable as async fifo method is not being used
set_max_delay 4 -from [get_clocks rx_clk_125_dly] -to [get_clocks clk_250] -datapath_only
# Needed for xilinx xpm afifo
set_false_path  -through [get_cells -hierarchical -filter {NAME =~ "*xpm_fifo_async_inst*" && NAME =~ "*fifo_rd_rst_ic_reg*"}]

###########################################
# Other false paths
###########################################
# Order map is synchronous dual port ram. Input data A to addr B was being timed but this path can be treated as async
set_false_path -from [get_pins order_book_engine_inst/order_map_inst/ref_num_ram/regsR_reg[*][*]/C] -to [get_pins order_book_engine_inst/order_map_inst/addrBR_reg[*]/CE]

###########################################
# Multi-cycle paths
###########################################
set_multicycle_path 2 -setup     -from [get_pins order_book_engine_inst/order_map_inst/shares_out_inst/regsR_reg[1][*]/C]        -to [get_pins order_book_engine_inst/order_book_inst/bSharesDiffR_reg[*][*]/D]
set_multicycle_path 1 -hold -end -from [get_pins order_book_engine_inst/order_map_inst/shares_out_inst/regsR_reg[1][*]/C]        -to [get_pins order_book_engine_inst/order_book_inst/bSharesDiffR_reg[*][*]/D]

set_multicycle_path 2 -setup     -from [get_pins order_book_engine_inst/order_map_inst/shares_out_inst/regsR_reg[1][*]/C]        -to [get_pins order_book_engine_inst/order_book_inst/sSharesDiffR_reg[*][*]/D]
set_multicycle_path 1 -hold -end -from [get_pins order_book_engine_inst/order_map_inst/shares_out_inst/regsR_reg[1][*]/C]        -to [get_pins order_book_engine_inst/order_book_inst/sSharesDiffR_reg[*][*]/D]