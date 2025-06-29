`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Ian Rider
// 
//////////////////////////////////////////////////////////////////////////////////

module RGMII_RX (
    input logic rstIn,
    input logic rxClkIn,
    input logic rxDataIn,
    input logic rxCtrlIn,
    input logic intBIn,
    input logic mmcmLockedIn);

    logic ctrlRisingR;
    logic ctrlFallingR;
    logic rxDataValid;
    logic rxDataErr;

    logic dataRisingR;
    logic dataFallingR;

    /////////////////////////////////
    // Decode RX Control
    /////////////////////////////////
    IDDR #(
        .SRTYPE("ASYNC")    // reset is asynchronous
    ) rx_ctrl_iddr_inst (
        .Q1(ctrlRisingR),   // rising edge capture
        .Q2(ctrlFallingR),  // falling edge capture
        .C(rxClkIn),        // rx clk (1.5ns delay already induced)
        .CE(mcmmLockedIn),  // indicates delayed clock is stable
        .D(rxCtrlIn),       // data from PHY
        .R(1'b0),           // reset to '1's
        .S(rstIn));         // reset to '0's

    assign rxDataValid = (ctrlRisingR & ctrlFallingR);
    assign rxDataErr   = (ctrlRisingR ^ ctrlFallingR);

    /////////////////////////////////
    // Data
    /////////////////////////////////
    IDDR #(
        .SRTYPE("ASYNC")    // reset is asynchronous
    ) rx_data_iddr_inst (
        .Q1(dataRisingR),   // rising edge capture
        .Q2(dataFallingR),  // falling edge capture
        .C(rxClkIn),        // rx clk (1.5ns delay already induced)
        .CE(mcmmLockedIn),  // indicates delayed clock is stable
        .D(rxDataIn),       // data from PHY
        .R(1'b0),           // reset to '1's
        .S(rstIn));         // reset to '0's
    

endmodule