`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Ian Rider
// 
//////////////////////////////////////////////////////////////////////////////////
`include "rgmii.sv"
`include "clks_rsts.sv"
`include "pkg.sv"

module ethernet_to_book_top (

    input  logic       clkIn,
    input  logic       rstIn,
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
    logic       rstTxLcl;    
    logic       rstTx;
    logic       rst250;
    logic       rstRxLcl;
    logic       txClkLcl;
    logic       rxClkLcl;
    logic       clk250;
    logic       mmcm0Locked; 
    logic       mmcm1Locked;

    logic [7:0] rxData;
    logic       rxDataValid;
    logic       rxDataLast;

    logic       rx250Data;
    logic       rdDataValid;

    ////////////////////////////////////////////
    // Clocks and Resets
    ////////////////////////////////////////////
    (* keep_hierarchy = "yes" *) clks_rsts clks_rsts_inst (
        .rstIn(rstIn),
        .clkIn(clkIn),
        .rxClkIn(rxClkIn),
        .rstTxLclOut(rstTxLcl),
        .rstTxOut(rstTx),
        .rst250Out(rst250),
        .rstRxLclOut(rstRxLcl),
        .txClkLclOut(txClkLcl),
        .txClkOut(txClkOut),
        .clk250Out(clk250),
        .rxClkLclOut(rxClkLcl),
        .mmcm0LockedOut(mmcm0Locked),
        .mmcm1LockedOut(mmcm1Locked));

    assign phyRstBOut = rstTx; // may want more logic driving this

    ////////////////////////////////////////////
    // RGMII
    ////////////////////////////////////////////
    (* keep_hierarchy = "yes" *) rgmii mac_inst (
        .intBIn(intBIn),
        .mmcm0LockedIn(mmcm0Locked),
        .mmcm1LockedIn(mmcm1Locked),

        .rstRxLclIn(rstRxLcl),
        .rxClkIn(rxClkLcl),
        .rxDataIn(rxDataIn),
        .rxCtrlIn(rxCtrlIn),
        .rxDataOut(rxData),
        .rxDataValidOut(rxDataValid),
        .rxDataLastOut(rxDataLast),

        .rstTxLclIn(rstTxLcl),
        .clk125In(txClkLcl),
        .txDataOut(txDataOut),
        .txCtrlOut(txCtrlOut));

    ////////////////////////////////////////////
    // rxClkLcl(125Mhz) -> 250Mhz CDC
    ////////////////////////////////////////////
    (* keep_hierarchy = "yes" *) fifo_cdc #(
        .XPERIMENTAL_LOW_LAT_CDC(1'b1))
    slow_fast_cdc_inst (
        .wrRstIn(rstRxLcl),        
        .wrClkIn(rxClkLcl),
        .wrEnIn(rxDataValid),
        .wrDataIn(rxData),
        .rdRstIn(rst250),
        .rdClkIn(clk250),
        .rdDataOut(rx250Data),
        .rdDataValidOut(rdDataValid));

    ////////////////////////////////////////////
    // Ethernet/IP/UDP/MoldUdp64 header parser
    ////////////////////////////////////////////
    

endmodule
