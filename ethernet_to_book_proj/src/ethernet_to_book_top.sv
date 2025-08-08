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

    output logic        itchDataValidOut,
    output logic [7:0 ] itchDataOut,

    input  logic        intBIn,
    output logic        phyRstBOut);

    // Signals
    logic       rstTxLcl,    rstTx,       rst250, rstRxLcl;    
    logic       txClkLcl,    rxClkLcl,    clk250;
    logic       mmcm0Locked, mmcm1Locked; 
    logic [7:0] rxData,      rx250Data, itchData;
    logic       rxDataValid, rdDataValid, rdDataErr, itchValid;

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

    assign phyRstBOut = rstTx; // may want more logic driving this

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
        .XPERIMENTAL_LOW_LAT_CDC(1'b1))
    slow_fast_cdc_inst (
        .wrRstIn(rstRxLcl),        
        .wrClkIn(rxClkLcl),
        .wrEnIn(rxDataValid),
        .wrDataIn(rxData),
        .rdRstIn(rst250),
        .rdClkIn(clk250),
        .rdDataOut(rx250Data),
        .rdDataValidOut(rdDataValid),
        .rdDataErrOut(rdDataErr));

    ////////////////////////////////////////////
    // Ethernet/IP/UDP/MoldUdp64 header parser
    ////////////////////////////////////////////
    eth_udp_parser eth_udp_parser_inst (
        .rstIn(rst250),
        .clkIn(clk250),
        .dataIn(rx250Data),
        .dataValidIn(rdDataValid),
        .dataErrIn(rdDataErr),
        .itchDataValidOut(itchValid),
        .itchDataOut(itchData));

    // Temporary to prevent synth optimization
    assign itchDataValidOut = itchValid;
    assign itchDataOut      = itchData;

    

endmodule
