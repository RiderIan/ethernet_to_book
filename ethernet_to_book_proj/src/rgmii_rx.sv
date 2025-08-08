`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev: Ian Rider
// Purpose: RX side RGMII MAC
//////////////////////////////////////////////////////////////////////////////////

module rgmii_rx (
    input  logic       rstIn,
    input  logic       rxClkIn,
    input  logic [3:0] rxDataIn,
    input  logic       rxCtrlIn,
    input  logic       intBIn,
    input  logic       mmcmLockedIn,
    
    output logic [7:0] rxDataOut,
    output logic       rxDataValidOut,
    output logic       rxDataLastOut); // unused

    logic ctrlRising;
    logic ctrlFalling;
    logic rxDataValidR;
    logic rxDataErrR;

    logic [3:0] dataRising;
    logic [3:0] dataFalling;
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
        .Q1(ctrlRising),      // rising edge capture
        .Q2(ctrlFalling),     // falling edge capture
        .C(rxClkIn),          // rx clk (1.5ns delay already induced)
        .CE(mmcmLockedIn),    // indicates delayed clock is stable
        .D(rxCtrlIn),         // data from PHY
        .R(1'b0),             // reset to '1's
        .S(rstIn));           // reset to '0's

    always_ff @(posedge rxClkIn) begin
        if (rstIn) begin
            rxDataValidR <= 1'b0;
            rxDataErrR   <= 1'b0;
        end else begin
            rxDataValidR <= (ctrlRising & ctrlFalling);
            rxDataErrR   <= (ctrlRising ^ ctrlFalling);
        end
    end

    genvar i;
    generate for (i = 0; i < 4; i++) begin
        IDDR rx_data_iddr_inst (
            .Q1(dataRising[i]),    // rising edge capture
            .Q2(dataFalling[i]),   // falling edge capture
            .C(rxClkIn),           // rx clk (1.5ns delay already induced)
            .CE(mmcmLockedIn),     // indicates delayed clock is stable
            .D(rxDataIn[i]),       // data from PHY
            .R(1'b0),              // reset to '1's
            .S(rstIn));            // reset to '0's
        end
    endgenerate

    ///////////////////////////////////
    // Form MAC Output
    ///////////////////////////////////
    always_ff @(posedge rxClkIn) begin
        if (rstIn) begin
            dataR        <= 8'b0;
            dataValR     <= 1'b0;
            dataValPrevR <= 1'b0;
            dataRisingR  <= 4'b0;
            dataFallingR <= 4'b0;
        end else begin
            // Default assignment
            dataValR     <= 1'b0;
            dataValPrevR <= dataValR;
            dataRisingR  <= dataRising;
            dataFallingR <= dataFalling;

            // Conditional override
            if (rxDataValidR && ~rxDataErrR) begin
                dataR    <= {dataRisingR, dataFallingR};
                dataValR <= 1'b1;
            end
        end
    end

    // Outputs
    assign rxDataOut      = dataR;
    assign rxDataValidOut = dataValR;
    assign rxDataLastOut  = (!dataValR && dataValPrevR);


endmodule