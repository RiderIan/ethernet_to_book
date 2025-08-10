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
    const logic [ 7:0] ADD_MSG_TYPE      = 8'h41;               // "A" ascii
    const logic [ 7:0] EXECUTED_MSG_TYPE = 8'h45;               // "E" ascii
    const logic [ 7:0] CANCEL_MSG_TYPE   = 8'h58;               // "X" ascii
    const logic [ 7:0] BUY               = 8'h42;               // "B" ascii
    const logic [ 7:0] SELL              = 8'h53;               // "S" ascii
    const logic [63:0] AAPL              = 8'h4141504C00000000; // "APPL" ascii -> APPLE symbol

    // Ethernet header
    const logic [47:0] DEVICE_MAC        = 48'hA846D2197E2B;    // Arbitrary for now
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
    const logic [31:0] NYSE_DST_IP       = 32'hE0000000;        // NYSE integrated feed multicast dest

    // UDP header
    const logic [15:0] NYSE_UDP_SRC_PORT = 16'h3E80;       
    const logic [15:0] UDP_DEST_PORT     = 16'h2710;

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
    } itchOrderExecutedType;

endpackage;