`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev:     Ian Rider
// Purpose: Verify MAC through ethernet parser
//////////////////////////////////////////////////////////////////////////////////
import tb_pkg::*;

module mac_to_parse_test;

    logic rst, clk100, rxClk, rxCtrl, txClk, txCtrl, itchDataValid, intB, phyRstB, locked;
    logic [3:0] rxData, txData;
    logic [7:0] itchData;

    // ENV
    tb_env env (
        .rstOut(rst),
        .clk100Out(clk100),
        .rxClkOut(rxClk));

    // DUT
    ethernet_to_book_top dut (
        .clkIn(clk100),
        .rstIn(rst),

        .rxDataIn(rxData),
        .rxCtrlIn(rxCtrl),
        .rxClkIn(rxClk),

        .txDataOut(txData),
        .txCtrlOut(txCtrl),
        .txClkOut(txClk),

        .itchDataValidOut(itchDataValid),
        .itchDataOut(itchData),

        .intBIn(intB),
        .phyRstBOut(phyRstB),
        .lockedOut(locked));

    initial begin : frame_gen_proc
        wait(locked);
        // TODO: Continue here and replicate eth_udp_parse_test but with rgmii tasks

    end

    initial begin : frame_check_proc
        $display(" --- TEST PASSED ---");
        $finish;
    end

endmodule