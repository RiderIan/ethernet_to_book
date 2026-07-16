vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/xpm
vlib modelsim_lib/msim/xil_defaultlib

vmap xpm modelsim_lib/msim/xpm
vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib

vlog -work xpm -64 -incr -mfcu  -sv "+incdir+../../../ipstatic" "+incdir+../../../../../../../../tools/xilinx/2025.2/data/rsb/busdef" \
"/home/ian-rider/tools/xilinx/2025.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"/home/ian-rider/tools/xilinx/2025.2/data/ip/xpm/xpm_fifo/hdl/xpm_fifo.sv" \
"/home/ian-rider/tools/xilinx/2025.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -64 -93  \
"/home/ian-rider/tools/xilinx/2025.2/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib -64 -incr -mfcu  "+incdir+../../../ipstatic" "+incdir+../../../../../../../../tools/xilinx/2025.2/data/rsb/busdef" \
"../../../../project.gen/sources_1/ip/system_clocks_gen/system_clocks_gen_clk_wiz.v" \
"../../../../project.gen/sources_1/ip/system_clocks_gen/system_clocks_gen.v" \

vlog -work xil_defaultlib \
"glbl.v"

