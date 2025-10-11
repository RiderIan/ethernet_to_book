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
    localparam int    BOOK_DEPTH         = 5;

    logic rst, clk100, rxClk, txClk, txCtrl, intB, phyRstB, locked, clk250, buyUpdatedR, sellUpdatedR;
    logic [ 3:0] txData;
    logic [15:0] ipChkSum;
    logic [64:0] refData;
    logic [31:0]  buyPriceLevelsR  [1:BOOK_DEPTH];
    logic [31:0]  buyQuantLevelsR  [1:BOOK_DEPTH];
    logic [31:0]  sellPriceLevelsR [1:BOOK_DEPTH];
    logic [31:0]  sellQuantLevelsR [1:BOOK_DEPTH];

    logic [31:0]  expBPriceLevelsR  [1:BOOK_DEPTH];
    logic [31:0]  expBQuantLevelsR  [1:BOOK_DEPTH];
    logic [31:0]  expSPriceLevelsR [1:BOOK_DEPTH];
    logic [31:0]  expSQuantLevelsR [1:BOOK_DEPTH];
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

    int ITCH_DATA_LEN1     = ($bits(addOrder)*8 + $bits({delOrder, execOrder}))/8;
    int ITCH_DATA_LEN2     = ($bits(addOrder)*2 + $bits({delOrder, execOrder}))/8;
    int IP_V4_TOTAL_LEN1    = ITCH_DATA_LEN1 + MOLD_HEADER_LEN + UDP_HEADER_LEN + IP_HEADER_LEN;
    int IP_V4_TOTAL_LEN2    = ITCH_DATA_LEN2 + MOLD_HEADER_LEN + UDP_HEADER_LEN + IP_HEADER_LEN;
    int UDP_LENGTH1         = IP_V4_TOTAL_LEN1 + MOLD_HEADER_LEN + UDP_HEADER_LEN;
    int UDP_LENGTH2         = IP_V4_TOTAL_LEN2 + MOLD_HEADER_LEN + UDP_HEADER_LEN;

    // Headers
    ethHeaderType  ethHdr   =  {DEVICE_MAC, SRC_MAC, ETH_IP_V4_TYPE};
    ipHeaderType   ipHdr1   =  {IP_V4_TYPE, DSCP_ECN, IP_V4_TOTAL_LEN1[15:0], ID, FLAGS, TTL, PROTOCOL, 16'h0000, SRC_IP, DST_IP};
    ipHeaderType   ipHdr2   =  {IP_V4_TYPE, DSCP_ECN, IP_V4_TOTAL_LEN2[15:0], ID, FLAGS, TTL, PROTOCOL, 16'h0000, SRC_IP, DST_IP};
    udpHeaderType  udpHdr1  =  {UDP_SRC_PORT, UDP_DEST_PORT, UDP_LENGTH1[15:0], 16'h0000};
    udpHeaderType  udpHdr2  =  {UDP_SRC_PORT, UDP_DEST_PORT, UDP_LENGTH2[15:0], 16'h0000};
    moldHeaderType moldHdr1 = '{
        sessId    : 80'h00000000000000000004, // Random
        seqNum    : 64'h0000000000000001,     // Increments for every new message on session ID
        msgCnt    : 16'h0006,                 // Number of ITCH messages within frame
        moldLen   : ITCH_DATA_LEN1[15:0]};    // Number of data bytes

    moldHeaderType moldHdr2 = '{
        sessId    : 80'h00000000000000000004, // Random
        seqNum    : 64'h0000000000000001,     // Increments for every new message on session ID
        msgCnt    : 16'h0003,                 // Number of ITCH messages within frame
        moldLen   : ITCH_DATA_LEN2[15:0]};    // Number of data bytes

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

        .intBIn(intB),
        .phyRstBOut(phyRstB),
        .lockedOut(locked));

    always_comb begin : internal_levels
        for (int i = 1; i <= BOOK_DEPTH; i++) begin
            buyPriceLevelsR[i]  <= dut.order_book_engine_inst.order_book_inst.buyPriceLevelsR[i];
            buyQuantLevelsR[i]  <= dut.order_book_engine_inst.order_book_inst.buyQuantLevelsR[i];
            sellPriceLevelsR[i] <= dut.order_book_engine_inst.order_book_inst.sellPriceLevelsR[i];
            sellQuantLevelsR[i] <= dut.order_book_engine_inst.order_book_inst.sellQuantLevelsR[i];
        end

        buyUpdatedR  <= dut.order_book_engine_inst.order_book_inst.buyUpdatedR;
        sellUpdatedR <= dut.order_book_engine_inst.order_book_inst.sellUpdatedR;
    end

    ////////////////////////////////////////////
    // Stimulus
    ////////////////////////////////////////////
    initial begin : frame_gen_proc
        clk250        = 1'b0;
        rxIf.reset();
        ipChkSum = ip_header_chksum_calc(ipHdr1);
        ipHdr1.chkSum = ipChkSum;
        wait(locked);

        // Send ethernet frame header
        send_eth_header_rgmii(rxIf, ethHdr);
        send_ip_header_rgmii(rxIf, ipHdr1);
        send_udp_header_rgmii(rxIf, udpHdr1);
        send_mold_header_rgmii(rxIf, moldHdr1);

        // Add order 1
        addOrder.refNum = 64'hDEF12373DEFDE89C; // matches delete order ref num
        send_itch_order_rgmii(rxIf, addOrder);

        // Add order 2
        addOrder.refNum = 64'hABCD167ABCDB1005; // matches execute order ref num
        addOrder.shares = 32'h00000555;
        send_itch_order_rgmii(rxIf, addOrder);

        // Add order 3
        addOrder.refNum = 64'hABCD167ABCDB1006;
        addOrder.price  = 32'h00224000;
        addOrder.shares = 32'h00000554;
        send_itch_order_rgmii(rxIf, addOrder);

        // Add order 4
        addOrder.refNum = 64'hABCD167ABCDB1007;
        addOrder.shares = 32'h00000553;
        send_itch_order_rgmii(rxIf, addOrder);

        // Add order 5
        addOrder.refNum = 64'hABCD167ABCDB1008;
        addOrder.price  = 32'h00222000;
        addOrder.shares = 32'h00000552;
        send_itch_order_rgmii(rxIf, addOrder);

        // Add order 6
        addOrder.refNum = 64'hABCD167ABCDB1009;
        addOrder.price  = 32'h00221000;
        addOrder.shares = 32'h00000551;
        send_itch_order_rgmii(rxIf, addOrder);

        // New frame
        // @(posedge rxIf.clk);
        // rxIf.ctrl = 1'b0;
        // #10000;

        // Send ethernet frame header
        // send_eth_header_rgmii(rxIf, ethHdr);
        // send_ip_header_rgmii(rxIf, ipHdr2);
        // send_udp_header_rgmii(rxIf, udpHdr2);
        // send_mold_header_rgmii(rxIf, moldHdr2);

        // Add order 7 -> insert between 4 and 5
        addOrder.refNum = 64'hABCD167ABCDAAAAA;
        addOrder.price  = 32'h00222001;
        addOrder.shares = 32'h00123123;
        send_itch_order_rgmii(rxIf, addOrder);

        // Add order 8 -> insert at top so bottom falls off
        addOrder.refNum = 64'hABCD167ABCDBBBBB;
        addOrder.price  = 32'hFFFFFFFF;
        addOrder.shares = 32'h01010101;
        send_itch_order_rgmii(rxIf, addOrder);

        // Delete first order
        send_itch_delete_rgmii(rxIf, delOrder);

        // Execute second order
        send_itch_execute_rgmii(rxIf, execOrder);
        @(posedge rxIf.clk);
        rxIf.ctrl = 1'b0;

    end

    ////////////////////////////////////////////
    // Output check
    ////////////////////////////////////////////
    initial begin : check_output

        ////////////////////////////////////////////
        // Buy side
        ////////////////////////////////////////////
        @(posedge buyUpdatedR);
        expBPriceLevelsR = '{32'h0022FEFC, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000};
        expBQuantLevelsR = '{32'h00000045, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000};
        check_price_levels(buyPriceLevelsR, expBPriceLevelsR);
        check_quant_levels(buyQuantLevelsR, expBQuantLevelsR);

        @(posedge buyUpdatedR);
        expBPriceLevelsR = '{32'h0022FEFC, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000};
        expBQuantLevelsR = '{32'h0000059A, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000};
        check_price_levels(buyPriceLevelsR, expBPriceLevelsR);
        check_quant_levels(buyQuantLevelsR, expBQuantLevelsR);

        @(posedge buyUpdatedR);
        expBPriceLevelsR = '{32'h0022FEFC, 32'h00224000, 32'h00000000, 32'h00000000, 32'h00000000};
        expBQuantLevelsR = '{32'h0000059A, 32'h00000554, 32'h00000000, 32'h00000000, 32'h00000000};
        check_price_levels(buyPriceLevelsR, expBPriceLevelsR);
        check_quant_levels(buyQuantLevelsR, expBQuantLevelsR);

        @(posedge buyUpdatedR);
        expBPriceLevelsR = '{32'h0022FEFC, 32'h00224000, 32'h00000000, 32'h00000000, 32'h00000000};
        expBQuantLevelsR = '{32'h0000059A, 32'h00000AA7, 32'h00000000, 32'h00000000, 32'h00000000};
        check_price_levels(buyPriceLevelsR, expBPriceLevelsR);
        check_quant_levels(buyQuantLevelsR, expBQuantLevelsR);

        @(posedge buyUpdatedR);
        expBPriceLevelsR = '{32'h0022FEFC, 32'h00224000, 32'h00222000, 32'h00000000, 32'h00000000};
        expBQuantLevelsR = '{32'h0000059A, 32'h00000AA7, 32'h00000552, 32'h00000000, 32'h00000000};
        check_price_levels(buyPriceLevelsR, expBPriceLevelsR);
        check_quant_levels(buyQuantLevelsR, expBQuantLevelsR);

        @(posedge buyUpdatedR);
        expBPriceLevelsR = '{32'h0022FEFC, 32'h00224000, 32'h00222000, 32'h00221000, 32'h00000000};
        expBQuantLevelsR = '{32'h0000059A, 32'h00000AA7, 32'h00000552, 32'h00000551, 32'h00000000};
        check_price_levels(buyPriceLevelsR, expBPriceLevelsR);
        check_quant_levels(buyQuantLevelsR, expBQuantLevelsR);

        @(posedge buyUpdatedR);
        expBPriceLevelsR = '{32'h0022FEFC, 32'h00224000, 32'h00222001, 32'h00222000, 32'h00221000};
        expBQuantLevelsR = '{32'h0000059A, 32'h00000AA7, 32'h00123123, 32'h00000552, 32'h00000551};
        check_price_levels(buyPriceLevelsR, expBPriceLevelsR);
        check_quant_levels(buyQuantLevelsR, expBQuantLevelsR);

        @(posedge buyUpdatedR);
        expBPriceLevelsR = '{32'hFFFFFFFF, 32'h0022FEFC, 32'h00224000, 32'h00222001, 32'h00222000};
        expBQuantLevelsR = '{32'h01010101, 32'h0000059A, 32'h00000AA7, 32'h00123123, 32'h00000552};
        check_price_levels(buyPriceLevelsR, expBPriceLevelsR);
        check_quant_levels(buyQuantLevelsR, expBQuantLevelsR);

        #100
        $display(" --- TEST PASSED ---");
        $finish;
    end

endmodule