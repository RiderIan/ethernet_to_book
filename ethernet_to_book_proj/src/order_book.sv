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

(* keep = "true", dont_touch = "true" *)
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

    logic [31:0]  buySidePriceRamR    [1:ORDER_BOOK_DEPTH];
    logic [31:0]  buySideQuantityRamR [1:ORDER_BOOK_DEPTH];
    logic [31:0]  buyPriceLevelsR     [1:ORDER_BOOK_DEPTH];
    logic [31:0]  buyPriceLevelsRR    [1:ORDER_BOOK_DEPTH];
    logic [31:0]  buyQuantityLevelsR  [1:ORDER_BOOK_DEPTH];
    logic [31:0]  buyQuantityLevelsRR [1:ORDER_BOOK_DEPTH];
    logic [31:0]  priceR, priceFindIdxR, sharesR, checkPriceMatchR;
    logic [ 2:0]  buyMatchIdxR, buyInsertIdxR, sellMatchIdx, sellInsertIdx;
    logic         addBuyR, insertSell, doAddR, addValidR, addValidRR, buySellR;

    ////////////////////////////////////////////
    // Necessary registers for delays/timing closure
    ////////////////////////////////////////////
    always_ff @(posedge clkIn) begin : input_regs
        priceR        <= priceIn;
        priceFindIdxR <= priceIn;
        sharesR       <= sharesIn;
        buySellR      <= buySellIn;
    end

    always_ff @(posedge clkIn) begin : valid_reg
        if (rstIn) begin
            addValidR  <= 1'b0;
            addValidRR <= 1'b0;
        end else begin
            addValidR  <= addValidIn;
            addValidRR <= addValidR;
        end
    end

    ////////////////////////////////////////////
    // LUT ram read backs for easier routing
    ////////////////////////////////////////////
    always_ff @(posedge clkIn) begin : buy_read_lut_ram
        if (rstIn) begin
            buyPriceLevelsR     <= {default:'0};
            buyQuantityLevelsR  <= {default:'0};
            buyPriceLevelsRR    <= {default:'0};
            buyQuantityLevelsRR <= {default:'0};
        end else begin
            for (int idx = 1; idx <= ORDER_BOOK_DEPTH; idx++) begin
                buyPriceLevelsR[idx]     <= buySidePriceRamR[idx];
                buyPriceLevelsRR[idx]    <= buyPriceLevelsR[idx];
                buyQuantityLevelsR[idx]  <= buySideQuantityRamR[idx];
                buyQuantityLevelsRR[idx] <= buyQuantityLevelsR[idx];
            end
        end
    end

    ////////////////////////////////////////////
    // Find insert and add index
    ////////////////////////////////////////////
    always_ff @(posedge clkIn) begin : buy_insert_idx
        for (logic [2:0] idx = ORDER_BOOK_DEPTH[2:0]; idx > 3'h0; idx--) begin
            if (priceFindIdxR > buyPriceLevelsRR[idx])
                buyInsertIdxR <= idx[2:0];
        end
    end

    always_ff @(posedge clkIn) begin : buy_add_idx
        addBuyR <= 1'b0;
        for (logic [2:0] idx = ORDER_BOOK_DEPTH[2:0]; idx > 3'h0; idx--) begin
           if (priceFindIdxR == buyPriceLevelsRR[idx]) begin
               buyMatchIdxR <= idx[2:0];
               addBuyR      <= 1'b1;
           end
        end
    end


    ////////////////////////////////////////////
    // Update buy side book logic
    ////////////////////////////////////////////
    always_ff @(posedge clkIn) begin : update_book
        if (rstIn) begin
            buySidePriceRamR    <= {default:'0};
            buySideQuantityRamR <= {default:'0};
        end else begin
            // Insert add order
            for (int idx = 1; idx <= ORDER_BOOK_DEPTH; idx++) begin
                if (addValidRR & ~addBuyR & buySellR) begin

                    if (idx > buyInsertIdxR) begin
                        buySidePriceRamR[idx]    <= buyPriceLevelsRR[idx-1];
                        buySideQuantityRamR[idx] <= buyQuantityLevelsRR[idx-1];
                    end

                    if (idx == buyInsertIdxR) begin
                        buySidePriceRamR[idx]    <= priceR;
                        buySideQuantityRamR[idx] <= sharesR;
                    end

                end
            end

            // Increment add order
            if (addValidRR & addBuyR & buySellR) begin
                buySideQuantityRamR[buyMatchIdxR] <= buyQuantityLevelsRR[buyMatchIdxR] + sharesR;
            end
        end

    end

    // TEMP
    assign topBuyOut = buyInsertIdxR;

endmodule