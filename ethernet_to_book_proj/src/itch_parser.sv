`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev: Ian Rider
// Purpose: Parses itch messages and output to book builder
//////////////////////////////////////////////////////////////////////////////////
import pkg::*;

module eth_udp_parser (
    input  logic        rstIn,
    input  logic        clkIn,

    input  logic [ 7:0] dataIn,
    input  logic        dataValidIn,
    input  logic        packetLostIn,

    output logic        msgValidOut,
    output logic [ 1:0] msgTypeOut,
    output logic [15:0] locateOut,
    output logic        buySellOut,
    output logic [31:0] sharesOut,
    output logic [31:0] priceOut);

endmodule