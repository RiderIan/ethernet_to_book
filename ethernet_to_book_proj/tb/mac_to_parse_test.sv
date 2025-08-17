`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev:     Ian Rider
// Purpose: Verify MAC through ethernet parser
//////////////////////////////////////////////////////////////////////////////////
import tb_pkg::*;

module mac_to_parse_test;

    const int         CLK_250_MHZ_PERIOD = 4;
    const int         ETH_HEADER_LEN     = 14; // Not included in IP length
    const int         IP_HEADER_LEN      = 20;
    const int         UDP_HEADER_LEN     = 8;
    const int         MOLD_HEADER_LEN    = 20;

    logic rst, clk100, rxClk, txClk, txCtrl, intB, phyRstB, locked, clk250, packetLostDet;
    logic [ 3:0] txData;
    logic [ 7:0] itchData;
    logic [15:0] ipChkSum;

    rgmii_rx_if       rxIf(rxClk);
    eth_udp_output_if parserOutIf(clk250);

    // ITCH Data
    itchAddOrderType itchOrder = '{
        msgType    : ADD_MSG_TYPE,
        locate     : 16'hBE42,      // Changes everyday, used for rapid book lookup
        trackNum   : 16'h0001,
        timeStamp  : 48'h000000000000,
        refNum     : 64'hDEFB1673DEFB1673,
        buySell    : BUY,
        shares     : 32'h00000045,
        stock      : AAPL,
        price      : 32'h0022FEFC}; // Price in $0.0001 increments, this is $229.3500 for example

    int ITCH_DATA_LEN      = $bits(itchOrder)/8;
    int IP_V4_TOTAL_LEN    = ITCH_DATA_LEN + MOLD_HEADER_LEN + UDP_HEADER_LEN + IP_HEADER_LEN;
    int UDP_LENGTH         = ITCH_DATA_LEN + MOLD_HEADER_LEN + UDP_HEADER_LEN;

    // Headers
    ethHeaderType  ethHdr  =  {DEVICE_MAC, SRC_MAC, ETH_IP_V4_TYPE};
    ipHeaderType   ipHdr   =  {IP_V4_TYPE, DSCP_ECN, IP_V4_TOTAL_LEN[15:0], ID, FLAGS, TTL, PROTOCOL, 16'h0000, SRC_IP, NYSE_DST_IP};
    udpHeaderType  udpHdr  =  {NYSE_UDP_SRC_PORT, UDP_DEST_PORT, UDP_LENGTH[15:0], 16'h0000};
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

        .intBIn(intB),
        .phyRstBOut(phyRstB),
        .lockedOut(locked));

    ////////////////////////////////////////////
    // Stimulus
    ////////////////////////////////////////////
    initial begin : frame_gen_proc
        clk250        = 1'b0;
        packetLostDet = 1'b0;
        rxIf.reset();
        ipHdr.chkSum = 16'h71ED;
        ipChkSum = ip_header_chksum_calc(ipHdr);
        wait(locked);

        // Send ethernet frame header
        send_eth_header_rgmii(rxIf, ethHdr);
        send_ip_header_rgmii(rxIf, ipHdr);
        send_udp_header_rgmii(rxIf, udpHdr);
        send_mold_header_rgmii(rxIf, moldHdr);
        // Send an add order
        send_itch_order_rgmii(rxIf, itchOrder);
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
        // Send an add order
        send_itch_order_rgmii(rxIf, itchOrder);
        @(posedge rxIf.clk);
        rxIf.ctrl = 1'b0;
    end

    always @(posedge parserOutIf.packetLost) begin
        packetLostDet = 1'b1;
    end

    ////////////////////////////////////////////
    // Output check
    ////////////////////////////////////////////
    initial begin : frame_check_proc

        for (int i = 0; i < ($bits(itchOrder)/8); i++) begin
            check_eth_udp_byte(parserOutIf, itchOrder.msgType);
            itchOrder = itchOrder << 8;
        end

        #8
        assert(parserOutIf.dataValid == 1'b0) else $fatal ("Valid failed to de-assert :(");

        itchOrder = '{
            msgType    : ADD_MSG_TYPE,
            locate     : 16'hBE42,
            trackNum   : 16'h0005,
            timeStamp  : 48'h000000000123,
            refNum     : 64'h111B1673DEFB4321,
            buySell    : SELL,
            shares     : 32'h00000184,
            stock      : AAPL,
            price      : 32'h0021FEFC};

        for (int i = 0; i < ($bits(itchOrder)/8); i++) begin
            check_eth_udp_byte(parserOutIf, itchOrder.msgType);
            itchOrder = itchOrder << 8;
        end

        #8
        assert(packetLostDet == 1'b1)         else $fatal ("Packet loss was not detected :(");
        assert(parserOutIf.dataValid == 1'b0) else $fatal ("Valid failed to de-assert :(");

        #20;
        $display(" --- TEST PASSED ---");
        $finish;
    end

endmodule