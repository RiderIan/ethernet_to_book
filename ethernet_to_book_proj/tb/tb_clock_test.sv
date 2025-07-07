`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev: Ian Rider
// Purpose: Verify data to clock skew of RMGII TX and RX is 1.0ns-2.6ns 
//////////////////////////////////////////////////////////////////////////////////
import tb_pkg::*;

module tb_clock_test;

    logic       clk100       = 0;
    logic       rst          = 1;
    logic       rstTxLcl;
    logic       rstTx;
    logic       rst250;
    logic       rstRxLcl;
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

    // ENV
    tb_env env (
        .rstOut(rst),
        .clk100Out(clk100),
        .rxClkOut(rxClk));

    // DUT
    clks_rsts dut (
        .rstIn(rst),
        .clkIn(clk100),
        .rxClkIn(rxClk),
        .rstTxLclOut(rstTxLcl),
        .rstTxOut(rstTx),
        .rst250Out(rst250),
        .rstRxLclOut(rstRxLcl),
        .txClkLclOut(txClkFabric),
        .txClkOut(txClk),
        .clk250Out(clk250),
        .rxClkLclOut(rxClkFabric),
        .mmcm0LockedOut(mmcm0Locked),
        .mmcm1LockedOut(mmcm1Locked));

    initial begin
        @(negedge rstRxLcl);
        $display("Waiting for both mmcms lock - ", $realtime, "ns");
        wait_mmcm_locks(mmcm0Locked, mmcm1Locked);
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