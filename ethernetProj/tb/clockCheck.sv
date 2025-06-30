`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev: Ian Rider
// Purpose: Verify data to clock skew of RMGII TX and RX is 1.0ns-2.6ns 
//////////////////////////////////////////////////////////////////////////////////
`include "tasks.sv"

module clockCheck;

    const int CLK_100_MHX_PERIOD = 10;
    const int CLK_125_MHZ_PERIOD = 8;

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

    real        txClkFabricTime;
    real        txClkPhyTime;
    real        rxClkFabricTime;
    real        rxClkPhyTime;

    // Clock gen
    always #(CLK_100_MHX_PERIOD/2) clk100 = ~clk100;
    always #(CLK_125_MHZ_PERIOD/2) rxClk  = ~rxClk;

    // DUT
    CLKS_RSTS dut (
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
        init_reset(rst);
        $display("Waiting for both mmcms lock - ", $realtime, "ns");
        wait_lock(mmcm0Locked, mmcm1Locked);
        @(posedge txClkFabric);
        txClkFabricTime = $realtime;
        @(posedge txClk);
        txClkPhyTime = $realtime;
        @(posedge rxClk);
        rxClkPhyTime = $realtime;
        @(posedge rxClkFabric);
        rxClkFabricTime = $realtime;


        assert((txClkFabricTime + 1.5) == txClkPhyTime) else $fatal("TX clock skew of 1.5ns not achieved. Measured skew = ", (txClkPhyTime    - txClkFabricTime));
        assert((rxClkPhyTime + 1.5) == rxClkFabricTime) else $fatal("RX clock skew of 1.5ns not achieved. Measured skew = ", (rxClkFabricTime - rxClkPhyTime));
        $display("TX measured clock skew: ", txClkPhyTime    - txClkFabricTime, "ns");
        $display("RX measured clock skew: ", rxClkFabricTime - rxClkPhyTime,    "ns");
        $display(" --- TEST PASSED ---");
        $finish;
    end

endmodule