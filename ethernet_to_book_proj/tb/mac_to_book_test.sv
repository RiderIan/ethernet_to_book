`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev:     Ian Rider
// Purpose:
//////////////////////////////////////////////////////////////////////////////////
import tb_pkg::*;

module mac_to_book_test;

    const int         CLK_250_MHZ_PERIOD = 4;
    const int         ETH_HEADER_LEN     = 14; // Not included in IP length
    const int         IP_HEADER_LEN      = 20;
    const int         UDP_HEADER_LEN     = 8;
    const int         MOLD_HEADER_LEN    = 20;

    logic rst, clk100, rxClk, txClk, txCtrl, intB, phyRstB, locked, clk250;
    logic [ 3:0] txData;
    logic [15:0] ipChkSum;
    logic [64:0] refData;
    orderDataType orderData;
    bookLevelType topBuy;


    rgmii_rx_if         rxIf(rxClk);
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

    int ITCH_DATA_LEN      = ($bits(addOrder)*6)/8;
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

        .orderDataOut(orderData),
        .refDataOut(refData),
        .topBuyOut(topBuy),

        .intBIn(intB),
        .phyRstBOut(phyRstB),
        .lockedOut(locked));

    ////////////////////////////////////////////
    // Stimulus
    ////////////////////////////////////////////
    initial begin : frame_gen_proc
        clk250        = 1'b0;
        rxIf.reset();
        ipChkSum = ip_header_chksum_calc(ipHdr);
        ipHdr.chkSum = ipChkSum;
        wait(locked);

        // Send ethernet frame header
        send_eth_header_rgmii(rxIf, ethHdr);
        send_ip_header_rgmii(rxIf, ipHdr);
        send_udp_header_rgmii(rxIf, udpHdr);
        send_mold_header_rgmii(rxIf, moldHdr);

        // Add order 1
        send_itch_order_rgmii(rxIf, addOrder);

        // Add order 2
        addOrder.shares = 32'h00000555;
        send_itch_order_rgmii(rxIf, addOrder);

        // Add order 3
        addOrder.price  = 32'h00224000;
        addOrder.shares = 32'h00000554;
        send_itch_order_rgmii(rxIf, addOrder);

        // Add order 4
        addOrder.price  = 32'h00223000;
        addOrder.shares = 32'h00000553;
        send_itch_order_rgmii(rxIf, addOrder);

        // Add order 5
        addOrder.price  = 32'h00222000;
        addOrder.shares = 32'h00000552;
        send_itch_order_rgmii(rxIf, addOrder);

        // Add order 6 -> off book
        addOrder.price  = 32'h00221000;
        addOrder.shares = 32'h00000551;
        send_itch_order_rgmii(rxIf, addOrder);
        @(posedge rxIf.clk);
        rxIf.ctrl = 1'b0;

    end

    ////////////////////////////////////////////
    // Output check
    ////////////////////////////////////////////
    initial begin : check_output

        #10000;
        $display(" --- TEST PASSED ---");
        $finish;
    end

endmodule