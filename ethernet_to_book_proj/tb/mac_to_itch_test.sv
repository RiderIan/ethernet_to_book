`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev:     Ian Rider
// Purpose: Verify full MAC to ITCH parser path
//////////////////////////////////////////////////////////////////////////////////
import tb_pkg::*;

module mac_to_itch_test;

    const int         CLK_250_MHZ_PERIOD = 4;
    const int         ETH_HEADER_LEN     = 14; // Not included in IP length
    const int         IP_HEADER_LEN      = 20;
    const int         UDP_HEADER_LEN     = 8;
    const int         MOLD_HEADER_LEN    = 20;

    logic rst, clk100, rxClk, txClk, txCtrl, intB, phyRstB, locked, clk250, packetLostDet, buySell;
    logic [ 3:0] txData;
    logic [ 7:0] itchData;
    logic [15:0] ipChkSum;
    logic [15:0] locate;
    logic [31:0] price, shares;
    logic [63:0] refNum;

    rgmii_rx_if         rxIf(rxClk);
    itch_add_output_if  addIf(clk250);
    itch_del_output_if  delIf(clk250);
    itch_exec_output_if execIf(clk250);
    eth_udp_output_if   parserOutIf(clk250);

    // Add order
    itchAddOrderType addOrder = '{
        msgType    : ADD_MSG_TYPE,
        locate     : 16'hBE42,      // Changes everyday, used for rapid book lookup
        trackNum   : 16'h0001,
        timeStamp  : 48'h000000000455,
        refNum     : 64'hDEFB1673DEFB1673,
        buySell    : BUY,
        shares     : 32'h00000045,
        stock      : AAPL,
        price      : 32'h0022FEFC}; // Price in $0.0001 increments, this is $229.3500 for example

    // Delete order
    itchDeleteOrderType delOrder = '{
        msgType    : DELETE_MSG_TYPE,
        locate     : 16'hBE42,
        trackNum   : 16'h3021,
        timeStamp  : 48'h000000003DE1,
        refNum     : 64'hDEF12373DEFDE89C};

    // Execute order
    itchOrderExecutedType execOrder = '{
        msgType    : EXECUTED_MSG_TYPE,
        locate     : 16'hBE42,
        trackNum   : 16'h4553,
        timeStamp  : 48'h000000000101,
        refNum     : 64'hABCD167ABCDB1005,
        execShares : 32'hABCD7684,
        matchNum   : 64'h3BD786555512BED7};

    int ITCH_DATA_LEN      = $bits({addOrder, delOrder, execOrder})/8;
    int IP_V4_TOTAL_LEN    = ITCH_DATA_LEN + MOLD_HEADER_LEN + UDP_HEADER_LEN + IP_HEADER_LEN;
    int UDP_LENGTH         = ITCH_DATA_LEN + MOLD_HEADER_LEN + UDP_HEADER_LEN;

    // Headers
    ethHeaderType  ethHdr  =  {DEVICE_MAC, SRC_MAC, ETH_IP_V4_TYPE};
    ipHeaderType   ipHdr   =  {IP_V4_TYPE, DSCP_ECN, IP_V4_TOTAL_LEN[15:0], ID, FLAGS, TTL, PROTOCOL, 16'h0000, SRC_IP, DST_IP};
    udpHeaderType  udpHdr  =  {UDP_SRC_PORT, UDP_DEST_PORT, UDP_LENGTH[15:0], 16'h0000};
    moldHeaderType moldHdr = '{
        sessId    : 80'h00000000000000000004, // Random
        seqNum    : 64'h0000000000000001,     // Increments for every new message on session ID
        msgCnt    : 16'h0001,                 // Number of ITCH messages within frame
        moldLen   : ITCH_DATA_LEN[15:0]};     // Number of data bytes

    ////////////////////////////////////////////
    // Environment
    ////////////////////////////////////////////
    tb_env env (
        .rstOut(rst),
        .clk100Out(clk100),
        .rxClkOut(rxClk));

    // Needed for itch data output as this won't actually be an output
    always #(CLK_250_MHZ_PERIOD/2) clk250 = ~clk250;

    ////////////////////////////////////////////
    // DUT
    ////////////////////////////////////////////
    ethernet_to_book_top dut (
        .clkIn(clk100),
        .rstIn(rst),

        .rxDataIn(rxIf.data),
        .rxCtrlIn(rxIf.ctrl),
        .rxClkIn(rxIf.clk),

        .txDataOut(txData),
        .txCtrlOut(txCtrl),
        .txClkOut(txClk),

        .itchDataValidOut(parserOutIf.dataValid),
        .itchDataOut(parserOutIf.data),
        .packetLostOut(parserOutIf.packetLost),

        .addValidOut(addIf.valid),
        .delValidOut(delIf.valid),
        .execValidOut(execIf.valid),
        .refNumOut(refNum),
        .locateOut(locate),
        .priceOut(price),
        .sharesOut(shares),
        .buySellOut(buySell),

        .intBIn(intB),
        .phyRstBOut(phyRstB),
        .lockedOut(locked));

    // Interfaces
    assign addIf.refNum  = refNum;
    assign addIf.locate  = locate;
    assign addIf.buySell = buySell;
    assign addIf.shares  = shares;
    assign addIf.price   = price;
    assign delIf.refNum  = refNum;
    assign delIf.locate  = locate;
    assign execIf.refNum = refNum;
    assign execIf.locate = locate;

    ////////////////////////////////////////////
    // Stimulus
    ////////////////////////////////////////////
    initial begin : frame_gen_proc
        clk250        = 1'b0;
        packetLostDet = 1'b0;
        rxIf.reset();
        ipChkSum = ip_header_chksum_calc(ipHdr);
        ipHdr.chkSum = ipChkSum;
        wait(locked);

        // Send ethernet frame header
        send_eth_header_rgmii(rxIf, ethHdr);
        send_ip_header_rgmii(rxIf, ipHdr);
        send_udp_header_rgmii(rxIf, udpHdr);
        send_mold_header_rgmii(rxIf, moldHdr);
        send_itch_order_rgmii(rxIf, addOrder);
        send_itch_delete_rgmii(rxIf, delOrder);
        send_itch_execute_rgmii(rxIf, execOrder);
        @(posedge rxIf.clk);
        rxIf.ctrl = 1'b0;

        #10000;

        // Skip one seq number for packet loss detection
        moldHdr.seqNum = 3;

        // Send ethernet frame header
        send_eth_header_rgmii(rxIf, ethHdr);
        send_ip_header_rgmii(rxIf, ipHdr);
        send_udp_header_rgmii(rxIf, udpHdr);
        send_mold_header_rgmii(rxIf, moldHdr);
        send_itch_order_rgmii(rxIf, addOrder);
        send_itch_delete_rgmii(rxIf, delOrder);
        send_itch_execute_rgmii(rxIf, execOrder);
        @(posedge rxIf.clk);
        rxIf.ctrl = 1'b0;
    end

    always @(posedge parserOutIf.packetLost) begin
        packetLostDet = 1'b1;
    end

    ////////////////////////////////////////////
    // Output check
    ////////////////////////////////////////////
    initial begin : check_output
        check_itch_add(addIf, addOrder);
        assert((delIf.valid|execIf.valid) != 1'b1) else $fatal ("Delete valid or execute valid asserted unexpectedly");
        $display("Add order passed.");

        check_itch_del(delIf, delOrder);
        assert((addIf.valid|execIf.valid) != 1'b1) else $fatal ("Add valid or execute valid asserted unexpectedly");
        $display("Delete order passed.");

        check_itch_exec(execIf, execOrder);
        assert((addIf.valid|delIf.valid) != 1'b1) else $fatal ("Add valid or delete valid asserted unexpectedly");
        $display("Execute order passed.");

        check_itch_add(addIf, addOrder);
        assert((delIf.valid|execIf.valid) != 1'b1) else $fatal ("Delete valid or execute valid asserted unexpectedly");
        $display("Add order passed.");

        check_itch_del(delIf, delOrder);
        assert((addIf.valid|execIf.valid) != 1'b1) else $fatal ("Add valid or execute valid asserted unexpectedly");
        $display("Delete order passed.");

        check_itch_exec(execIf, execOrder);
        assert((addIf.valid|delIf.valid) != 1'b1) else $fatal ("Add valid or delete valid asserted unexpectedly");
        $display("Execute order passed.");

        #20;
        $display(" --- TEST PASSED ---");
        $finish;
    end

endmodule