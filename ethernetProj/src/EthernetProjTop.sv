`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Ian Rider
// 
//////////////////////////////////////////////////////////////////////////////////
`include "RGMII.sv"
`include "CLKS_RSTS.sv"

module EthernetProjTop (

    input    logic     clkIn,
    input    logic     rstIn,
    //inout  logic       mdioBi,
    //output logic       mdClkOut,

    input  logic [3:0] rxDataIn,    
    input  logic       rxCtrlIn,
    input  logic       rxClkIn,

    output logic [3:0] txDataOut,
    output logic       txCtrlOut,
    output logic       txClkOut,

    input  logic       intBIn,
    output logic       phyRstBOut);

    // Signals
    logic clkLcl;
    logic rstLcl;
    logic clk125Tx;
    logic clk125Rx;
    logic clk250;
    logic mmcm0Locked; 
    logic mmcm1Locked;

    /////////////////////////////////
    // Clocks and Resets
    /////////////////////////////////
    CLKS_RSTS clks_rsts_inst (
        .rstIn(rstIn),
        .clkIn(clkIn),
        .rxClkIn(rxClkIn),
        .rstLclOut(rstLcl),
        .clkLclOut(clkLcl),
        .clk125TxOut(clk125Tx),
        .txClkOut(txClkOut),
        .clk250Out(clk250),
        .clk125RxOut(clk125Rx),
        .mmcm0LockedOut(mmcm0Locked),
        .mmcm1LockedOut(mmcm1Locked));

    /////////////////////////////////
    // RGMII
    /////////////////////////////////
    RGMII mac_inst (
        .rstIn(rstLcl),
        .clk125In(clk125Tx),
        .rxClkIn(clk125Rx),
        .rxCtrlIn(rxCtrlIn),
        .intBIn(intBIn),
        .mmcm0LockedIn(mmcm0Locked),
        .mmcm1LockedIn(mmcm1Locked),

        .txDataOut(txDataOut),
        .txCtrlOut(txCtrlOut),
        .phyRstBOut(phyRstBOut));

endmodule
