`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev: Ian Rider
// Purpose: Variable depth order book supports add, delete, and execute messages.
//////////////////////////////////////////////////////////////////////////////////
import pkg::*;

////////////////////////////////////////////
// IN PROGRESS
////////////////////////////////////////////

////////////////////////////////////////////
// IN PROGRESS
////////////////////////////////////////////

module order_book # (
    parameter int ORDER_BOOK_DEPTH)(

    input logic         rstIn,
    input logic         clkIn,

    input logic         addValidIn,
    input logic         delExecValidIn,

    input logic [15:0]  locateIn,
    input logic [31:0]  priceIn,
    input logic [31:0]  sharesIn,
    input logic         buySellIn,

    input logic [15:0]  mapLocateIn,
    input logic [31:0]  mapPriceIn,
    input logic [31:0]  mapSharesIn,
    input logic         mapBuySellIn,

    output logic [63:0] topBuyOut,   // temp
    output logic [63:0] topSellOut); // temp

    bookLevelType buySideRamR  [1:ORDER_BOOK_DEPTH];
    bookLevelType sellSideRamR [1:ORDER_BOOK_DEPTH];
    logic [ 2:0]  buyMatchIdx, buyInsertIdx, sellMatchIdx, sellInsertIdx;
    logic         insertBuy, insertSell;

    // TODO: make variable depth
    assign buyMatchIdx  = (priceIn == buySideRamR[1].price) ? 3'h1 :
                          (priceIn == buySideRamR[2].price) ? 3'h2 :
                          (priceIn == buySideRamR[3].price) ? 3'h3 :
                          (priceIn == buySideRamR[4].price) ? 3'h4 :
                          (priceIn == buySideRamR[5].price) ? 3'h5 : 3'h0;

    // TODO: make variable depth
    assign buyInsertIdx = (priceIn > buySideRamR[1].price) ? 3'h1 :
                          (priceIn > buySideRamR[2].price) ? 3'h2 :
                          (priceIn > buySideRamR[3].price) ? 3'h3 :
                          (priceIn > buySideRamR[4].price) ? 3'h4 :
                          (priceIn > buySideRamR[5].price) ? 3'h5 : 3'h0;

    assign insertBuy = (buyInsertIdx < 3'h6) &  (buyMatchIdx == 3'h0);
    assign addBuy    = (buyMatchIdx != 3'h0);


    ////////////////////////////////////////////
    // Insert and shift buy
    ////////////////////////////////////////////
    always_ff @(posedge clkIn) begin
        if (rstIn) begin
            buySideRamR <= {default:'0};
        end else begin
            for (int idx = 1; idx < ORDER_BOOK_DEPTH + 1; idx++) begin
                if (addValidIn & insertBuy & buySellIn) begin
                    buySideRamR[idx].quantity <= (idx < buyInsertIdx)  ? buySideRamR[idx].quantity :
                                                 (idx == buyInsertIdx) ? sharesIn :
                                                 buySideRamR[idx-1].quantity;

                    buySideRamR[idx].price    <= (idx < buyInsertIdx)  ? buySideRamR[idx].price :
                                                 (idx == buyInsertIdx) ? priceIn :
                                                 buySideRamR[idx-1].price;
                end
            end

            // TODO: This feed back is not timing friendly, need to figure something else out bc the above passes timing alone
            if (addValidIn & addBuy & buySellIn) begin
                buySideRamR[buyMatchIdx].quantity <= buySideRamR[buyMatchIdx].quantity + sharesIn;
            end
        end
    end

    // TODO: Pretty much copy and past buy side here
    ////////////////////////////////////////////
    // Insert and shift sell
    ////////////////////////////////////////////

    // temp for sythesis
    assign topBuyOut = buySideRamR[1];



endmodule