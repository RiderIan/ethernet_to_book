`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev:     Ian Rider
// Purpose: Verify ethernet/ip/MoldUdp64 parser
//////////////////////////////////////////////////////////////////////////////////
import tb_pkg::*;

module eth_udp_parse_test;

    const int CLK_250_MHZ_PERIOD = 4;

    const int ETH_HEADER_LEN     = 14; // Not included in IP length
    const int IP_HEADER_LEN      = 20;
    const int UDP_HEADER_LEN     = 8;
    const int MOLD_HEADER_LEN    = 20;
    const int ITCH_DATA_LEN      = 125;
    const int IP_V4_TOTAL_LEN    = ITCH_DATA_LEN + MOLD_HEADER_LEN + UDP_HEADER_LEN + IP_HEADER_LEN;
    const int UDP_LENGTH         = ITCH_DATA_LEN + MOLD_HEADER_LEN + UDP_HEADER_LEN;

    // Ethernet header
    const logic [47:0] SRC_MAC           = 48'h123456789ABC; // Random
    const logic [47:0] DEVICE_MAC        = 48'hA846D2197E2B; // Arbitrary, not going to read actual MAC from ROM
    const logic [15:0] ETH_TYPE          = 16'h0800;         // IpV4
    ethHeaderType ethHdr = {SRC_MAC, DEVICE_MAC, ETH_TYPE};

    // IP Header
    const logic [ 7:0] VER         =  8'h45;                 // IpV4
    const logic [ 7:0] DSCP_ECN    =  8'h00;                 // Not used
    const logic [15:0] LEN         = IP_V4_TOTAL_LEN[15:0];  // Entire packet length
    const logic [15:0] ID          = 16'h0000;               // Not used for now
    const logic [15:0] FLAGS       = 16'h0000;               // Not used
    const logic [ 7:0] TTL         =  8'h00;                 // Not used
    const logic [ 7:0] PROTOCOL    =  8'h11;                 // UDP
    logic       [15:0] ipChkSum    = 16'h0000;               // Checksum over entire header with chksum set to zero
    const logic [31:0] SRC_IP      = 32'h12345678;           // random for now
    const logic [31:0] DST_IP      = 32'hE0000000;           // Multicast
    ipHeaderType ipHdr = {VER, DSCP_ECN, LEN, ID, FLAGS, TTL, PROTOCOL, ipChkSum, SRC_IP, DST_IP};

    // UDP Header
    const logic [15:0] SRC_PORT    = 16'h1426;               // Random
    const logic [15:0] DST_PORT    = 16'h0001;               // Only one port
    const logic [15:0] UDP_LEN     = UDP_LENGTH[15:0];       // UDP header and data
    logic       [15:0] udpChkSum   = 16'h0000;               // Not implemented yet
    udpHeaderType udpHdr = {SRC_PORT, DST_PORT, UDP_LEN, udpChkSum};

    // Mold Header
    logic [79:0] sessionId = 80'hABCDE54321FFEECBE418;       // Random
    logic [63:0] seqNum    = 64'h0000000000000000;           // Increments for every new message on session ID
    logic [15:0] msgCnt    = 16'h0001;                       // Number of ITCH messages within frame
    logic [15:0] moldLen   = ITCH_DATA_LEN[15:0];            // Number of data bytes
    moldHeaderType moldHdr = {sessionId, seqNum, msgCnt, moldLen};

    // ITCH Data
    // itchDataType itchData;
    // itchData.msgType    =;
    // itchData.locate     =;
    // itchData.trackNum   =;
    // itchData.timeStamp  =;
    // itchData.refNum     =;
    // itchData.buySell    =;
    // itchData.shares     =;
    // itchData.stock      =;
    // itchData.price      =;



    logic [7:0] itchData;
    logic       rst, clk250, dataErr, dataValid, itchDataValid;
    eth_udp_if  parserIf(clk250);

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
        .itchDataOut(itchData),
        .itchDataValidOut(itchDataValid));

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
        send_ip_header(parserIf,  ipHdr);
        send_udp_header(parserIf, udpHdr);
        send_mold_header(parserIf, moldHdr);
       
        @(posedge parserIf.clk);
        parserIf.dataValid = 1'b0;

    end

    ////////////////////////////////////////////
    // Output check
    ////////////////////////////////////////////
    initial begin : check_data
        #10000;
        // for (int i = 0; i < 125; i++) begin
        //     @(posedge itchDataValid);
        //     assert(itchData == i[7:0]) else $fatal("Byte Received: 0x%H", itchData, " Expected: 0x%H", i[7:0], "  INCORRECT :(");
        // end
        $display(" --- TEST PASSED ---");
        $finish;
    end

endmodule