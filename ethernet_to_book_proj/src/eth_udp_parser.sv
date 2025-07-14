`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev: Ian Rider
// Purpose: Parser ethernet and MoldUdp64 headers, pass itch data straight through
//////////////////////////////////////////////////////////////////////////////////

module eth_udp_parser (
    input  logic       rstIn,
    input  logic       clkIn,

    // CDC interface
    input  logic [7:0] dataIn,
    input  logic       dataValidIn,
    input  logic       dataErrIn,
   
    output logic [7:0] itchDataOut,
    output logic       itchDataValidOut);

    // Header byte offsets that matter
    const int DEST_MAC     = 0;
    const int SRC_MAC      = 6;
    const int ETH_TYPE     = 12;
    const int TOTAL_LENGTH = 15;
    const int PROTOCOL     = 17;
    const int UDP_SRC      = 26;
    const int UDP_DST      = 28;
    const int UDP_LENGTH   = 30;
    const int UDP_CHKSUM   = 32;
    const int MOLD_SESH    = 34;
    const int MOLD_SEQ_NUM = 44;
    const int MOLD_MSG_CNT = 52;
    const int ITCH_MSG_LEN = 54;
    const int ITCH_MSG     = 56;

    int unsigned byteCntR;
    logic dataValidR, dataLastDetR, ipV4CheckR, passItchR;

    ////////////////////////////////////////////
    // Ethernet header capture
    ////////////////////////////////////////////
    typedef struct packed {
        logic [47:0] dstMac;
        logic [47:0] srcMac;
        logic [15:0] ethType;
    } ethHeaderType;
    ethHeaderType ethHeaderR;

    always_ff @(posedge clkIn) begin : eth_header_capture
        if (dataValidIn & (byteCntR < (ETH_TYPE + 2)))
            ethHeaderR <= (ethHeaderR << 8) | dataIn;  
    end

    always_ff @(posedge clkIn) begin : ip_v_4_chk
        if (rstIn) begin
            ipV4CheckR <= 1'b0;
        end else begin  
            // Check for IPv4 -> ignore if not
            if ((byteCntR == (ETH_TYPE+2)) && (ethHeaderR.ethType == 16'h0800))
                ipV4CheckR <= 1'b1;
            else
                ipV4CheckR <= 1'b0;
        end
    end

    ////////////////////////////////////////////
    // IPv4 header capture
    ////////////////////////////////////////////
    typedef struct packed {
        logic [ 7:0] ver;
        logic [ 7:0] dscpEcn;
        logic [15:0] len;
        logic [15:0] id;
        logic [15:0] flags;
        logic [ 7:0] ttl;
        logic [ 7:0] protocol;
        logic [15:0] chkSum;
        logic [31:0] srcIp;
        logic [31:0] dstIp;
    } ipHeaderType;
    ipHeaderType ipHeaderR;

    always_ff @(posedge clkIn) begin : ip_header_capture
        ipHeaderR <= (ipHeaderR << 8) | dataIn;
    end

    ////////////////////////////////////////////
    // UDP & MoldUDP64 header capture TODO: Continue here
    ////////////////////////////////////////////
    typedef struct packed {
        logic [15:0] srcPort;
        logic [15:0] dstPort;
        logic [15:0] udpLen;
        logic [15:0] chkSum;
        logic [79:0] sessId;
        logic [63:0] seqNum;
        logic [15:0] msgCnt;
        logic [15:0] moldLen;
    } udpHeaderType;
    udpHeaderType udpHeaderR;

    always_ff @(posedge clkIn) begin : udp_header_capture
        if (dataValidIn & (byteCntR < MOLD_MSG_CNT+2))
            udpHeaderR <= (udpHeaderR << 8) | dataIn; 
    end

    // Look for nyse
    // always_ff @(posedge clkIn) begin : source_chk
    //     if (rstIn) begin
    //     end else begin
    //         if ((byteCntR == (ETH_TYPE+2)) &&)
    //     end
    // end

    ////////////////////////////////////////////
    // ITCH passthrough control TODO: Drive passItchR here
    ////////////////////////////////////////////
    assign itchDataOut      = dataIn;
    assign itchDataValidOut = (dataValidIn & passItchR);

    ////////////////////////////////////////////
    // Byte cnt of current frame
    ////////////////////////////////////////////
    always_ff @(posedge clkIn) begin
        if (rstIn) begin
            byteCntR <= 0;
        end else begin
            if (dataValidIn) begin
                if (dataLastDetR||dataErrIn)
                    byteCntR <= 0;
                else
                    byteCntR <= byteCntR + 1;
            end
        end
    end





endmodule