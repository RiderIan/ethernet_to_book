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
    input logic         mapBuySellIn);

    localparam int ADDR_BITS = $clog2(ORDER_BOOK_DEPTH);

    logic [31:0]  buySidePriceRamR    [1:ORDER_BOOK_DEPTH];
    logic [31:0]  buySideQuantityRamR [1:ORDER_BOOK_DEPTH];
    logic [31:0]  buyPriceLevelsR     [1:ORDER_BOOK_DEPTH];
    logic [31:0]  buyPriceLevelsRR    [1:ORDER_BOOK_DEPTH];
    logic [31:0]  buyQuantityLevelsR  [1:ORDER_BOOK_DEPTH];
    logic [31:0]  buyQuantityLevelsRR [1:ORDER_BOOK_DEPTH];

    logic [31:0]  sellSidePriceRamR    [1:ORDER_BOOK_DEPTH];
    logic [31:0]  sellSideQuantityRamR [1:ORDER_BOOK_DEPTH];
    logic [31:0]  priceDlyR, mapPriceDlyR, priceFindIdxR, sharesR, sharesDlyR, checkPriceMatchR, mapSharesDlyR;
    logic [ORDER_BOOK_DEPTH:1] compInsertOneHot, compMatchOneHot;
    logic [ADDR_BITS-1:0]      buyMatchIdxR, buyInsertIdxR, sellMatchIdx, sellInsertIdx, compInsert;
    logic         matchFoundR, insertSell, doAddR, addValidR, addValidDlyR, delExecValidDlyR, buySellDlyR, mapBuySellDlyR, bookUpdatedR, bookUpdatedRR;

    ////////////////////////////////////////////
    // Necessary registers for delays/fanout/timing closure
    ////////////////////////////////////////////
    pipe #(.DEPTH(2), .WIDTH(32)) price_reg_inst          (.rstIn(1'b0),  .clkIn(clkIn), .DIn(priceIn),        .QOut(priceDlyR));
    pipe #(.DEPTH(2), .WIDTH(32)) shares_reg_inst         (.rstIn(1'b0),  .clkIn(clkIn), .DIn(sharesIn),       .QOut(sharesDlyR));
    pipe #(.DEPTH(2), .WIDTH(32)) map_price_reg_inst      (.rstIn(1'b0),  .clkIn(clkIn), .DIn(mapPriceIn),     .QOut(mapPriceDlyR));
    pipe #(.DEPTH(2), .WIDTH(32)) map_shares_reg_inst     (.rstIn(1'b0),  .clkIn(clkIn), .DIn(mapSharesIn),    .QOut(mapSharesDlyR));
    pipe #(.DEPTH(2), .WIDTH( 1)) buy_sell_reg_inst       (.rstIn(1'b0),  .clkIn(clkIn), .DIn(buySellIn),      .QOut(buySellDlyR));
    pipe #(.DEPTH(2), .WIDTH( 1)) map_buy_sell_reg_inst   (.rstIn(1'b0),  .clkIn(clkIn), .DIn(mapBuySellIn),   .QOut(mapBuySellDlyR));
    pipe #(.DEPTH(2), .WIDTH( 1)) add_valid_reg_inst      (.rstIn(rstIn), .clkIn(clkIn), .DIn(addValidIn),     .QOut(addValidDlyR));
    pipe #(.DEPTH(2), .WIDTH( 1)) del_exec_valid_reg_inst (.rstIn(rstIn), .clkIn(clkIn), .DIn(delExecValidIn), .QOut(delExecValidDlyR));

    always_ff @(posedge clkIn) begin : price_idx_mux
        priceFindIdxR <= addValidIn     ? priceIn :
                         delExecValidIn ? mapPriceIn : '0;
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
        matchFoundR <= 1'b0;
        for (logic [2:0] idx = ORDER_BOOK_DEPTH[2:0]; idx > 3'h0; idx--) begin
           if (priceFindIdxR == buyPriceLevelsRR[idx]) begin
               buyMatchIdxR <= idx[2:0];
               matchFoundR  <= 1'b1;
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
                if (addValidDlyR & buySellDlyR) begin

                    if ((idx > buyInsertIdxR) & ~matchFoundR) begin
                        buySidePriceRamR[idx]    <= buyPriceLevelsRR[idx-1];
                        buySideQuantityRamR[idx] <= buyQuantityLevelsRR[idx-1];
                    end

                    if ((idx == buyInsertIdxR) & ~matchFoundR) begin
                        buySidePriceRamR[idx]    <= priceDlyR;
                        buySideQuantityRamR[idx] <= sharesDlyR;
                    end

                    if ((idx == buyMatchIdxR) & matchFoundR)
                        buySideQuantityRamR[idx] <= buyQuantityLevelsRR[idx] + sharesDlyR;

                end

                if ((idx == buyMatchIdxR) & delExecValidDlyR & matchFoundR & buySellDlyR)
                    buySideQuantityRamR[idx] <= buyQuantityLevelsRR[idx] - mapSharesDlyR;
            end
        end
    end

    always_ff @(posedge clkIn) begin : ila_trig_reg
        if (rstIn) begin
            bookUpdatedR  <= 1'b0;
            bookUpdatedRR <= 1'b0;
        end else begin
            bookUpdatedR  <= addValidDlyR | delExecValidDlyR;
            bookUpdatedRR <= bookUpdatedR;
        end
    end

    top_of_book_ila book_ila_inst (
        .clk(clkIn),
        .trig_in(bookUpdatedRR),
        .probe0({buySidePriceRamR[1], buySideQuantityRamR[1]}),
        .probe1({sellSidePriceRamR[1], sellSideQuantityRamR[1]}));

endmodule