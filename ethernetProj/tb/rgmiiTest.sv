`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev: Ian Rider
// Purpose: Verify data transfer to and from RGMII
//////////////////////////////////////////////////////////////////////////////////
`include "tasks.sv"

module rgmiiTest;

    logic       clk100       = 0;
    logic       rst          = 1;
    logic       rstLcl;
    logic       clkLcl;
    logic       clk250;

    logic [3:0] rxData;
    logic       rxCtrl;
    logic       rxClk        = 0;

    logic [3:0] txData;
    logic       txCtrl;
    logic       txClk;

    logic       intB;
    logic       phyRstB;

    logic       mmcm0Locked = 0;
    logic       mmcm1Locked = 0;
    logic       txClkFabric;

    // Clock gen
    always #(CLK_100_MHX_PERIOD/2) clk100 = ~clk100;
    always #(CLK_125_MHZ_PERIOD/2) rxClk  = ~rxClk;

    // DUT0
    RGMII rgmi_dut0_inst (
        rstIn,
        clk125In,
        rxClkIn,
        rxDataIn,
        rxCtrlIn,
        intBIn,
        mmcm0LockedIn
        mmcm1LockedIn
        txDataOut,
        txCtrlOut,
        phyRstBOut);

    // DUT1
    CLKS_RSTS clks_rsts_dut1_inst (
        .rstIn(rst),
        .clkIn(clk100),
        .rxClkIn(rxClk),
        .rstLclOut(rstLcl),
        .clkLclOut(clkLcl),
        .clk125TxOut(txClkFabric),
        .txClkOut(txClk),
        .clk250Out(clk250),
        .clk125RxOut(rxClkFabric),
        .mmcm0LockedOut(mmcm0Locked),
        .mmcm1LockedOut(mmcm1Locked));

    initial begin
        init_rst(rst);
        tx_rgmii_data

    end

endmodule