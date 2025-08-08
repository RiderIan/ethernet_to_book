`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev: Ian Rider
// Purpose: RGMII MAC top level
//////////////////////////////////////////////////////////////////////////////////
`include "rgmii_rx.sv"

module rgmii (
    input  logic       intBIn,
    input  logic       mmcm0LockedIn,
    input  logic       mmcm1LockedIn,

    input  logic       rstRxLclIn,
    input  logic       rxClkIn,
    input  logic [3:0] rxDataIn,
    input  logic       rxCtrlIn,
    output logic [7:0] rxDataOut,
    output logic       rxDataValidOut,
    output logic       rxDataLastOut,

    input  logic       rstTxLclIn,
    input  logic       clk125In,
    output logic [3:0] txDataOut,
    output logic       txCtrlOut);

    // TX side not implemented
    assign txCtrlOut = 1'b0;
    assign txDataOut = 8'h00;

    // RX
    rgmii_rx rx_inst (
        .rstIn(rstRxLclIn),
        .rxClkIn(rxClkIn),
        .rxDataIn(rxDataIn),
        .rxCtrlIn(rxCtrlIn),
        .intBIn(intBIn),
        .mmcmLockedIn(mmcm1LockedIn),
        
        .rxDataOut(rxDataOut),
        .rxDataValidOut(rxDataValidOut),
        .rxDataLastOut(rxDataLastOut));

endmodule