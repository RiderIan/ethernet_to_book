`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev: Ian Rider
// Purpose: Verify data to clock skew of RMGII TX and RX is 1.6ns-2.0ns 
//////////////////////////////////////////////////////////////////////////////////

module clockCheck;

    logic       clk100       = 0;
    logic       rst          = 1;

    logic [3:0] rxData;
    logic       rxCtrl;
    logic       rxClk;

    logic [3:0] txData;
    logic       txCtrl;
    logic       txClk;

    logic       intB;
    logic       phyRstB;

    logic       mmcm0Locked;
    logic       clk125;

    real        macSysClk125Time;
    real        macDlyClk125Time;

    // Clock gen
    always #5 clk100 = ~clk100;

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
        
        .mcmm0LockedOut(mmcm0Locked),
        .clk125Out(clk125));

    initial begin
        rst = 1;
        #20;
        rst = 0;
        $display("Waiting for mmcm lock");
        wait (mmcm0Locked == 1);
        @(posedge clk125);
        macSysClk125Time = $realtime;
        @(posedge txClk);
        macDlyClk125Time = $realtime;

        assert((macSysClk125Time + 1.5) == macDlyClk125Time) else $fatal("Clock skew of 1.5ns not achieved. Measured skew = ", (macDlyClk125Time - macSysClk125Time));
        $display("Measured clock skew: ", macDlyClk125Time - macSysClk125Time, "ns");
        $display("This test ran");
        $finish;
    end

endmodule