###########################################
# Dev: Ian Rider
# Purpose: Timing constraints
###########################################

# System Clock
create_clock -period 10 -name system_clock [get_ports clkIn]
create_clock -period 8  -name rx_clk_125   [get_ports rxClkIn]

# Generated Clocks
#create_generated_clock -name tx_clk_125     -source system_clock   -mulitply_by 5 -divide_by 4          [get_pins mmcm0_inst/inst/mmcm_adv_inst/CLKOUT0]
#create_generated_clock -name tx_clk_125_dly -source system_clock   -mulitply_by 5 -divide_by 4 -add 1.5 [get_pins mmcm0_inst/inst/mmcm_adv_inst/CLKOUT1]
#create_generated_clock -name clk_250        -source system_clock   -mulitply_by 5 -divide_by 4          [get_pins mmcm0_inst/inst/mmcm_adv_inst/CLKOUT2]

#create_generated_clock -name rx_clk_125_dly -source rx_clk_125                                 -add 1.5 [get_pins mmcm1_inst/inst/mmcm_adv_inst/CLKOUT0]
