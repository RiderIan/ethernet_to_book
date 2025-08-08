`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev: Ian Rider
// Purpose: Structs/interfaces common between src and tb 
//////////////////////////////////////////////////////////////////////////////////

package pkg;

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