`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev: Ian Rider
// Purpose: Top level architecture
//////////////////////////////////////////////////////////////////////////////////
`include "rgmii.sv"
`include "clks_rsts.sv"
`include "eth_udp_parser.sv"

module ethernet_to_book_top (

    input  logic        clkIn,
    input  logic        rstIn,
    //inout  logic       mdioBi,
    //output logic       mdClkOut,

    input  logic [3:0]  rxDataIn,
    input  logic        rxCtrlIn,
    input  logic        rxClkIn,

    output logic [3:0]  txDataOut,
    output logic        txCtrlOut,
    output logic        txClkOut,

    output logic        itchDataValidOut, // temp
    output logic [7:0 ] itchDataOut,      // temp
    output logic        packetLostOut,    // temp

    output logic        addValidOut,      // temp
    output logic        delValidOut,      // temp
    output logic        execValidOut,     // temp
    output logic [63:0] refNumOut,        // temp
    output logic [15:0] locateOut,        // temp
    output logic [31:0] priceOut,         // temp
    output logic [63:0] sharesOut,        // temp
    output logic        buySellOut,       // temp

    input  logic        intBIn,
    output logic        phyRstBOut,
    output logic        lockedOut);

    // Signals
    logic        rstTxLcl,    rstTx,       rst250, rstRxLcl;
    logic        txClkLcl,    rxClkLcl,    clk250;
    logic        mmcm0Locked, mmcm1Locked;
    logic [ 7:0] rxData,      rx250Data, itchData;
    logic        rxDataValid, rdDataValid, itchValid, packetLost, addValid, delValid, execValid, buySell;
    logic [15:0] locate;
    logic [31:0] price;
    logic [63:0] refNum, shares;

    ////////////////////////////////////////////
    // Clocks and Resets
    ////////////////////////////////////////////
    clks_rsts clks_rsts_inst (
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

    ////////////////////////////////////////////
    // RGMII
    ////////////////////////////////////////////
    rgmii mac_inst (
        .intBIn(intBIn),
        .mmcm0LockedIn(mmcm0Locked),
        .mmcm1LockedIn(mmcm1Locked),

        .rstRxLclIn(rstRxLcl),
        .rxClkIn(rxClkLcl),
        .rxDataIn(rxDataIn),
        .rxCtrlIn(rxCtrlIn),
        .rxDataOut(rxData),
        .rxDataValidOut(rxDataValid),

        .rstTxLclIn(rstTxLcl),
        .clk125In(txClkLcl),
        .txDataOut(txDataOut),
        .txCtrlOut(txCtrlOut));

    ////////////////////////////////////////////
    // CDC slow (125MHz) -> fast (250MHz+)
    ////////////////////////////////////////////
    slow_fast_cdc #(
        .LOW_LAT_CDC(1'b1))
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
    eth_udp_parser eth_udp_parser_inst (
        .rstIn(rst250),
        .clkIn(clk250),
        .dataIn(rx250Data),
        .dataValidIn(rdDataValid),
        .itchDataValidOut(itchValid),
        .itchDataOut(itchData),
        .packetLostOut(packetLost));

    assign packetLostOut = packetLost;

    itch_parser itch_parser_inst (
        .rstIn(rst250),
        .clkIn(clk250),
        .dataIn(itchData),
        .dataValidIn(itchValid),
        .packetLostIn(packetLost),
        .addValidOut(addValid),
        .delValidOut(delValid),
        .execValidOut(execValid),
        .refNumOut(refNum),
        .locateOut(locate),
        .priceOut(price),
        .sharesOut(shares),
        .buySellOut(buySell));

    ////////////////////////////////////////////
    // Outputs
    ////////////////////////////////////////////
    assign phyRstBOut       = rstTx; // may want more logic driving this
    assign lockedOut        = mmcm0Locked & mmcm1Locked;

    // Temporary to prevent synth optimization and for full system sims
    assign itchDataValidOut = itchValid;
    assign itchDataOut      = itchData;
    assign addValidOut      = addValid;
    assign delValidOut      = delValid;
    assign execValidOut     = execValid;
    assign refNumOut        = refNum;
    assign locateOut        = locate;
    assign priceOut         = price;
    assign sharesOut        = shares;
    assign buySellOut       = buySell;

endmodule
