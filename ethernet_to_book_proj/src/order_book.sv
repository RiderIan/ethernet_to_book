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
    parameter int DEPTH)(

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

    localparam int ADDR_BITS = $clog2(DEPTH);

    // Buy side book
    logic [31:0]  buyPriceLevelsR  [1:DEPTH];
    logic [31:0]  buyQuantLevelsR  [1:DEPTH];
    logic [31:0]  bAddPriceLevelsR [1:DEPTH];
    logic [31:0]  bAddQuantLevelsR [1:DEPTH];
    logic [31:0]  bDelPriceLevelsR [1:DEPTH];
    logic [31:0]  bDelQuantLevelsR [1:DEPTH];

    // Sell Side book
    logic [31:0]  sellPriceLevelsR [1:DEPTH];
    logic [31:0]  sellQuantLevelsR [1:DEPTH];
    logic [31:0]  sAddPriceLevelsR [1:DEPTH];
    logic [31:0]  sAddQuantLevelsR [1:DEPTH];
    logic [31:0]  sDelPriceLevelsR [1:DEPTH];
    logic [31:0]  sDelQuantLevelsR [1:DEPTH];

    logic [31:0]  sharesSumR        [1:DEPTH];
    logic [16:0]  sharesDiffR       [1:DEPTH];

    logic [31:0]  priceR, sharesR, mapPriceR, mapSharesR;
    logic [DEPTH:1] priceMatchR, priceGreatR, priceLessR, mapPriceMatchR, mapQuantMatchR, mapPriceLessR, buyAddWrEnR, buyDelWrEnR, sellAddWrEnR, sellDelWrEnR;;
    logic addValidR, delExecValidR, buyUpdatedR, sellUpdatedR, buySellR, mapBuySellR, anyPriceMatchR, anyMapPriceMatchR, anyMapQuantMatchR;;

    ////////////////////////////////////////////
    // Input regs
    ////////////////////////////////////////////
    always_ff @(posedge clkIn) begin : input_regs_w_rst
        if (rstIn) begin
            addValidR     <= '0;
            delExecValidR <= '0;
        end else begin
            addValidR     <= addValidIn;
            delExecValidR <= delExecValidIn;
        end
    end

    always_ff @(posedge clkIn) begin : input_reg_no_rst
        priceR      <= priceIn;
        sharesR     <= sharesIn;
        mapPriceR   <= mapPriceIn;
        mapSharesR  <= mapSharesIn;
        buySellR    <= buySellIn;
        mapBuySellR <= mapBuySellIn;
    end

    always_comb begin : match_checks
        anyPriceMatchR    <= |priceMatchR;
        anyMapPriceMatchR <= |mapPriceMatchR;
        anyMapQuantMatchR <= |mapQuantMatchR;
    end

    ////////////////////////////////////////////////////////////////////////////////////////
    //
    // TOP NODES
    //
    ////////////////////////////////////////////////////////////////////////////////////////
    always_ff @(posedge clkIn) begin : top_compares
        priceMatchR[1]    <= (buyPriceLevelsR[1] == priceIn);
        priceGreatR[1]    <= (buyPriceLevelsR[1] <  priceIn);
        priceLessR[1]     <= (buyPriceLevelsR[1] >  priceIn);

        mapPriceMatchR[1] <= (buyPriceLevelsR[1] == mapPriceIn);
        mapQuantMatchR[1] <= (buyQuantLevelsR[1] <= mapSharesIn);

        sharesSumR[1]     <= buyQuantLevelsR[1] + sharesIn;
        sharesDiffR[1]    <= buyQuantLevelsR[1] - mapSharesIn;
    end

    ////////////////////////////////////////////
    // Buy side
    ////////////////////////////////////////////
    // Increment or insert
    always_ff @(posedge clkIn) begin : top_buy_add_order
        if (rstIn) begin
            bAddPriceLevelsR[1] <= '0;
            bAddQuantLevelsR[1] <= '0;
            buyAddWrEnR[1]      <= '0;
        end else begin
            bAddPriceLevelsR[1] <= buyPriceLevelsR[1];
            bAddQuantLevelsR[1] <= buyQuantLevelsR[1];
            buyAddWrEnR[1]        <= 1'b0;

            if (addValidR & buySellR) begin
                if (priceGreatR[1]) begin
                    bAddPriceLevelsR[1] <= priceR;
                    bAddQuantLevelsR[1] <= sharesR;
                    buyAddWrEnR[1]      <= 1'b1;
                end else if (priceMatchR[1]) begin
                    bAddQuantLevelsR[1] <= sharesSumR[1];
                    buyAddWrEnR[1]      <= 1'b1;
                end
            end
        end
    end

    // Decrement or delete and shift up
    always_ff @(posedge clkIn) begin : top_buy_del_exec_order
        if (rstIn) begin
            bDelPriceLevelsR[1] <= '0;
            bDelQuantLevelsR[1] <= '0;
            buyDelWrEnR[1]      <= '0;
        end else begin
            bDelPriceLevelsR[1] <= buyPriceLevelsR[1];
            bDelQuantLevelsR[1] <= buyQuantLevelsR[1];
            buyDelWrEnR[1]      <= 1'b0;

            if (delExecValidR & mapBuySellR) begin
                if (mapPriceMatchR[1]) begin
                    if (mapQuantMatchR[1]) begin
                        bDelPriceLevelsR[1] <= buyPriceLevelsR[2];
                        bDelQuantLevelsR[1] <= buyQuantLevelsR[2];
                        buyDelWrEnR[1]      <= 1'b1;
                    end else begin
                        bDelQuantLevelsR[1] <= sharesDiffR[1];
                        buyDelWrEnR[1]      <= 1'b1;
                    end
                end
            end
        end
    end

    ////////////////////////////////////////////
    // Sell side
    ////////////////////////////////////////////
    // Increment or insert
    always_ff @(posedge clkIn) begin : top_sell_add_order
        if (rstIn) begin
            sAddPriceLevelsR[1] <= '0;
            sAddQuantLevelsR[1] <= '0;
            sellAddWrEnR[1]     <= '0;
        end else begin
            sAddPriceLevelsR[1] <= sellPriceLevelsR[1];
            sAddQuantLevelsR[1] <= sellQuantLevelsR[1];
            sellAddWrEnR[1]     <= '0;

            if (addValidR & ~buySellR) begin
                if (priceLessR[1]) begin
                    sellPriceLevelsR[1] <= priceR;
                    sellQuantLevelsR[1] <= sharesR;
                    sellAddWrEnR[1]     <= 1'b1;
                end else if (priceMatchR[1]) begin
                    sellQuantLevelsR[1] <= sharesSumR[1];;
                    sellAddWrEnR[1]     <= 1'b1;
                end
            end
        end
    end

    // Decrement or delete and shift up
    always_ff @(posedge clkIn) begin : top_sell_del_exec_order
        if (rstIn) begin
            sDelPriceLevelsR[1] <= '0;
            sDelQuantLevelsR[1] <= '0;
            sellDelWrEnR[1]     <= '0;
        end else begin
            sDelPriceLevelsR[1] <= sellPriceLevelsR[1];
            sDelQuantLevelsR[1] <= sellQuantLevelsR[1];
            sellDelWrEnR[1]     <= '0;

            if (delExecValidR & ~mapBuySellR) begin
                if (mapPriceMatchR[1]) begin
                    if (mapQuantMatchR[1]) begin
                        sDelPriceLevelsR[1] <= sDelPriceLevelsR[2];
                        sDelQuantLevelsR[1] <= sDelQuantLevelsR[2];
                        sellDelWrEnR[1]     <= 1'b1;
                    end else begin
                        sDelQuantLevelsR[1] <= sharesDiffR[1];
                        sellDelWrEnR[1]     <= 1'b1;
                    end
                end
            end
        end
    end
    ////////////////////////////////////////////////////////////////////////////////////////


    ////////////////////////////////////////////////////////////////////////////////////////
    //
    // MIDDLE NODES
    //
    ////////////////////////////////////////////////////////////////////////////////////////
    genvar i;
    generate
        for (i = DEPTH - 1; i > 1; i--) begin : middle_nodes_gen

            always_ff @(posedge clkIn) begin : common_compares
                priceMatchR[i]    <= (buyPriceLevelsR[i] == priceIn);
                priceGreatR[i]    <= (buyPriceLevelsR[i] <  priceIn);
                priceLessR[i]     <= (buyPriceLevelsR[i] >  priceIn);

                mapPriceMatchR[i] <= (buyPriceLevelsR[i] == mapPriceIn);
                mapQuantMatchR[i] <= (buyQuantLevelsR[i] <= mapSharesIn);
                mapPriceLessR[i]  <= (buyPriceLevelsR[i] <= mapPriceIn);

                sharesSumR[i]     <= buyQuantLevelsR[i] + sharesIn;
                sharesDiffR[i]    <= buyQuantLevelsR[1] - mapSharesIn;
            end

            ////////////////////////////////////////////
            // Buy side
            ////////////////////////////////////////////
            // Increment or insert and shift down
            always_ff @(posedge clkIn) begin : buy_add_order
                if (rstIn) begin
                    bAddPriceLevelsR[i] <= '0;
                    bAddQuantLevelsR[i] <= '0;
                    buyAddWrEnR[i]      <= '0;
                end else begin
                    bAddPriceLevelsR[i] <= buyPriceLevelsR[i];
                    bAddQuantLevelsR[i] <= buyQuantLevelsR[i];
                    buyAddWrEnR[i]      <= 1'b0;

                    if (addValidR & buySellR) begin
                        if (priceMatchR[i]) begin
                            bAddQuantLevelsR[i] <= sharesSumR[i];
                            buyAddWrEnR[i]      <= 1'b1;
                        end else if (~anyPriceMatchR) begin
                            if (priceGreatR[i] & priceGreatR[i-1]) begin
                                bAddPriceLevelsR[i] <= buyPriceLevelsR[i-1];
                                bAddQuantLevelsR[i] <= buyQuantLevelsR[i-1];
                                buyAddWrEnR[i]      <= 1'b1;
                            end else if (priceGreatR[i] & ~priceGreatR[i-1]) begin
                                bAddPriceLevelsR[i] <= priceR;
                                bAddQuantLevelsR[i] <= sharesR;
                                buyAddWrEnR[i]      <= 1'b1;
                            end
                        end
                    end
                end
            end

            // Decrement or delete and shift up
            always_ff @(posedge clkIn) begin : buy_del_exec_order
                if (rstIn) begin
                    bDelPriceLevelsR[i] <= '0;
                    bDelQuantLevelsR[i] <= '0;
                    buyDelWrEnR[i]      <= '0;
                end else begin
                    bDelPriceLevelsR[i] <= buyPriceLevelsR[i];
                    bDelQuantLevelsR[i] <= buyQuantLevelsR[i];
                    buyDelWrEnR[i]      <= 1'b0;

                    if (delExecValidR & mapBuySellR) begin
                        if (anyMapPriceMatchR & anyMapQuantMatchR & mapPriceLessR[i]) begin
                            bDelPriceLevelsR[i] <= buyPriceLevelsR[i+1];
                            bDelQuantLevelsR[i] <= buyQuantLevelsR[i+1];
                            buyDelWrEnR[i]        <= 1'b1;
                        end else if (mapPriceMatchR[i]) begin
                            bDelQuantLevelsR[i] <= sharesDiffR[i];
                            buyDelWrEnR[i]        <= 1'b1;
                        end
                    end
                end
            end

            ////////////////////////////////////////////
            // Sell side
            ////////////////////////////////////////////
            // Increment or insert and shift down
            always_ff @(posedge clkIn) begin : sell_add_order
                if (rstIn) begin
                    sDelPriceLevelsR[i] <= '0;
                    sDelQuantLevelsR[i] <= '0;
                    sellDelWrEnR[i]     <= '0;
                end else begin
                    sDelPriceLevelsR[i] <= sellPriceLevelsR[i];
                    sDelQuantLevelsR[i] <= sellQuantLevelsR[i];
                    sellDelWrEnR[i]     <= '0;

                    if (addValidR & ~buySellR) begin
                        if (priceMatchR[i]) begin
                            sAddQuantLevelsR[i] <= sharesSumR[i];
                            sellAddWrEnR[i]     <= 1'b1;
                        end else if (~anyPriceMatchR) begin
                            if (priceLessR[i] & priceLessR[i-1]) begin
                                sAddPriceLevelsR[i] <= sellPriceLevelsR[i-1];
                                sAddQuantLevelsR[i] <= sellQuantLevelsR[i-1];
                                sellAddWrEnR[i]     <= 1'b1;
                            end else if (priceLessR[i] & ~priceLessR[i-1]) begin
                                sAddPriceLevelsR[i] <= priceR;
                                sAddQuantLevelsR[i] <= sharesR;
                                sellAddWrEnR[i]     <= 1'b1;
                            end
                        end
                    end
                end
            end

            // Decrement or delete and shift up
            always_ff @(posedge clkIn) begin : sell_del_exec_order
                if (rstIn) begin
                    sDelPriceLevelsR[i] <= '0;
                    sDelQuantLevelsR[i] <= '0;
                    sellDelWrEnR[i]     <= '0;
                end else begin
                    sDelPriceLevelsR[i] <= sellPriceLevelsR[i];
                    sDelQuantLevelsR[i] <= sellQuantLevelsR[i];
                    sellDelWrEnR[i]     <= 1'b0;

                    if (delExecValidR & ~mapBuySellR) begin
                        if (anyMapPriceMatchR & anyMapQuantMatchR ^ mapPriceLessR[i]) begin
                            sDelPriceLevelsR[i] <= sellPriceLevelsR[i+1];
                            sDelQuantLevelsR[i] <= sellQuantLevelsR[i+1];
                            sellDelWrEnR[i]     <= 1'b1;
                        end else if (mapPriceMatchR[i]) begin
                            sDelQuantLevelsR[i] <= sharesDiffR[i];
                            sellDelWrEnR[i]     <= 1'b1;
                        end
                    end
                end
            end
        end
    endgenerate
    ////////////////////////////////////////////////////////////////////////////////////////


    ////////////////////////////////////////////////////////////////////////////////////////
    //
    // BOTTOM NODES
    //
    ////////////////////////////////////////////////////////////////////////////////////////
    always_ff @(posedge clkIn) begin : bottom_compares
        priceMatchR[DEPTH]    <= (buyPriceLevelsR[DEPTH] == priceIn);
        priceGreatR[DEPTH]    <= (buyPriceLevelsR[DEPTH] <  priceIn);
        priceLessR[DEPTH]     <= (buyPriceLevelsR[DEPTH] >  priceIn);

        mapPriceMatchR[DEPTH] <= (buyPriceLevelsR[DEPTH] == mapPriceIn);
        mapQuantMatchR[DEPTH] <= (buyQuantLevelsR[DEPTH] <= mapSharesIn);
        mapPriceLessR[DEPTH]  <= (buyPriceLevelsR[DEPTH] <  mapPriceIn);

        sharesSumR[DEPTH]     <= buyQuantLevelsR[DEPTH] + sharesIn;
        sharesDiffR[DEPTH]    <= buyQuantLevelsR[DEPTH] - mapSharesIn;
    end

    ////////////////////////////////////////////
    // Buy side
    ////////////////////////////////////////////
    // Increment or insert and shift down
    always_ff @(posedge clkIn) begin : bottom_buy_add_order
        if (rstIn) begin
            bAddPriceLevelsR[DEPTH] <= '0;
            bAddQuantLevelsR[DEPTH] <= '0;
            buyAddWrEnR[DEPTH]      <= '0;
        end else begin
            bAddPriceLevelsR[DEPTH] <= buyPriceLevelsR[DEPTH];
            bAddQuantLevelsR[DEPTH] <= buyQuantLevelsR[DEPTH];
            buyAddWrEnR[DEPTH]      <= 1'b0;

            if (addValidR & buySellR) begin
                if (priceMatchR[DEPTH]) begin
                    bAddQuantLevelsR[DEPTH] <= sharesSumR[DEPTH];
                    buyAddWrEnR[DEPTH]      <= 1'b1;
                end else if (~anyPriceMatchR) begin
                    if (priceGreatR[DEPTH] & priceGreatR[DEPTH-1]) begin
                        bAddPriceLevelsR[DEPTH] <= buyPriceLevelsR[DEPTH-1];
                        bAddQuantLevelsR[DEPTH] <= buyQuantLevelsR[DEPTH-1];
                        buyAddWrEnR[DEPTH]      <= 1'b1;
                    end else if (priceGreatR[DEPTH] & ~priceGreatR[DEPTH-1]) begin
                        bAddPriceLevelsR[DEPTH] <= priceR;
                        bAddQuantLevelsR[DEPTH] <= sharesR;
                        buyAddWrEnR[DEPTH]      <= 1'b1;
                    end
                end
            end
        end
    end

    // Decrement or delete
    always_ff @(posedge clkIn) begin : bottom_buy_del_exec_order
        if (rstIn) begin
            buyDelWrEnR[DEPTH]        <= '0;
            bDelPriceLevelsR[DEPTH] <= '0;
            bDelQuantLevelsR[DEPTH] <= '0;
        end else begin
            buyDelWrEnR[DEPTH]        <= 1'b0;
            bDelPriceLevelsR[DEPTH] <= buyPriceLevelsR[DEPTH];
            bDelQuantLevelsR[DEPTH] <= buyQuantLevelsR[DEPTH];

            if (delExecValidR & mapBuySellR) begin
                if (mapPriceMatchR[DEPTH]) begin
                    if (mapQuantMatchR[DEPTH]) begin
                        bDelPriceLevelsR[DEPTH] <= '0;
                        bDelQuantLevelsR[DEPTH] <= '0;
                    end else begin
                        bDelQuantLevelsR[DEPTH] <= sharesDiffR[DEPTH];
                    end
                end
            end
        end
    end

    ////////////////////////////////////////////
    // Sell side
    ////////////////////////////////////////////
    // Increment or insert and shift down
    always_ff @(posedge clkIn) begin : bottom_sell_add_order
        if (rstIn) begin
            sAddPriceLevelsR[DEPTH] <= '0;
            sAddQuantLevelsR[DEPTH] <= '0;
            sellAddWrEnR[DEPTH]     <= '0;
        end else begin
            sAddPriceLevelsR[DEPTH] <= sellPriceLevelsR[DEPTH];
            sAddQuantLevelsR[DEPTH] <= sellQuantLevelsR[DEPTH];
            sellAddWrEnR[DEPTH]     <= 1'b0;

            if (addValidR & ~buySellR) begin
                if (priceMatchR[DEPTH]) begin
                    sAddQuantLevelsR[DEPTH] <= sharesSumR[DEPTH];
                    sellAddWrEnR[DEPTH]     <= 1'b1;
                end else if (~anyPriceMatchR) begin
                    if (priceLessR[DEPTH] & priceLessR[DEPTH-1]) begin
                        sAddPriceLevelsR[DEPTH] <= sellPriceLevelsR[DEPTH-1];
                        sAddQuantLevelsR[DEPTH] <= sellQuantLevelsR[DEPTH-1];
                        sellAddWrEnR[DEPTH]     <= 1'b1;
                    end else if (priceLessR[DEPTH] & ~priceLessR[DEPTH-1]) begin
                        sAddPriceLevelsR[DEPTH] <= priceR;
                        sAddQuantLevelsR[DEPTH] <= sharesR;
                        sellAddWrEnR[DEPTH]     <= 1'b1;
                    end
                end
            end
        end
    end

    // Decrement or delete
    always_ff @(posedge clkIn) begin : bottom_sell_del_exec_order
        if (rstIn) begin
            sDelPriceLevelsR[DEPTH] <= '0;
            sDelQuantLevelsR[DEPTH] <= '0;
            sellDelWrEnR[DEPTH]     <= '0;
        end else begin
            sDelPriceLevelsR[DEPTH] <= sellPriceLevelsR[DEPTH];
            sDelQuantLevelsR[DEPTH] <= sellQuantLevelsR[DEPTH];
            sellDelWrEnR[DEPTH]     <= '0;

            if (delExecValidR & mapBuySellR) begin
                if (mapPriceMatchR[DEPTH]) begin
                    if (mapQuantMatchR[DEPTH]) begin
                        bDelPriceLevelsR[DEPTH] <= '0;
                        bDelQuantLevelsR[DEPTH] <= '0;
                        sellDelWrEnR[DEPTH]     <= 1'b1;
                    end else begin
                        bDelQuantLevelsR[DEPTH] <= sharesDiffR[DEPTH];
                        sellDelWrEnR[DEPTH]     <= 1'b1;
                    end
                end
            end
        end
    end
    ////////////////////////////////////////////////////////////////////////////////////////

    ////////////////////////////////////////////
    // Buy MUX
    ////////////////////////////////////////////
    always_ff @(posedge clkIn) begin : buy_mux
        if (rstIn) begin
            buyPriceLevelsR <= '{default:'0};
            buyQuantLevelsR <= '{default:'0};
        end else begin
            if (|buyAddWrEnR) begin
                buyPriceLevelsR <= bAddPriceLevelsR;
                buyQuantLevelsR <= bAddQuantLevelsR;
            end else if (|buyDelWrEnR) begin
                buyPriceLevelsR <= bDelPriceLevelsR;
                buyQuantLevelsR <= bDelQuantLevelsR;
            end
        end
    end

    ////////////////////////////////////////////
    // Sell mux
    ////////////////////////////////////////////
    always_ff @(posedge clkIn) begin : sell_mux
        if (rstIn) begin
            sellPriceLevelsR <= '{default:'0};
            sellQuantLevelsR <= '{default:'0};
        end else begin
            if (|buyAddWrEnR) begin
                sellPriceLevelsR <= sAddPriceLevelsR;
                sellQuantLevelsR <= sAddQuantLevelsR;
            end else if (|buyDelWrEnR) begin
                sellPriceLevelsR <= sDelPriceLevelsR;
                sellQuantLevelsR <= sDelQuantLevelsR;
            end
        end
    end




    ////////////////////////////////////////////////////////////////////////////////////////
    //
    // HARDWARE DEBUG
    //
    ////////////////////////////////////////////////////////////////////////////////////////
    always_ff @(posedge clkIn) begin : ila_trig_reg
        if (rstIn) begin
            buyUpdatedR  <= 1'b0;
            sellUpdatedR <= 1'b0;
        end else begin
            buyUpdatedR  <= (|buyAddWrEnR) | (|buyDelWrEnR);
            sellUpdatedR <= 1'b0;
        end
    end

    top_of_book_ila book_ila_inst (
        .clk(clkIn),
        .trig_in(buyUpdatedR|sellUpdatedR),
        .probe0({buyPriceLevelsR[1], buyQuantLevelsR[1]}),
        .probe1({sellPriceLevelsR[1], sellQuantLevelsR[1]}));

endmodule