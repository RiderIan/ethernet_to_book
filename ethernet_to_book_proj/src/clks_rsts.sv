`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev: Ian Rider
// Purpose: Generate local clocks with 100Mhz board clock and 125Mhz PHY rxClk
//////////////////////////////////////////////////////////////////////////////////
module clks_rsts(
    input  logic rstIn,
    input  logic clkIn,
    input  logic rxClkIn,
    output logic rstTxLclOut,
    output logic rstTxOut,
    output logic rst250Out,
    output logic rstRxLclOut,
    output logic txClkLclOut,
    output logic txClkOut,
    output logic clk250Out,
    output logic rxClkLclOut,
    output logic mmcm0LockedOut,
    output logic mmcm1LockedOut);

    // Signals
    logic clkLcl,txClkLcl, txClk, clk250, rxClkLcl, rstLcl, rstLclSync;

    /////////////////////////////////
    // Clocks and Resets
    /////////////////////////////////
    BUFG bufg_clk_inst (
        .I(clkIn),
        .O(clkLcl));

    assign rstLcl = rstIn;

    // System clock domain
    synchronizer_ff #(.DEPTH(3)) sync_rst_lcl_inst    (.rstIn(1'b0), .clkIn(clkLcl),   .DIn(rstLcl), .QOut(rstLclSync));

    // Tx local domain
    synchronizer_ff #(.DEPTH(3)) sync_tx_lcl_rst_inst (.rstIn(1'b0), .clkIn(txClkLcl), .DIn(rstLcl), .QOut(rstTxLclOut));

    // Tx output clock domain
    synchronizer_ff #(.DEPTH(3)) sync_tx_rst_inst     (.rstIn(1'b0), .clkIn(txClk),    .DIn(rstLcl), .QOut(rstTxOut));

    // 250Mhz local domain
    synchronizer_ff #(.DEPTH(3)) sync_250_rst_inst    (.rstIn(1'b0), .clkIn(clk250),   .DIn(rstLcl), .QOut(rst250Out));

    // Rx local domain
    synchronizer_ff #(.DEPTH(3)) sync_rx_rst_inst     (.rstIn(1'b0), .clkIn(rxClkLcl), .DIn(rstLcl), .QOut(rstRxLclOut));

    system_clocks_gen mmcm0_inst (
        .clk_out1(txClkLcl),          // Local 125Mhz for RGMII
        .clk_out2(txClk),             // 125Mhz clock delayed by 1.5ns for PHY tx clock
        .clk_out3(clk250),            // 250Mhz system clock for parsers/book builder
        .reset(rstLclSync),           // reset
        .locked(mmcm0LockedOut),      // Indicated ouput clocks are locked/valid
        .clk_in1(clkIn));             // 100Mhz reference clock

    rx_clk_shift mmcm1_inst (
        .clk_out1(rxClkLcl),          // 125Mhz clock delayed for mgii rx logic
        .reset(rstLclSync),           // reset
        .locked(mmcm1LockedOut),      // Indicated ouput clock is locked/valid
        .clk_in1(rxClkIn));           // 125 MHz reference clock provided by PHY

    // Clock outputs
    assign txClkLclOut = txClkLcl;
    assign txClkOut    = txClk;
    assign clk250Out   = clk250;
    assign rxClkLclOut = rxClkLcl;

endmodule