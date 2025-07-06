`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Ian Rider
// 
//////////////////////////////////////////////////////////////////////////////////
`include "rgmii.sv"
`include "clks_rsts.sv"

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
    logic       rstLcl;
    logic       txClkLcl;
    logic       rxClkLcl;
    logic       clk250;
    logic       mmcm0Locked; 
    logic       mmcm1Locked;

    logic [7:0] rxData;
    logic       rxDataValid;
    logic       rxDataLast;

    ////////////////////////////////////////////
    // Clocks and Resets
    ////////////////////////////////////////////
    clks_rsts clks_rsts_inst (
        .rstIn(rstIn),
        .clkIn(clkIn),
        .rxClkIn(rxClkIn),
        .rstLclOut(rstLcl),
        .txClkLclOut(txClkLcl),
        .txClkOut(txClkOut),
        .clk250Out(clk250),
        .rxClkLclOut(rxClkLcl),
        .mmcm0LockedOut(mmcm0Locked),
        .mmcm1LockedOut(mmcm1Locked));

    assign phyRstBOut = rstLcl; // may want more logic driving this

    ////////////////////////////////////////////
    // RGMII
    ////////////////////////////////////////////
    rgmii mac_inst (
        .rstIn(rstLcl),
        .intBIn(intBIn),
        .mmcm0LockedIn(mmcm0Locked),
        .mmcm1LockedIn(mmcm1Locked),

        .rxClkIn(rxClkLcl),
        .rxCtrlIn(rxCtrlIn),
        .rxDataOut(rxData),
        .rxDataValidOut(rxDataValid),
        .rxDataLastOut(rxDataLast),

        .clk125In(txClkLcl),
        .txDataOut(txDataOut),
        .txCtrlOut(txCtrlOut),
        .phyRstBOut(phyRstBOut));

    ////////////////////////////////////////////
    // rxClkLcl(125Mhz) -> 250Mhz CDC
    ////////////////////////////////////////////

    ////////////////////////////////////////////
    // Ethernet/IP/UDP/MoldUdp64 header parser
    ////////////////////////////////////////////
    // udp_parser udp_inst (
    //     .rstIn(rstLcl),
    //     .clkIn(clk250),
    //     .rxDataIn()
    //     .rxDataValidIn,
    //     .rxDataLastIn,
    //     .itchDataOut,
    //     .itchMsgLenOut
    // )

endmodule
