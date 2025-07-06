`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev: Ian Rider
// Purpose: Verify RGMII_RX module ablitity to decode ethernet packets
//////////////////////////////////////////////////////////////////////////////////
import tb_pkg::*;

module rgmii_rx_test;

    // Env signals
    logic              rst;
    logic              clk100;
    logic              rxClk;

    // Clock and reset signals
    logic              rstlcl;
    logic              txClkLcl;
    logic              txClk;
    logic              clk250;
    logic              rxClkLcl;
    logic              mmcm0Locked;
    logic              mmcm1Locked;

    // rgmii signals
    logic              intB;
    logic              rxDataLast;
    rgmii_rx_if        rxIf(rxClk);
    rgmii_rx_output_if rxOIf(rxClkLcl);
    
    // ENV
    tb_env env (
        .rstOut(rst),
        .clk100Out(clk100),
        .rxClkOut(rxClk));

    // DUT0
    rgmii_rx dut0 (
        .rstIn(rstLcl),
        .rxClkIn(rxClkLcl),
        .rxDataIn(rxIf.rxData),
        .rxCtrlIn(rxIf.rxCtrl),
        .intBIn(intB),
        .mmcmLockedIn(mmcm0Locked & mmcm1Locked),
        .rxDataOut(rxOIf.rxData),
        .rxDataValidOut(rxOIf.rxDataValid),
        .rxDataLastOut(rxOIf.rxDataLast));

    // DUT1
    clks_rsts dut1 (
        .rstIn(rst),
        .clkIn(clk100),
        .rxClkIn(rxClk),
        .rstLclOut(rstLcl),
        .txClkLclOut(txClkLcl),
        .txClkOut(txClk),
        .clk250Out(clk250),
        .rxClkLclOut(rxClkLcl),
        .mmcm0LockedOut(mmcm0Locked),
        .mmcm1LockedOut(mmcm1Locked));

    initial begin : frame_gen_proc
        rxIf.reset();
        @(negedge rstLcl);
        $display("Waiting for both mmcms lock - ", $realtime, "ns");
        wait_mmcm_locks(mmcm0Locked, mmcm1Locked);

        // Stream non-stop for max ethernet frame size (ipv4, MoldUdp64, ITCH)
        for(int i = 0; i < 1440; i++)
            send_byte(rxIf, i);

        // End frame
        @(posedge rxClk);
        rxIf.rxCtrl = 1'b0;
 
    end

    initial begin : frame_check_proc
        @(posedge rxOIf.rxDataValid);
        for(int i = 0; i < 1440; i++)
            check_byte(rxOIf, i);
            assert(rxOIf.rxDataLast == 0) else $fatal("Unexpected end of frame :(");
        @(negedge rxOIf.rxDataLast);
        $display(" --- TEST PASSED ---");
        $finish;
    end


endmodule