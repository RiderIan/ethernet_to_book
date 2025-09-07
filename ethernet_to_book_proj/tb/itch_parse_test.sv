`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev:     Ian Rider
// Purpose: Verify itch_parser module
//////////////////////////////////////////////////////////////////////////////////
import tb_pkg::*;

module itch_parse_test;
    const int         CLK_250_MHZ_PERIOD = 4;

    logic             rst, clk250, packetLost, addValid, delValid, execValid, buySell, buySellStim;
    logic [15:0]      locate;
    logic [31:0]      price, shares;
    logic [63:0]      refNum;
    eth_udp_if        parserIf(clk250); // same interface as ethernet/udp parser

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
        execShares : 31'hABCD7684,
        matchNum   : 64'h3BD786555512BED7};

    assign buySellStim = (addOrder.buySell == BUY) ? 1'b1 : 1'b0;


    ////////////////////////////////////////////
    // Clock gen
    ////////////////////////////////////////////
    always #(CLK_250_MHZ_PERIOD/2) clk250 = ~clk250;

    ////////////////////////////////////////////
    // DUT
    ////////////////////////////////////////////
    itch_parser dut (
        .rstIn(rst),
        .clkIn(clk250),
        .dataIn(parserIf.data),
        .dataValidIn(parserIf.dataValid),
        .packetLostIn(packetLost),
        .addValidOut(addValid),
        .delValidOut(delValid),
        .execValidOut(execValid),
        .refNumOut(refNum),
        .locateOut(locate),
        .priceOut(price),
        .sharesOut(shares),
        .buySellOut(buySell));

    ////////////////////////////////////////////
    // Stimulus
    ////////////////////////////////////////////
    initial begin : stimulus
        rst    = 1'b1;
        clk250 = 1'b0;
        parserIf.reset();
        #20
        rst    = 1'b0;

        // Etherent packet should not exceed 1500 bytes including headers
        // ITCH parser can handle 2048 bytes of ITCH data before it will fail
        // De-asserting of dataValid (end of packet) will reset ITCH parser
        // This sends 1892 bytes of itch data without de-asserting dataValid, far more than the max IRL
        for (int i = 0; i < 22; i++) begin
            // 86 bytes total
            send_itch_order(parserIf, addOrder);
            send_itch_del_order(parserIf, delOrder);
            send_itch_exec_order(parserIf, execOrder);
        end

        @(posedge parserIf.clk);
        parserIf.dataValid = 1'b0;
        #96; // Inter-Packet Gap

        for (int i = 0; i < 22; i++) begin
            // 86 bytes total
            send_itch_order(parserIf, addOrder);
            send_itch_del_order(parserIf, delOrder);
            send_itch_exec_order(parserIf, execOrder);
        end

        @(posedge parserIf.clk);
        parserIf.dataValid = 1'b0;
        #96; // Inter-Packet Gap

        for (int i = 0; i < 22; i++) begin
            // 86 bytes total
            send_itch_order(parserIf, addOrder);
            send_itch_del_order(parserIf, delOrder);
            send_itch_exec_order(parserIf, execOrder);
        end

        @(posedge parserIf.clk);
        parserIf.dataValid = 1'b0;
        #96; // Inter-Packet Gap
    end

    ////////////////////////////////////////////
    // Output check
    ////////////////////////////////////////////
    initial begin : check_output
        for (int i = 0; i < 22; i++) begin
            @(posedge addValid);
            assert((delValid|execValid) != 1'b1) else $fatal ("Delete valid or execute valid asserted unexpectedly");
            assert(locate  == addOrder.locate)   else $fatal ("Incorrect locate received : %H Expected: %H", locate,  addOrder.locate);
            assert(refNum  == addOrder.refNum)   else $fatal ("Incorrect refNum received : %H Expected: %H", refNum,  addOrder.refNum);
            assert(buySell == buySellStim)       else $fatal ("Incorrect buySell received: %H Expected: %H", buySell, addOrder.buySell);
            assert(shares  == addOrder.shares)   else $fatal ("Incorrect shares received : %H Expected: %H", shares,  addOrder.shares);
            assert(price   == addOrder.price)    else $fatal ("Incorrect price received  : %H Expected: %H", price,   addOrder.price);
            $display("Add order: ", i, " passed.");

            @(posedge delValid);
            assert((addValid|execValid) != 1'b1) else $fatal ("Add valid or execute valid asserted unexpectedly");
            assert(locate  == delOrder.locate)   else $fatal ("Incorrect locate received : %H Expected: %H", locate,  delOrder.locate);
            assert(refNum  == delOrder.refNum)   else $fatal ("Incorrect refNum received : %H Expected: %H", refNum,  delOrder.refNum);
            $display("Delete order: ", i, " passed.");

            @(posedge execValid);
            assert((addValid|delValid) != 1'b1)  else $fatal ("Add valid or delete valid asserted unexpectedly");
            assert(locate  == execOrder.locate)  else $fatal ("Incorrect locate received : %H Expected: %H", locate,  execOrder.locate);
            assert(refNum  == execOrder.refNum)  else $fatal ("Incorrect refNum received : %H Expected: %H", refNum,  execOrder.refNum);
            $display("Execute order: ", i, " passed.");
        end

        for (int i = 0; i < 22; i++) begin
            @(posedge addValid);
            assert((delValid|execValid) != 1'b1) else $fatal ("Delete valid or execute valid asserted unexpectedly");
            assert(locate  == addOrder.locate)   else $fatal ("Incorrect locate received : %H Expected: %H", locate,  addOrder.locate);
            assert(refNum  == addOrder.refNum)   else $fatal ("Incorrect refNum received : %H Expected: %H", refNum,  addOrder.refNum);
            assert(buySell == buySellStim)       else $fatal ("Incorrect buySell received: %H Expected: %H", buySell, addOrder.buySell);
            assert(shares  == addOrder.shares)   else $fatal ("Incorrect shares received : %H Expected: %H", shares,  addOrder.shares);
            assert(price   == addOrder.price)    else $fatal ("Incorrect price received  : %H Expected: %H", price,   addOrder.price);
            $display("Add order: ", i, " passed.");

            @(posedge delValid);
            assert((addValid|execValid) != 1'b1) else $fatal ("Add valid or execute valid asserted unexpectedly");
            assert(locate  == delOrder.locate)   else $fatal ("Incorrect locate received : %H Expected: %H", locate,  delOrder.locate);
            assert(refNum  == delOrder.refNum)   else $fatal ("Incorrect refNum received : %H Expected: %H", refNum,  delOrder.refNum);
            $display("Delete order: ", i, " passed.");

            @(posedge execValid);
            assert((addValid|delValid) != 1'b1)  else $fatal ("Add valid or delete valid asserted unexpectedly");
            assert(locate  == execOrder.locate)  else $fatal ("Incorrect locate received : %H Expected: %H", locate,  execOrder.locate);
            assert(refNum  == execOrder.refNum)  else $fatal ("Incorrect refNum received : %H Expected: %H", refNum,  execOrder.refNum);
            $display("Execute order: ", i, " passed.");
        end

        for (int i = 0; i < 22; i++) begin
            @(posedge addValid);
            assert((delValid|execValid) != 1'b1) else $fatal ("Delete valid or execute valid asserted unexpectedly");
            assert(locate  == addOrder.locate)   else $fatal ("Incorrect locate received : %H Expected: %H", locate,  addOrder.locate);
            assert(refNum  == addOrder.refNum)   else $fatal ("Incorrect refNum received : %H Expected: %H", refNum,  addOrder.refNum);
            assert(buySell == buySellStim)       else $fatal ("Incorrect buySell received: %H Expected: %H", buySell, addOrder.buySell);
            assert(shares  == addOrder.shares)   else $fatal ("Incorrect shares received : %H Expected: %H", shares,  addOrder.shares);
            assert(price   == addOrder.price)    else $fatal ("Incorrect price received  : %H Expected: %H", price,   addOrder.price);
            $display("Add order: ", i, " passed.");

            @(posedge delValid);
            assert((addValid|execValid) != 1'b1) else $fatal ("Add valid or execute valid asserted unexpectedly");
            assert(locate  == delOrder.locate)   else $fatal ("Incorrect locate received : %H Expected: %H", locate,  delOrder.locate);
            assert(refNum  == delOrder.refNum)   else $fatal ("Incorrect refNum received : %H Expected: %H", refNum,  delOrder.refNum);
            $display("Delete order: ", i, " passed.");

            @(posedge execValid);
            assert((addValid|delValid) != 1'b1)  else $fatal ("Add valid or delete valid asserted unexpectedly");
            assert(locate  == execOrder.locate)  else $fatal ("Incorrect locate received : %H Expected: %H", locate,  execOrder.locate);
            assert(refNum  == execOrder.refNum)  else $fatal ("Incorrect refNum received : %H Expected: %H", refNum,  execOrder.refNum);
            $display("Execute order: ", i, " passed.");
        end

        #20;
        $display(" --- TEST PASSED ---");
        $finish;
    end

endmodule