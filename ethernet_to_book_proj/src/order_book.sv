`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev: Ian Rider
// Purpose: Variable depth order book supports add, delete, and execute messages.
//////////////////////////////////////////////////////////////////////////////////
import pkg::*;

module order_book # (
    parameter int ORDER_BOOK_DEPTH)(

    input logic        rstIn,
    input logic        clkIn,

    input logic        addValidIn,
    input logic        delExecValidIn,

    input logic [15:0] locateIn,
    input logic [31:0] priceIn,
    input logic [31:0] sharesIn,
    input logic        buySellIn,

    input logic [15:0] mapLocateIn,
    input logic [31:0] mapPriceIn,
    input logic [31:0] mapSharesIn,
    input logic        mapBuySellIn);

endmodule