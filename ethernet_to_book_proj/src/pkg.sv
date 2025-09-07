`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev: Ian Rider
// Purpose: Structs/interfaces common between src and tb
//////////////////////////////////////////////////////////////////////////////////

package pkg;

    ////////////////////////////////////////////
    // Constants
    ////////////////////////////////////////////
    // ITCH
    const logic [ 7:0] ADD_MSG_TYPE      =  8'h41;               // "A" ascii
    const logic [ 7:0] EXECUTED_MSG_TYPE =  8'h45;               // "E" ascii
    const logic [ 7:0] DELETE_MSG_TYPE   =  8'h44;               // "D" ascii
    const logic [ 7:0] BUY               =  8'h42;               // "B" ascii
    const logic [ 7:0] SELL              =  8'h53;               // "S" ascii
    const logic [63:0] AAPL              = 64'h4141504C00000000; // "APPL" ascii -> APPLE symbol

    // Ethernet header
    // IpV4 Multicast -> 01:00:5E
    // Lower 23-bits are lower 23 of IP dest address
    // bit 24 is forced to '0'
    const logic [47:0] DEVICE_MAC        = 48'h01005E7D8B20;
    const logic [47:0] SRC_MAC           = 48'h123456789ABC;    // Random
    const logic [15:0] ETH_IP_V4_TYPE    = 16'h0800;            // IpV4
    const logic [15:0] ETH_IP_V6_TYPE    = 16'h86DD;            // IpV6

    // IP header
    const logic [ 7:0] IP_V4_TYPE        =  8'h45;              // IpV4
    const logic [ 7:0] DSCP_ECN          =  8'h00;              // Not used
    const logic [15:0] ID                = 16'h0000;            // Not used for now
    const logic [15:0] FLAGS             = 16'h0000;            // Not used
    const logic [ 7:0] TTL               =  8'h00;              // Not used
    const logic [ 7:0] PROTOCOL          =  8'h11;              // UDP
    const logic [31:0] SRC_IP            = 32'h12345678;        // random for now
    const logic [31:0] DST_IP            = 32'h8AFD8B20;        // BX TotalView-ITCH feed in Chicago

    // UDP header
    const logic [15:0] UDP_SRC_PORT      = 16'h2710;            // Not fixed/unknown
    const logic [15:0] UDP_DEST_PORT     = 16'h4696;            // BX TotalView-ITCH feed

    ////////////////////////////////////////////
    // Structs common between src and tb
    ////////////////////////////////////////////
    typedef struct packed {
        logic [47:0] dstMac;
        logic [47:0] srcMac;
        logic [15:0] ethType;
    } ethHeaderType;

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

    typedef struct packed {
        logic [15:0] srcPort;
        logic [15:0] dstPort;
        logic [15:0] len;
        logic [15:0] chkSum;
    } udpHeaderType;

    typedef struct packed {
        logic [79:0] sessId;
        logic [63:0] seqNum;
        logic [15:0] msgCnt;
        logic [15:0] moldLen;
    } moldHeaderType;

    typedef struct packed {
        logic [ 7:0] msgType;
        logic [15:0] locate;
        logic [15:0] trackNum;
        logic [47:0] timeStamp;
        logic [63:0] refNum;
        logic [ 7:0] buySell;
        logic [31:0] shares;
        logic [63:0] stock;
        logic [31:0] price;
    } itchAddOrderType;

    typedef struct packed {
        logic [ 7:0] msgType;
        logic [15:0] locate;
        logic [15:0] trackNum;
        logic [47:0] timeStamp;
        logic [63:0] refNum;
    } itchDeleteOrderType;

    typedef struct packed {
        logic [ 7:0] msgType;
        logic [15:0] locate;
        logic [15:0] trackNum;
        logic [47:0] timeStamp;
        logic [63:0] refNum;
        logic [31:0] execShares;
        logic [63:0] matchNum;
    } itchOrderExecutedType;


    virtual class grayBin #(int WIDTH);
        static function automatic logic [WIDTH-1:0] bin2gray (input logic [WIDTH-1:0] bin);
            return (bin >> 1) ^ bin;
        endfunction

        static function automatic logic [WIDTH-1:0] gray2bin (input logic [WIDTH-1:0] gray);
            logic [WIDTH-1:0] bin;
            bin[WIDTH-1] = gray[WIDTH-1];
            for (int i = WIDTH-2; i >= 0; i--) begin
                bin[i] = bin[i+1] ^ gray[i];
            end
            return bin;
        endfunction
    endclass

endpackage;