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
    logic clkLcl;
    logic txClkLcl;
    logic txClk;
    logic clk250;
    logic rxClkLcl;
    logic rstLcl;
    logic rstLclSync;
    logic rstR;
    logic rstRR;
    logic rstTxLclR;
    logic rstTxLclRR;
    logic rstTxR;
    logic rstTxRR;
    logic rst250R;
    logic rst250RR;
    logic rstRxLclR;
    logic rstRxLclRR;

    /////////////////////////////////
    // Clocks and Resets
    /////////////////////////////////
    BUFG bufg_clk_inst (
        .I(clkIn),
        .O(clkLcl));

    BUFG bufg_rst_inst (
        .I(rstIn),
        .O(rstLcl));

    // System clock domain
    always_ff @(posedge clkLcl) begin : sys_reset_sync
        rstR        <= rstLcl;
        rstRR       <= rstR;
        rstLclSync  <= rstRR;
    end

    // Tx local domain
    always_ff @(posedge txClkLcl) begin : tx_lcl_reset_sync
        rstTxLclR   <= rstLcl;
        rstTxLclRR  <= rstTxLclR;
        rstTxLclOut <= rstTxLclRR;
    end

    // Tx output clock domain
    always_ff @(posedge txClk) begin : tx_reset_sync
        rstTxR      <= rstLcl;
        rstTxRR     <= rstTxR;
        rstTxOut    <= rstTxRR;
    end

    // 250Mhz local domain
    always_ff @(posedge clk250) begin : fast_reset_sync
        rst250R     <= rstLcl;
        rst250RR    <= rst250R;
        rst250Out   <= rst250RR;
    end

    // Rx local domain
    always_ff @(posedge rxClkLcl) begin : rx_lcl_reset_sync
        rstRxLclR   <= rstLcl;
        rstRxLclRR  <= rstRxLclR;
        rstRxLclOut <= rstRxLclRR;
    end

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