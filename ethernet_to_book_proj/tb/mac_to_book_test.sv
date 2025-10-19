`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev:     Ian Rider
// Purpose: Test full mac to order book engine path.
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
    logic [ 3:0]  txData;
    logic [15:0]  ipChkSum;
    logic [64:0]  refData;
    logic [31:0]  buyPriceLevelsR  [1:BOOK_DEPTH];
    logic [31:0]  buyQuantLevelsR  [1:BOOK_DEPTH];
    logic [31:0]  sellPriceLevelsR [1:BOOK_DEPTH];
    logic [31:0]  sellQuantLevelsR [1:BOOK_DEPTH];

    logic [31:0]  expBPriceLevelsR [1:BOOK_DEPTH];
    logic [31:0]  expBQuantLevelsR [1:BOOK_DEPTH];
    logic [31:0]  expSPriceLevelsR [1:BOOK_DEPTH];
    logic [31:0]  expSQuantLevelsR [1:BOOK_DEPTH];
    orderDataType orderData;
    bookLevelType topBuy;


    rgmii_rx_if         rxIf(rxClk);
    eth_udp_output_if   parserOutIf(clk250);

    ////////////////////////////////////////////
    // Initial order values
    ////////////////////////////////////////////
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

    itchDeleteOrderType delOrder = '{
        msgType    : DELETE_MSG_TYPE,
        locate     : 16'hBE42,
        trackNum   : 16'h3021,
        timeStamp  : 48'h000000003DE1,
        refNum     : 64'hDEF12373DEFDE89C};

    itchOrderExecutedType execOrder = '{
        msgType    : EXECUTED_MSG_TYPE,
        locate     : 16'hBE42,
        trackNum   : 16'h4553,
        timeStamp  : 48'h000000000101,
        refNum     : 64'hABCD167ABCDB1005,
        execShares : 32'hABCD7684,
        matchNum   : 64'h3BD786555512BED7};


    ////////////////////////////////////////////
    // Initial header values
    ////////////////////////////////////////////
    int itchDataLen     = ($bits(addOrder)*7 + $bits(delOrder)*2 + $bits(execOrder))/8;
    int ipV4TotalLen    = itchDataLen + MOLD_HEADER_LEN + UDP_HEADER_LEN + IP_HEADER_LEN;
    int udpLen          = itchDataLen + MOLD_HEADER_LEN + UDP_HEADER_LEN;

    // Headers
    ethHeaderType  ethHdr  =  {DEVICE_MAC, SRC_MAC, ETH_IP_V4_TYPE};
    ipHeaderType   ipHdr   =  {IP_V4_TYPE, DSCP_ECN, ipV4TotalLen[15:0], ID, FLAGS, TTL, PROTOCOL, 16'h0000, SRC_IP, DST_IP};
    udpHeaderType  udpHdr  =  {UDP_SRC_PORT, UDP_DEST_PORT, udpLen[15:0], 16'h0000};
    //                         session ID                sequence number       msg cnt   msg length
    moldHeaderType moldHdr = '{80'h00000000000000000004, 64'h0000000000000000, 16'h0006, itchDataLen[15:0]};

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

    ////////////////////////////////////////////
    // Internal signals
    ////////////////////////////////////////////
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
        // Init values, wait for stable clocks
        clk250        = 1'b0;
        rxIf.reset();
        wait(locked);

        // Send ethernet frame header
        ipChkSum = ip_header_chksum_calc(ipHdr);
        ipHdr.chkSum = ipChkSum;
        send_eth_header_rgmii(rxIf, ethHdr);
        send_ip_header_rgmii(rxIf, ipHdr);
        send_udp_header_rgmii(rxIf, udpHdr);
        send_mold_header_rgmii(rxIf, moldHdr);

        // Add order
        addOrder.refNum  = 64'h0000000000000001;
        addOrder.shares  = 32'h01234567;
        addOrder.price   = 32'h00050000;
        addOrder.buySell = BUY;
        send_itch_order_rgmii(rxIf, addOrder);

        // Add order
        addOrder.refNum  = 64'h0000000000000002;
        addOrder.shares  = 32'h0000FABC;
        addOrder.price   = 32'h00050001;
        addOrder.buySell = BUY;
        send_itch_order_rgmii(rxIf, addOrder);

        // Add order
        addOrder.refNum  = 64'h0000000000000003;
        addOrder.shares  = 32'h00000012;
        addOrder.price   = 32'h00040000;
        addOrder.buySell = BUY;
        send_itch_order_rgmii(rxIf, addOrder);

        // Add order
        addOrder.refNum  = 64'h0000000000000004;
        addOrder.shares  = 32'h00000432;
        addOrder.price   = 32'h00040001;
        addOrder.buySell = BUY;
        send_itch_order_rgmii(rxIf, addOrder);

        // Add order
        addOrder.refNum  = 64'h0000000000000005;
        addOrder.shares  = 32'h00000001;
        addOrder.price   = 32'h00050002;
        addOrder.buySell = BUY;
        send_itch_order_rgmii(rxIf, addOrder);

        // Add order
        addOrder.refNum  = 64'h0000000000000006;
        addOrder.shares  = 32'h00000FFF;
        addOrder.price   = 32'h00030000;
        addOrder.buySell = BUY;
        send_itch_order_rgmii(rxIf, addOrder);

        // Delete order
        delOrder.refNum  = 64'h0000000000000004;
        send_itch_delete_rgmii(rxIf, delOrder);

        // Execute top of book
        execOrder.refNum = 64'h0000000000000005;
        send_itch_execute_rgmii(rxIf, execOrder);

        // Add order
        addOrder.refNum  = 64'h0000000000000007;
        addOrder.shares  = 32'h00000123;
        addOrder.price   = 32'h00050000;
        addOrder.buySell = BUY;
        send_itch_order_rgmii(rxIf, addOrder);

        // Delete order
        delOrder.refNum  = 64'h0000000000000001;
        send_itch_delete_rgmii(rxIf, delOrder);

        // End frame
        @(posedge rxIf.clk);
        rxIf.ctrl = 1'b0;
        #10000

        // Re-calculate lengths and construct headers
        itchDataLen  = ($bits(addOrder)*10)/8;
        ipV4TotalLen = itchDataLen + MOLD_HEADER_LEN + UDP_HEADER_LEN + IP_HEADER_LEN;
        udpLen       = ipV4TotalLen + MOLD_HEADER_LEN + UDP_HEADER_LEN;
        ethHdr       = {DEVICE_MAC, SRC_MAC, ETH_IP_V4_TYPE};
        ipHdr        = {IP_V4_TYPE, DSCP_ECN, ipV4TotalLen[15:0], ID, FLAGS, TTL, PROTOCOL, 16'h0000, SRC_IP, DST_IP};
        udpHdr       = {UDP_SRC_PORT, UDP_DEST_PORT, udpLen[15:0], 16'h0000};
        //               session ID                sequence number       msg cnt   msg length
        moldHdr      = '{80'h00000000000000000004, 64'h000000000000000A, 16'h0006, itchDataLen[15:0]};
        ipChkSum = ip_header_chksum_calc(ipHdr);
        ipHdr.chkSum = ipChkSum;
        // Send header
        send_eth_header_rgmii(rxIf, ethHdr);
        send_ip_header_rgmii(rxIf, ipHdr);
        send_udp_header_rgmii(rxIf, udpHdr);
        send_mold_header_rgmii(rxIf, moldHdr);

        // Add order
        addOrder.refNum  = 64'h0000000000000008;
        addOrder.shares  = 32'h01234567;
        addOrder.price   = 32'h00000020;
        addOrder.buySell = SELL;
        send_itch_order_rgmii(rxIf, addOrder);

        // Add order
        addOrder.refNum  = 64'h0000000000000009;
        addOrder.shares  = 32'h00000001;
        addOrder.price   = 32'h0000001F;
        addOrder.buySell = SELL;
        send_itch_order_rgmii(rxIf, addOrder);

        // Add order
        addOrder.refNum  = 64'h000000000000000A;
        addOrder.shares  = 32'h00000555;
        addOrder.price   = 32'h0000001E;
        addOrder.buySell = SELL;
        send_itch_order_rgmii(rxIf, addOrder);

        // Add order
        addOrder.refNum  = 64'h000000000000000B;
        addOrder.shares  = 32'h00000AAA;
        addOrder.price   = 32'h00000123;
        addOrder.buySell = SELL;
        send_itch_order_rgmii(rxIf, addOrder);

        // Add order
        addOrder.refNum  = 64'h000000000000000C;
        addOrder.shares  = 32'h00000CCC;
        addOrder.price   = 32'h00000124;
        addOrder.buySell = SELL;
        send_itch_order_rgmii(rxIf, addOrder);

        // Add order
        addOrder.refNum  = 64'h000000000000000D;
        addOrder.shares  = 32'h00000001;
        addOrder.price   = 32'h0000001E;
        addOrder.buySell = SELL;
        send_itch_order_rgmii(rxIf, addOrder);

        // Delete order
        delOrder.refNum  = 64'h000000000000000D;
        send_itch_delete_rgmii(rxIf, delOrder);

        // Execute top of book
        execOrder.refNum = 64'h0000000000000009;
        send_itch_execute_rgmii(rxIf, execOrder);

        // End frame
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
        expBPriceLevelsR = '{32'h00050000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000};
        expBQuantLevelsR = '{32'h01234567, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000};
        check_price_levels(buyPriceLevelsR, expBPriceLevelsR);
        check_quant_levels(buyQuantLevelsR, expBQuantLevelsR);
        $display("ADD ORDER 1 COMPLETE");

        @(posedge buyUpdatedR);
        expBPriceLevelsR = '{32'h00050001, 32'h00050000, 32'h00000000, 32'h00000000, 32'h00000000};
        expBQuantLevelsR = '{32'h0000FABC, 32'h01234567, 32'h00000000, 32'h00000000, 32'h00000000};
        check_price_levels(buyPriceLevelsR, expBPriceLevelsR);
        check_quant_levels(buyQuantLevelsR, expBQuantLevelsR);
        $display("ADD ORDER 2 COMPLETE");

        @(posedge buyUpdatedR);
        expBPriceLevelsR = '{32'h00050001, 32'h00050000, 32'h00040000, 32'h00000000, 32'h00000000};
        expBQuantLevelsR = '{32'h0000FABC, 32'h01234567, 32'h00000012, 32'h00000000, 32'h00000000};
        check_price_levels(buyPriceLevelsR, expBPriceLevelsR);
        check_quant_levels(buyQuantLevelsR, expBQuantLevelsR);
        $display("ADD ORDER 3 COMPLETE");

        @(posedge buyUpdatedR);
        expBPriceLevelsR = '{32'h00050001, 32'h00050000, 32'h00040001, 32'h00040000, 32'h00000000};
        expBQuantLevelsR = '{32'h0000FABC, 32'h01234567, 32'h00000432, 32'h00000012, 32'h00000000};
        check_price_levels(buyPriceLevelsR, expBPriceLevelsR);
        check_quant_levels(buyQuantLevelsR, expBQuantLevelsR);
        $display("ADD ORDER 4 COMPLETE");

        @(posedge buyUpdatedR);
        expBPriceLevelsR = '{32'h00050002, 32'h00050001, 32'h00050000, 32'h00040001, 32'h00040000};
        expBQuantLevelsR = '{32'h00000001, 32'h0000FABC, 32'h01234567, 32'h00000432, 32'h00000012};
        check_price_levels(buyPriceLevelsR, expBPriceLevelsR);
        check_quant_levels(buyQuantLevelsR, expBQuantLevelsR);
        $display("ADD ORDER 5 COMPLETE");

        @(posedge dut.order_book_engine_inst.order_book_inst.addValidR); // Off book (no change) so buyUpdatedR never asserts
        #16 // Wait for updated level to propagate
        expBPriceLevelsR = '{32'h00050002, 32'h00050001, 32'h00050000, 32'h00040001, 32'h00040000};
        expBQuantLevelsR = '{32'h00000001, 32'h0000FABC, 32'h01234567, 32'h00000432, 32'h00000012};
        check_price_levels(buyPriceLevelsR, expBPriceLevelsR);
        check_quant_levels(buyQuantLevelsR, expBQuantLevelsR);
        $display("ADD ORDER 6 COMPLETE");

        @(posedge buyUpdatedR);
        expBPriceLevelsR = '{32'h00050002, 32'h00050001, 32'h00050000, 32'h00040000, 32'h00000000};
        expBQuantLevelsR = '{32'h00000001, 32'h0000FABC, 32'h01234567, 32'h00000012, 32'h00000000};
        check_price_levels(buyPriceLevelsR, expBPriceLevelsR);
        check_quant_levels(buyQuantLevelsR, expBQuantLevelsR);
        $display("DELETE ORDER REF 0004 COMPLETE");

        @(posedge buyUpdatedR);
        expBPriceLevelsR = '{32'h00050001, 32'h00050000, 32'h00040000, 32'h00000000, 32'h00000000};
        expBQuantLevelsR = '{32'h0000FABC, 32'h01234567, 32'h00000012, 32'h00000000, 32'h00000000};
        check_price_levels(buyPriceLevelsR, expBPriceLevelsR);
        check_quant_levels(buyQuantLevelsR, expBQuantLevelsR);
        $display("EXECUTE ORDER REF 0005 COMPLETE");

        @(posedge buyUpdatedR);
        expBPriceLevelsR = '{32'h00050001, 32'h00050000, 32'h00040000, 32'h00000000, 32'h00000000};
        expBQuantLevelsR = '{32'h0000FABC, 32'h0123468A, 32'h00000012, 32'h00000000, 32'h00000000};
        check_price_levels(buyPriceLevelsR, expBPriceLevelsR);
        check_quant_levels(buyQuantLevelsR, expBQuantLevelsR);
        $display("ADD ORDER 7 COMPLETE");

        @(posedge buyUpdatedR);
        expBPriceLevelsR = '{32'h00050001, 32'h00050000, 32'h00040000, 32'h00000000, 32'h00000000};
        expBQuantLevelsR = '{32'h0000FABC, 32'h00000123, 32'h00000012, 32'h00000000, 32'h00000000};
        check_price_levels(buyPriceLevelsR, expBPriceLevelsR);
        check_quant_levels(buyQuantLevelsR, expBQuantLevelsR);
        $display("DELETE ORDER REF 0005 COMPLETE");

        @(posedge sellUpdatedR);
        expSPriceLevelsR = '{32'h00000020, 32'hFFFFFFFF, 32'hFFFFFFFF, 32'hFFFFFFFF, 32'hFFFFFFFF};
        expSQuantLevelsR = '{32'h01234567, 32'hFFFFFFFF, 32'hFFFFFFFF, 32'hFFFFFFFF, 32'hFFFFFFFF};
        check_price_levels(sellPriceLevelsR, expSPriceLevelsR);
        check_quant_levels(sellQuantLevelsR, expSQuantLevelsR);
        $display("ADD SELL 1 COMPLETE");

        @(posedge sellUpdatedR);
        expSPriceLevelsR = '{32'h0000001F, 32'h00000020, 32'hFFFFFFFF, 32'hFFFFFFFF, 32'hFFFFFFFF};
        expSQuantLevelsR = '{32'h00000001, 32'h01234567, 32'hFFFFFFFF, 32'hFFFFFFFF, 32'hFFFFFFFF};
        check_price_levels(sellPriceLevelsR, expSPriceLevelsR);
        check_quant_levels(sellQuantLevelsR, expSQuantLevelsR);
        $display("ADD SELL 2 COMPLETE");

        @(posedge sellUpdatedR);
        expSPriceLevelsR = '{32'h0000001E, 32'h0000001F, 32'h00000020, 32'hFFFFFFFF, 32'hFFFFFFFF};
        expSQuantLevelsR = '{32'h00000555, 32'h00000001, 32'h01234567, 32'hFFFFFFFF, 32'hFFFFFFFF};
        check_price_levels(sellPriceLevelsR, expSPriceLevelsR);
        check_quant_levels(sellQuantLevelsR, expSQuantLevelsR);
        $display("ADD SELL 3 COMPLETE");

        @(posedge sellUpdatedR);
        expSPriceLevelsR = '{32'h0000001E, 32'h0000001F, 32'h00000020, 32'h00000123, 32'hFFFFFFFF};
        expSQuantLevelsR = '{32'h00000555, 32'h00000001, 32'h01234567, 32'h00000AAA, 32'hFFFFFFFF};
        check_price_levels(sellPriceLevelsR, expSPriceLevelsR);
        check_quant_levels(sellQuantLevelsR, expSQuantLevelsR);
        $display("ADD SELL 4 COMPLETE");

        @(posedge sellUpdatedR);
        expSPriceLevelsR = '{32'h0000001E, 32'h0000001F, 32'h00000020, 32'h00000123, 32'h00000124};
        expSQuantLevelsR = '{32'h00000555, 32'h00000001, 32'h01234567, 32'h00000AAA, 32'h00000CCC};
        check_price_levels(sellPriceLevelsR, expSPriceLevelsR);
        check_quant_levels(sellQuantLevelsR, expSQuantLevelsR);
        $display("ADD SELL 5 COMPLETE");

        @(posedge sellUpdatedR);
        expSPriceLevelsR = '{32'h0000001E, 32'h0000001F, 32'h00000020, 32'h00000123, 32'h00000124};
        expSQuantLevelsR = '{32'h00000556, 32'h00000001, 32'h01234567, 32'h00000AAA, 32'h00000CCC};
        check_price_levels(sellPriceLevelsR, expSPriceLevelsR);
        check_quant_levels(sellQuantLevelsR, expSQuantLevelsR);
        $display("ADD SELL 6 COMPLETE");

        @(posedge sellUpdatedR);
        expSPriceLevelsR = '{32'h0000001E, 32'h0000001F, 32'h00000020, 32'h00000123, 32'h00000124};
        expSQuantLevelsR = '{32'h00000555, 32'h00000001, 32'h01234567, 32'h00000AAA, 32'h00000CCC};
        check_price_levels(sellPriceLevelsR, expSPriceLevelsR);
        check_quant_levels(sellQuantLevelsR, expSQuantLevelsR);
        $display("DELETE SELL 1 COMPLETE");

        @(posedge sellUpdatedR);
        expSPriceLevelsR = '{32'h0000001E, 32'h00000020, 32'h00000123, 32'h00000124, 32'hFFFFFFFF};
        expSQuantLevelsR = '{32'h00000555, 32'h01234567, 32'h00000AAA, 32'h00000CCC, 32'hFFFFFFFF};
        check_price_levels(sellPriceLevelsR, expSPriceLevelsR);
        check_quant_levels(sellQuantLevelsR, expSQuantLevelsR);
        $display("EXECTUED SELL 1 COMPLETE");

        #100
        $display(" --- TEST PASSED ---");
        $finish;
    end

endmodule