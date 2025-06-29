`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev: Ian Rider
// Purpose: Verify data to clock skew of RMGII TX and RX is 1.0ns-2.6ns 
//////////////////////////////////////////////////////////////////////////////////

module clockCheck;

    const int CLK_100_MHX_PERIOD = 10;
    const int CLK_125_MHZ_PERIOD = 8;

    logic       clk100       = 0;
    logic       rst          = 1;

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
    EthernetProjTop dut (
        .clkIn(clk100),
        .rstIn(rst),

        .rxDataIn(rxData),
        .rxCtrlIn(rxCtrl),
        .rxClkIn(rxClk),

        .txDataOut(txData),
        .txCtrlOut(txCtrl),
        .txClkOut(txClk),

        .intBIn(intB),
        .phyRstBOut(phyRstB),
        
        .mmcm0LockedOut(mmcm0Locked),
        .mmcm1LockedOut(mmcm1Locked),
        .txClkFabricOut(txClkFabric),
        .rxClkFabricOut(rxClkFabric));

    initial begin
        rst = 1;
        #20;
        rst = 0;
        $display("Waiting for both mmcms lock - ", $realtime, "ns");
        wait(mmcm0Locked == 1'b1 && mmcm1Locked == 1'b1);
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
        $display("Measured clock skew: ", txClkPhyTime    - txClkFabricTime, "ns");
        $display("Measured clock skew: ", rxClkFabricTime - rxClkPhyTime,    "ns");
        $display("This test ran");
        $finish;
    end

endmodule