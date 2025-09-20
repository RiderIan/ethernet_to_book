##################################################################################
## Dev: Ian Rider
## Purpose: Pin assignments
##################################################################################

# 100Mhz on board clock, rst tied to active high push button "BTNL"
set_property    PACKAGE_PIN R4             [get_ports clkIn]
set_property    PACKAGE_PIN C22            [get_ports rstIn]

# Not implemented
# set_property PACKAGE_PIN Y16  [get_ports mdioBi]
# set_property PACKAGE_PIN AA16 [get_ports mdClkOut]

# RX PHY
set_property    PACKAGE_PIN AB16           [get_ports {rxDataIn[0]}]
set_property    PACKAGE_PIN AA15           [get_ports {rxDataIn[1]}]
set_property    PACKAGE_PIN AB15           [get_ports {rxDataIn[2]}]
set_property    PACKAGE_PIN AB11           [get_ports {rxDataIn[3]}]

set_property    PACKAGE_PIN W10            [get_ports rxCtrlIn]
set_property    PACKAGE_PIN V13            [get_ports rxClkIn]

# TX PHY - not implemented
set_property    PACKAGE_PIN Y12            [get_ports {txDataOut[0]}]
set_property    PACKAGE_PIN W12            [get_ports {txDataOut[1]}]
set_property    PACKAGE_PIN W11            [get_ports {txDataOut[2]}]
set_property    PACKAGE_PIN Y11            [get_ports {txDataOut[3]}]
set_property    PACKAGE_PIN V10            [get_ports txCtrlOut]
set_property    PACKAGE_PIN AA14           [get_ports txClkOut]

# Other PHY signals
set_property    PACKAGE_PIN Y14            [get_ports intBIn]
set_property    PACKAGE_PIN U7             [get_ports phyRstBOut]

# MMCM locked indicated to LED0
set_property    PACKAGE_PIN T14            [get_ports lockedOut]


