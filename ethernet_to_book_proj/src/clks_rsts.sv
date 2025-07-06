`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev: Ian Rider
// Purpose: Generate local clocks with 100Mhz board clock and 125Mhz PHY rxClk
//////////////////////////////////////////////////////////////////////////////////
module clks_rsts(
    input  logic rstIn,
    input  logic clkIn,
    input  logic rxClkIn,
    output logic rstLclOut,
    output logic txClkLclOut,
    output logic txClkOut,
    output logic clk250Out,
    output logic rxClkLclOut,
    output logic mmcm0LockedOut,
    output logic mmcm1LockedOut);

    // Signals
    logic clkLcl;
    logic rstFF0;
    logic rstFF1;
    logic rstLcl;

    /////////////////////////////////
    // Clocks and Resets
    /////////////////////////////////
    BUFG BUFG_inst (
        .I(clkIn),
        .O(clkLcl));

    // Synchronize reset
    always_ff @(posedge clkLcl) begin : reset_sync_inst
        rstFF0 <= rstIn;
        rstFF1 <= rstFF0;
        rstLcl <= rstFF1;
    end

    assign rstLclOut = rstLcl;

    system_clocks_gen mmcm0_inst (
        .clk_out1(txClkLclOut),       // Local 125Mhz for RGMII
        .clk_out2(txClkOut),          // 125Mhz clock delayed by 1.5ns for PHY tx clock
        .clk_out3(clk250Out),         // 250Mhz system clock for parsers/book builder
        .reset(rstLcl),               // reset
        .locked(mmcm0LockedOut),      // Indicated ouput clocks are locked/valid
        .clk_in1(clkIn));             // 100Mhz reference clock

    rx_clk_shift mmcm1_inst (
        .clk_out1(rxClkLclOut),       // 125Mhz clock delayed for mgii rx logic
        .reset(rstLcl),               // reset
        .locked(mmcm1LockedOut),      // Indicated ouput clock is locked/valid
        .clk_in1(rxClkIn));           // 125 MHz reference clock provided by PHY
    
endmodule