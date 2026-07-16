transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

vlib work
vlib riviera/xpm
vlib riviera/xil_defaultlib

vmap xpm riviera/xpm
vmap xil_defaultlib riviera/xil_defaultlib

vlog -work xpm  -incr "+incdir+../../../ipstatic" "+incdir+../../../../../../../../tools/xilinx/2025.2/data/rsb/busdef" -l xpm -l xil_defaultlib \
"/home/ian-rider/tools/xilinx/2025.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"/home/ian-rider/tools/xilinx/2025.2/data/ip/xpm/xpm_fifo/hdl/xpm_fifo.sv" \
"/home/ian-rider/tools/xilinx/2025.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -93  -incr \
"/home/ian-rider/tools/xilinx/2025.2/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib  -incr -v2k5 "+incdir+../../../ipstatic" "+incdir+../../../../../../../../tools/xilinx/2025.2/data/rsb/busdef" -l xpm -l xil_defaultlib \
"../../../../project.gen/sources_1/ip/system_clocks_gen/system_clocks_gen_clk_wiz.v" \
"../../../../project.gen/sources_1/ip/system_clocks_gen/system_clocks_gen.v" \

vlog -work xil_defaultlib \
"glbl.v"

