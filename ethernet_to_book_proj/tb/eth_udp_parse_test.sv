`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev:     Ian Rider
// Purpose: Verify ethernet/ip/MoldUdp64 parser
//////////////////////////////////////////////////////////////////////////////////
import tb_pkg::*;

module eth_udp_parse_test;

    const int         CLK_250_MHZ_PERIOD = 4;

    const int         ETH_HEADER_LEN     = 14; // Not included in IP length
    const int         IP_HEADER_LEN      = 20;
    const int         UDP_HEADER_LEN     = 8;
    const int         MOLD_HEADER_LEN    = 20;

    logic             rst, clk250, dataErr, dataValid;
    eth_udp_if        parserIf(clk250);
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

    // Ethernet header
    ethHeaderType ethHdr = {DEVICE_MAC, SRC_MAC, ETH_IP_V4_TYPE};

    // IP Header
    ipHeaderType ipHdr = {IP_V4_TYPE, DSCP_ECN, IP_V4_TOTAL_LEN[15:0], ID, FLAGS, TTL, PROTOCOL, 16'h0000, SRC_IP, NYSE_DST_IP};

    // UDP Header
    udpHeaderType udpHdr = {NYSE_UDP_SRC_PORT, UDP_DEST_PORT, UDP_LENGTH[15:0], 16'h0000};

    // Mold Header
    moldHeaderType moldHdr = '{
        sessId    : 80'hABCDE54321FFEECBE418, // Random
        seqNum    : 64'h0000000000000000,     // Increments for every new message on session ID
        msgCnt    : 16'h0001,                 // Number of ITCH messages within frame
        moldLen   : ITCH_DATA_LEN[15:0]};     // Number of data bytes

    ////////////////////////////////////////////
    // Clock gen
    ////////////////////////////////////////////
    always #(CLK_250_MHZ_PERIOD/2) clk250 = ~clk250;

    ////////////////////////////////////////////
    // DUT: rxClkLcl(125Mhz) -> 250Mhz CDC
    ////////////////////////////////////////////
    eth_udp_parser dut (
        .rstIn(rst),
        .clkIn(clk250),
        .dataIn(parserIf.data),
        .dataValidIn(parserIf.dataValid),
        .dataErrIn(parserIf.dataErr),
        .itchDataOut(parserOutIf.data),
        .itchDataValidOut(parserOutIf.dataValid));

    ////////////////////////////////////////////
    // Stimulus
    ////////////////////////////////////////////
    initial begin : drive_data
        rst    = 1'b1;
        clk250 = 1'b0;
        parserIf.reset();
        #20;
        rst    = 1'b0;

        // Send ethernet frame header
        send_eth_header(parserIf, ethHdr);
        send_ip_header(parserIf, ipHdr);
        send_udp_header(parserIf, udpHdr);
        send_mold_header(parserIf, moldHdr);
        // Send an add order
        send_itch_order(parserIf, itchOrder);
        @(posedge parserIf.clk);
        parserIf.dataValid = 1'b0;

        #10000;
        
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

        // Send ethernet frame header
        send_eth_header(parserIf, ethHdr);
        send_ip_header(parserIf, ipHdr);
        send_udp_header(parserIf, udpHdr);
        send_mold_header(parserIf, moldHdr);
        // Send an add order
        send_itch_order(parserIf, itchOrder);

    end

    ////////////////////////////////////////////
    // Output check
    ////////////////////////////////////////////
    initial begin : check_data

        @(posedge parserOutIf.dataValid);
        for (int i = 0; i < ($bits(itchOrder)/8); i++) begin
            check_eth_udp_byte(parserOutIf, itchOrder.msgType);
            itchOrder = itchOrder << 8;
        end

        @(posedge parserOutIf.clk);
        assert(parserOutIf.dataValid == 1'b0) else $fatal ("Valid failed to de-assert :(");

        @(posedge parserOutIf.dataValid);
        for (int i = 0; i < ($bits(itchOrder)/8); i++) begin
            check_eth_udp_byte(parserOutIf, itchOrder.msgType);
            itchOrder = itchOrder << 8;
        end

        #20;
        $display(" --- TEST PASSED ---");
        $finish;
    end

endmodule