module CLKS_RSTS(
    input  logic rstIn,
    input  logic clkIn,
    input  logic rxClkIn,
    output logic rstLclOut,
    output logic clkLclOut,
    output logic clk125TxOut,
    output logic txClkOut,
    output logic clk250Out,
    output logic clk125RxOut,
    output logic mmcm0LockedOut,
    output logic mmcm1LockedOut);

    // Signals
    logic clkLcl;
    logic rstLcl;

    /////////////////////////////////
    // Clocks and Resets
    /////////////////////////////////
    BUFG BUFG_inst (
        .I(clkIn),
        .O(clkLcl));

    assign clkLclOut = clkLcl;

    // Synchronize de-assertion of reset
    always_ff @(posedge clkLcl) begin : reset_deassert_sync_inst
        if (rstIn)
            rstLcl <= 1'b1;
        else
            rstLcl <= 1'b0;
    end

    assign rstLclOut = rstLcl;

    system_clocks_gen mmcm0_inst (
        .clk_out1(clk125TxOut),       // Local 125Mhz for RGMII
        .clk_out2(txClkOut),          // 125Mhz clock delayed by 1.5ns for PHY tx clock
        .clk_out3(clk250Out),         // 250Mhz system clock for parsers/book builder
        .reset(rstLcl),               // reset
        .locked(mmcm0LockedOut),      // Indicated ouput clocks are locked/valid
        .clk_in1(clkIn));             // 100Mhz reference clock

    rx_clk_shift mmcm1_inst (
        .clk_out1(clk125RxOut),       // 125Mhz clock delayed for mgii rx logic
        .reset(rstLcl),               // reset
        .locked(mmcm1LockedOut),      // Indicated ouput clock is locked/valid
        .clk_in1(rxClkIn));           // 125 MHz reference clock provided by PHY
    
endmodule