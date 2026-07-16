transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

asim +access +r +m+rx_clk_shift  -L xil_defaultlib -L xpm -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.rx_clk_shift xil_defaultlib.glbl

do {rx_clk_shift.udo}

run 1000ns

endsim

quit -force
