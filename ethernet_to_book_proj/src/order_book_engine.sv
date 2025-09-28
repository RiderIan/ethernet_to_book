`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev: Ian Rider
// Purpose: Order book and order map engine top level. Supports add, delete, and
//          executed message types.
//////////////////////////////////////////////////////////////////////////////////
`include "order_book.sv"
`include "order_map.sv"
import pkg::*;

module order_book_engine # (
    parameter int ORDER_MAP_DEPTH,     // Must be power of two
    parameter int ORDER_BOOK_DEPTH) (

    input  logic        rstIn,
    input  logic        clkIn,

    input  logic        addValidIn,
    input  logic        delValidIn,
    input  logic        execValidIn,

    input  logic [63:0] refNumIn,
    input  logic [15:0] locateIn,
    input  logic [31:0] priceIn,
    input  logic [31:0] sharesIn,
    input  logic        buySellIn);

    logic delExecValid, buySell;
    logic [15:0] locate;
    logic [31:0] price, shares;

    ////////////////////////////////////////////
    // Order map
    ////////////////////////////////////////////
    order_map # (
        .ORDER_MAP_DEPTH(ORDER_MAP_DEPTH))
    order_map_inst (
        .rstIn(rstIn),
        .clkIn(clkIn),
        .addValidIn(addValidIn),
        .delValidIn(delValidIn),
        .execValidIn(execValidIn),
        .refNumIn(refNumIn),
        .locateIn(locateIn),
        .priceIn(priceIn),
        .sharesIn(sharesIn),
        .buySellIn(buySellIn),
        .delExecValidOut(delExecValid),
        .locateOut(locate),
        .priceOut(price),
        .sharesOut(shares),
        .buySellOut(buySell));

    ////////////////////////////////////////////
    // Order book
    ////////////////////////////////////////////
    (* keep = "true", dont_touch = "true" *)
    order_book # (
        .ORDER_BOOK_DEPTH(ORDER_BOOK_DEPTH))
    order_book_inst (
        .rstIn(rstIn),
        .clkIn(clkIn),
        .addValidIn(addValidIn),
        .delExecValidIn(delExecValid),
        .locateIn(locateIn),
        .priceIn(priceIn),
        .sharesIn(sharesIn),
        .buySellIn(buySellIn),
        .mapLocateIn(locate),
        .mapPriceIn(price),
        .mapSharesIn(shares),
        .mapBuySellIn(buySell));





endmodule