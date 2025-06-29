`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Ian Rider
// 
//////////////////////////////////////////////////////////////////////////////////
`include "RGMII_RX.sv"
`include "RGMII_TX.sv"

module RGMII (
    input  logic rstIn,
    input  logic clk125In,
    input  logic rxClkIn,
    input  logic rxDataIn,
    input  logic rxCtrlIn,
    input  logic intBIn,
    input  logic mmcm0LockedIn,
    input  logic mmcm1LockedIn,

    output logic txDataOut,
    output logic txCtrlOut,
    output logic phyRstBOut);

    // TX
    // RGMII_TX tx_inst (
    //     .rstIn(rstIn),
    //     .clk125In(clk125In),
    //     .intBIn(intBIn),
    //     .txDataOut(txDataOut),
    //     .txCtrlOut(txCtrlOut));

    // RX
    RGMII_RX rx_inst (
        .rstIn(rstIn),
        .rxClkIn(rxClkIn),
        .rxDataIn(rxDataIn),
        .rxCtrlIn(rxCtrlIn),
        .intBIn(intBIn),
        .mmcmLockedIn(mmcm1LockedIn));

endmodule