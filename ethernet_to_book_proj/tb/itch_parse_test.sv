`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev:     Ian Rider
// Purpose: Verify itch_parser module
//////////////////////////////////////////////////////////////////////////////////
import tb_pkg::*;

module itch_parse_test;
    const int         CLK_250_MHZ_PERIOD = 4;

    logic               rst, clk250, packetLost, buySell;
    logic [15:0]        locate;
    logic [31:0]        price, shares;
    logic [63:0]        refNum;
    itch_add_output_if  addIf(clk250);
    itch_del_output_if  delIf(clk250);
    itch_exec_output_if execIf(clk250);
    eth_udp_if          parserIf(clk250); // same interface as ethernet/udp parser


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
        .addValidOut(addIf.valid),
        .delValidOut(delIf.valid),
        .execValidOut(execIf.valid),
        .refNumOut(refNum),
        .locateOut(locate),
        .priceOut(price),
        .sharesOut(shares),
        .buySellOut(buySell));

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

        // Inter-Packet Gap
        @(posedge parserIf.clk);
        parserIf.dataValid = 1'b0;
        #96;

        for (int i = 0; i < 22; i++) begin
            // 86 bytes total
            send_itch_order(parserIf, addOrder);
            send_itch_del_order(parserIf, delOrder);
            send_itch_exec_order(parserIf, execOrder);
        end

        // Inter-Packet Gap
        @(posedge parserIf.clk);
        parserIf.dataValid = 1'b0;
        #96;

        for (int i = 0; i < 22; i++) begin
            // 86 bytes total
            send_itch_order(parserIf, addOrder);
            send_itch_del_order(parserIf, delOrder);
            send_itch_exec_order(parserIf, execOrder);
        end

        @(posedge parserIf.clk);
        parserIf.dataValid = 1'b0;
    end

    ////////////////////////////////////////////
    // Output check
    ////////////////////////////////////////////
    initial begin : check_output
        for (int i = 0; i < 3; i++) begin
            for (int j = 0; j < 22; j++) begin
                check_itch_add(addIf, addOrder);
                assert((delIf.valid|execIf.valid) != 1'b1) else $fatal ("Delete valid or execute valid asserted unexpectedly");
                $display("Add order: ", i, " ", j, " passed.");

                check_itch_del(delIf, delOrder);
                assert((addIf.valid|execIf.valid) != 1'b1) else $fatal ("Add valid or execute valid asserted unexpectedly");
                $display("Delete order: ", i, " ", j, " passed.");

                check_itch_exec(execIf, execOrder);
                assert((addIf.valid|delIf.valid) != 1'b1)  else $fatal ("Add valid or delete valid asserted unexpectedly");
                $display("Execute order: ", i, " ", j, " passed.");
            end
        end

        #20;
        $display(" --- TEST PASSED ---");
        $finish;
    end

endmodule