`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Ian Rider
// 
//////////////////////////////////////////////////////////////////////////////////
`include "rgmii_rx.sv"
`include "rgmii_tx.sv"

module rgmii (
    input  logic       rstIn,
    input  logic       intBIn,
    input  logic       mmcm0LockedIn,
    input  logic       mmcm1LockedIn,

    input  logic       rxClkIn,
    input  logic       rxDataIn,
    input  logic       rxCtrlIn,
    output logic [7:0] rxDataOut,
    output logic       rxDataValidOut,
    output logic       rxDataLastOut,

    input  logic       clk125In,
    output logic       txDataOut,
    output logic       txCtrlOut,
    output logic       phyRstBOut);

    // TX
    // rgmii_tx tx_inst (
    //     .rstIn(rstIn),
    //     .clk125In(clk125In),
    //     .intBIn(intBIn),
    //     .txDataOut(txDataOut),
    //     .txCtrlOut(txCtrlOut));

    // RX
    rgmii_rx rx_inst (
        .rstIn(rstIn),
        .rxClkIn(rxClkIn),
        .rxDataIn(rxDataIn),
        .rxCtrlIn(rxCtrlIn),
        .intBIn(intBIn),
        .mmcmLockedIn(mmcm1LockedIn),
        
        .rxDataOut(rxDataOut),
        .rxDataValidOut(rxDataValidOut),
        .rxDataLastOut(rxDataLastOut));

endmodule