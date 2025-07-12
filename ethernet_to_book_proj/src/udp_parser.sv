`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev: Ian Rider
// Purpose: 
//////////////////////////////////////////////////////////////////////////////////
`include "rgmii_rx.sv"
`include "rgmii_tx.sv"

module udp_parser (
    input logic rstIn,
    input logic clkIn,

    // Fifo control
    output logic rdEnOut,
    input  logic rdEmptyIn,


);

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



endmodule