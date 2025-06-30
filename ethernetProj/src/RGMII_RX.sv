`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Ian Rider
// 
//////////////////////////////////////////////////////////////////////////////////

module RGMII_RX (
    input logic       rstIn,
    input logic       rxClkIn,
    input logic [3:0] rxDataIn,
    input logic       rxCtrlIn,
    input logic       intBIn,
    input logic       mmcmLockedIn);

    logic ctrlRisingR;
    logic ctrlFallingR;
    logic rxDataValid;
    logic rxDataErr;

    logic [3:0] dataRisingR;
    logic [3:0] dataFallingR;
    logic [7:0] dataR;
    logic       dataValR;
    logic       dataValPrevR;
    logic       dataLast;

    ///////////////////////////////////
    // Decode DDR Data and DDR RX Control
    ///////////////////////////////////
    IDDR rx_ctrl_iddr_inst (
        .Q1(ctrlRisingR),   // rising edge capture
        .Q2(ctrlFallingR),  // falling edge capture
        .C(rxClkIn),        // rx clk (1.5ns delay already induced)
        .CE(mmcmLockedIn),  // indicates delayed clock is stable
        .D(rxCtrlIn),       // data from PHY
        .R(1'b0),           // reset to '1's
        .S(rstIn));         // reset to '0's

    assign rxDataValid = (ctrlRisingR & ctrlFallingR);
    assign rxDataErr   = (ctrlRisingR ^ ctrlFallingR);

    IDDR rx_data_iddr_inst (
        .Q1(dataRisingR),   // rising edge capture
        .Q2(dataFallingR),  // falling edge capture
        .C(rxClkIn),        // rx clk (1.5ns delay already induced)
        .CE(mmcmLockedIn),  // indicates delayed clock is stable
        .D(rxDataIn),       // data from PHY
        .R(1'b0),           // reset to '1's
        .S(rstIn));         // reset to '0's

    ///////////////////////////////////
    // Form MAC Output
    ///////////////////////////////////
    always_ff @(posedge rxClkIn) begin
        if (rstIn) begin
            dataR        <= 8'b0;
            dataValR     <= 1'b0;
            dataValPrevR <= 1'b0;
        end else begin
            // Default assignment
            dataValR     <= 1'b0;
            dataValPrevR <= dataValR;

            // Conditional override
            if (rxDataValid && ~rxDataErr) begin
                dataR    <= {dataRisingR, dataFallingR};
                dataValR <= 1'b1;
            end
        end
    end

    // One clock pulse for last data
    assign dataLast = (!dataValR && dataValPrevR);


endmodule