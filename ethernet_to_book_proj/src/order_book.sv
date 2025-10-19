`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev: Ian Rider
// Purpose: Variable depth order book supports add, delete, and execute messages.
//////////////////////////////////////////////////////////////////////////////////
import pkg::*;

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

    // Buy side signals
    logic [31:0]    buyPriceLevelsR  [1:DEPTH];
    logic [31:0]    buyQuantLevelsR  [1:DEPTH];
    logic [31:0]    bAddPriceLevelsR [1:DEPTH];
    logic [31:0]    bAddQuantLevelsR [1:DEPTH];
    logic [31:0]    bDelPriceLevelsR [1:DEPTH];
    logic [31:0]    bDelQuantLevelsR [1:DEPTH];
    logic [31:0]    bSharesSumR      [1:DEPTH];
    logic [31:0]    bSharesDiffR     [1:DEPTH];
    logic [DEPTH:1] bPriceMatchR, bPriceGreatR, bMapPriceMatchR, bMapQuantMatchR, bMapPriceLessR, bAddWrEnR, bDelWrEnR;
    logic           bAnyPriceMatchR, bAnyMapQuantMatchR;

    // Sell side signals
    logic [31:0]    sellPriceLevelsR [1:DEPTH];
    logic [31:0]    sellQuantLevelsR [1:DEPTH];
    logic [31:0]    sAddPriceLevelsR [1:DEPTH];
    logic [31:0]    sAddQuantLevelsR [1:DEPTH];
    logic [31:0]    sDelPriceLevelsR [1:DEPTH];
    logic [31:0]    sDelQuantLevelsR [1:DEPTH];
    logic [31:0]    sSharesSumR      [1:DEPTH];
    logic [31:0]    sSharesDiffR     [1:DEPTH];
    logic [DEPTH:1] sPriceMatchR, sPriceLessR, sMapPriceMatchR, sMapQuantMatchR, sMapPriceLessR, sAddWrEnR, sDelWrEnR;
    logic           sAnyPriceMatchR, sAnyMapQuantMatchR;

    // Misc
    logic [31:0]  priceR, sharesR;
    logic addValidR, delExecValidR, buyUpdatedR, sellUpdatedR, buySellR, mapBuySellR;

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
        buySellR    <= buySellIn;
        mapBuySellR <= mapBuySellIn;
    end

    always_comb begin : match_checks
        bAnyPriceMatchR    <= |bPriceMatchR;
        bAnyMapQuantMatchR <= |(bMapQuantMatchR & bMapPriceMatchR);

        sAnyPriceMatchR    <= |sPriceMatchR;
        sAnyMapQuantMatchR <= |(sMapQuantMatchR & sMapPriceMatchR);
    end

    ////////////////////////////////////////////////////////////////////////////////////////
    //
    // TOP NODES
    //
    ////////////////////////////////////////////////////////////////////////////////////////
    always_ff @(posedge clkIn) begin : top_compares
        bPriceMatchR[1]    <= buyPriceLevelsR[1]  == priceIn;
        bPriceGreatR[1]    <= buyPriceLevelsR[1]  <  priceIn;
        bMapPriceMatchR[1] <= buyPriceLevelsR[1]  == mapPriceIn;
        bMapQuantMatchR[1] <= buyQuantLevelsR[1]  <= mapSharesIn;
        bSharesSumR[1]     <= buyQuantLevelsR[1]  +  sharesIn;
        bSharesDiffR[1]    <= buyQuantLevelsR[1]  -  mapSharesIn;

        sPriceMatchR[1]    <= sellPriceLevelsR[1] == priceIn;
        sPriceLessR[1]     <= sellPriceLevelsR[1] >  priceIn;
        sMapPriceMatchR[1] <= sellPriceLevelsR[1] == mapPriceIn;
        sMapQuantMatchR[1] <= sellQuantLevelsR[1] <= mapSharesIn;
        sSharesSumR[1]     <= sellQuantLevelsR[1] +  sharesIn;
        sSharesDiffR[1]    <= sellQuantLevelsR[1] -  mapSharesIn;
    end

    ////////////////////////////////////////////
    // Buy side
    ////////////////////////////////////////////
    // Increment or insert
    always_ff @(posedge clkIn) begin : top_buy_add_order
        if (rstIn) begin
            bAddPriceLevelsR[1] <= '0;
            bAddQuantLevelsR[1] <= '0;
            bAddWrEnR[1]        <= '0;
        end else begin
            bAddPriceLevelsR[1] <= buyPriceLevelsR[1];
            bAddQuantLevelsR[1] <= buyQuantLevelsR[1];
            bAddWrEnR[1]        <= 1'b0;

            if (addValidR & buySellR) begin
                if (bPriceGreatR[1]) begin
                    bAddPriceLevelsR[1] <= priceR;
                    bAddQuantLevelsR[1] <= sharesR;
                    bAddWrEnR[1]        <= 1'b1;
                end else if (bPriceMatchR[1]) begin
                    bAddQuantLevelsR[1] <= bSharesSumR[1];
                    bAddWrEnR[1]        <= 1'b1;
                end
            end
        end
    end

    // Decrement or delete and shift up
    always_ff @(posedge clkIn) begin : top_buy_del_exec_order
        if (rstIn) begin
            bDelPriceLevelsR[1] <= '0;
            bDelQuantLevelsR[1] <= '0;
            bDelWrEnR[1]        <= '0;
        end else begin
            bDelPriceLevelsR[1] <= buyPriceLevelsR[1];
            bDelQuantLevelsR[1] <= buyQuantLevelsR[1];
            bDelWrEnR[1]        <= 1'b0;

            if (delExecValidR & mapBuySellR) begin
                if (bMapPriceMatchR[1]) begin
                    if (bMapQuantMatchR[1]) begin
                        bDelPriceLevelsR[1] <= buyPriceLevelsR[2];
                        bDelQuantLevelsR[1] <= buyQuantLevelsR[2];
                        bDelWrEnR[1]        <= 1'b1;
                    end else begin
                        bDelQuantLevelsR[1] <= bSharesDiffR[1];
                        bDelWrEnR[1]        <= 1'b1;
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
            sAddPriceLevelsR[1] <= '1;
            sAddQuantLevelsR[1] <= '1;
            sAddWrEnR[1]        <= '0;
        end else begin
            sAddPriceLevelsR[1] <= sellPriceLevelsR[1];
            sAddQuantLevelsR[1] <= sellQuantLevelsR[1];
            sAddWrEnR[1]        <= '0;

            if (addValidR & ~buySellR) begin
                if (sPriceLessR[1]) begin
                    sAddPriceLevelsR[1] <= priceR;
                    sAddQuantLevelsR[1] <= sharesR;
                    sAddWrEnR[1]        <= 1'b1;
                end else if (sPriceMatchR[1]) begin
                    sAddQuantLevelsR[1] <= sSharesSumR[1];;
                    sAddWrEnR[1]        <= 1'b1;
                end
            end
        end
    end

    // Decrement or delete and shift up
    always_ff @(posedge clkIn) begin : top_sell_del_exec_order
        if (rstIn) begin
            sDelPriceLevelsR[1] <= '1;
            sDelQuantLevelsR[1] <= '1;
            sDelWrEnR[1]        <= '0;
        end else begin
            sDelPriceLevelsR[1] <= sellPriceLevelsR[1];
            sDelQuantLevelsR[1] <= sellQuantLevelsR[1];
            sDelWrEnR[1]        <= '0;

            if (delExecValidR & ~mapBuySellR) begin
                if (sMapPriceMatchR[1]) begin
                    if (sMapQuantMatchR[1]) begin
                        sDelPriceLevelsR[1] <= sellPriceLevelsR[2];
                        sDelQuantLevelsR[1] <= sellQuantLevelsR[2];
                        sDelWrEnR[1]        <= 1'b1;
                    end else begin
                        sDelQuantLevelsR[1] <= sSharesDiffR[1];
                        sDelWrEnR[1]        <= 1'b1;
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
                bPriceMatchR[i]    <= buyPriceLevelsR[i]  == priceIn;
                bPriceGreatR[i]    <= buyPriceLevelsR[i]  <  priceIn;
                bMapPriceMatchR[i] <= buyPriceLevelsR[i]  == mapPriceIn;
                bMapPriceLessR[i]  <= buyPriceLevelsR[i]  <= mapPriceIn;
                bMapQuantMatchR[i] <= buyQuantLevelsR[i]  <= mapSharesIn;
                bSharesSumR[i]     <= buyQuantLevelsR[i]  +  sharesIn;
                bSharesDiffR[i]    <= buyQuantLevelsR[i]  -  mapSharesIn;

                sPriceMatchR[i]    <= sellPriceLevelsR[i] == priceIn;
                sPriceLessR[i]     <= sellPriceLevelsR[i] >  priceIn;
                sMapPriceMatchR[i] <= sellPriceLevelsR[i] == mapPriceIn;
                sMapQuantMatchR[i] <= sellQuantLevelsR[i] <= mapSharesIn;
                sMapPriceLessR[i]  <= sellPriceLevelsR[i] >= mapPriceIn;
                sSharesSumR[i]     <= sellQuantLevelsR[i] +  sharesIn;
                sSharesDiffR[i]    <= sellQuantLevelsR[i] -  mapSharesIn;
            end

            ////////////////////////////////////////////
            // Buy side
            ////////////////////////////////////////////
            // Increment or insert and shift down
            always_ff @(posedge clkIn) begin : buy_add_order
                if (rstIn) begin
                    bAddPriceLevelsR[i] <= '0;
                    bAddQuantLevelsR[i] <= '0;
                    bAddWrEnR[i]        <= '0;
                end else begin
                    bAddPriceLevelsR[i] <= buyPriceLevelsR[i];
                    bAddQuantLevelsR[i] <= buyQuantLevelsR[i];
                    bAddWrEnR[i]        <= 1'b0;

                    if (addValidR & buySellR) begin
                        if (bPriceMatchR[i]) begin
                            bAddQuantLevelsR[i] <= bSharesSumR[i];
                            bAddWrEnR[i]        <= 1'b1;
                        end else if (~bAnyPriceMatchR) begin
                            if (bPriceGreatR[i] & bPriceGreatR[i-1]) begin
                                bAddPriceLevelsR[i] <= buyPriceLevelsR[i-1];
                                bAddQuantLevelsR[i] <= buyQuantLevelsR[i-1];
                                bAddWrEnR[i]        <= 1'b1;
                            end else if (bPriceGreatR[i] & ~bPriceGreatR[i-1]) begin
                                bAddPriceLevelsR[i] <= priceR;
                                bAddQuantLevelsR[i] <= sharesR;
                                bAddWrEnR[i]        <= 1'b1;
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
                    bDelWrEnR[i]        <= '0;
                end else begin
                    bDelPriceLevelsR[i] <= buyPriceLevelsR[i];
                    bDelQuantLevelsR[i] <= buyQuantLevelsR[i];
                    bDelWrEnR[i]        <= 1'b0;

                    if (delExecValidR & mapBuySellR) begin
                        if (bAnyMapQuantMatchR & bMapPriceLessR[i]) begin
                            bDelPriceLevelsR[i] <= buyPriceLevelsR[i+1];
                            bDelQuantLevelsR[i] <= buyQuantLevelsR[i+1];
                            bDelWrEnR[i]        <= 1'b1;
                        end else if (bMapPriceMatchR[i]) begin
                            bDelQuantLevelsR[i] <= bSharesDiffR[i];
                            bDelWrEnR[i]        <= 1'b1;
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
                    sDelPriceLevelsR[i] <= '1;
                    sDelQuantLevelsR[i] <= '1;
                    sAddWrEnR[i]        <= '0;
                end else begin
                    sDelPriceLevelsR[i] <= sellPriceLevelsR[i];
                    sDelQuantLevelsR[i] <= sellQuantLevelsR[i];
                    sAddWrEnR[i]        <= '0;

                    if (addValidR & ~buySellR) begin
                        if (sPriceMatchR[i]) begin
                            sAddQuantLevelsR[i] <= sSharesSumR[i];
                            sAddWrEnR[i]        <= 1'b1;
                        end else if (~sAnyPriceMatchR) begin
                            if (sPriceLessR[i] & sPriceLessR[i-1]) begin
                                sAddPriceLevelsR[i] <= sellPriceLevelsR[i-1];
                                sAddQuantLevelsR[i] <= sellQuantLevelsR[i-1];
                                sAddWrEnR[i]        <= 1'b1;
                            end else if (sPriceLessR[i] & ~sPriceLessR[i-1]) begin
                                sAddPriceLevelsR[i] <= priceR;
                                sAddQuantLevelsR[i] <= sharesR;
                                sAddWrEnR[i]        <= 1'b1;
                            end
                        end
                    end
                end
            end

            // Decrement or delete and shift up
            always_ff @(posedge clkIn) begin : sell_del_exec_order
                if (rstIn) begin
                    sDelPriceLevelsR[i] <= '1;
                    sDelQuantLevelsR[i] <= '1;
                    sDelWrEnR[i]        <= '0;
                end else begin
                    sDelPriceLevelsR[i] <= sellPriceLevelsR[i];
                    sDelQuantLevelsR[i] <= sellQuantLevelsR[i];
                    sDelWrEnR[i]        <= 1'b0;

                    if (delExecValidR & ~mapBuySellR) begin
                        if (sAnyMapQuantMatchR & sMapPriceLessR[i]) begin
                            sDelPriceLevelsR[i] <= sellPriceLevelsR[i+1];
                            sDelQuantLevelsR[i] <= sellQuantLevelsR[i+1];
                            sDelWrEnR[i]        <= 1'b1;
                        end else if (bMapPriceMatchR[i]) begin
                            sDelQuantLevelsR[i] <= sSharesDiffR[i];
                            sDelWrEnR[i]        <= 1'b1;
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
        bPriceMatchR[DEPTH]    <= buyPriceLevelsR[DEPTH]  == priceIn;
        bPriceGreatR[DEPTH]    <= buyPriceLevelsR[DEPTH]  <  priceIn;
        bMapPriceMatchR[DEPTH] <= buyPriceLevelsR[DEPTH]  == mapPriceIn;
        bMapPriceLessR[DEPTH]  <= buyPriceLevelsR[DEPTH]  <  mapPriceIn;
        bMapQuantMatchR[DEPTH] <= buyQuantLevelsR[DEPTH]  <= mapSharesIn;
        bSharesSumR[DEPTH]     <= buyQuantLevelsR[DEPTH]   + sharesIn;
        bSharesDiffR[DEPTH]    <= buyQuantLevelsR[DEPTH]   - mapSharesIn;

        sPriceMatchR[DEPTH]    <= sellPriceLevelsR[DEPTH] == priceIn;
        sPriceLessR[DEPTH]     <= sellPriceLevelsR[DEPTH] >  priceIn;
        sMapPriceMatchR[DEPTH] <= sellPriceLevelsR[DEPTH] == mapPriceIn;
        sMapQuantMatchR[DEPTH] <= sellQuantLevelsR[DEPTH] <= mapSharesIn;
        sSharesSumR[DEPTH]     <= sellQuantLevelsR[DEPTH] +  sharesIn;
        sSharesDiffR[DEPTH]    <= sellQuantLevelsR[DEPTH] -  mapSharesIn;
    end

    ////////////////////////////////////////////
    // Buy side
    ////////////////////////////////////////////
    // Increment or insert and shift down
    always_ff @(posedge clkIn) begin : bottom_buy_add_order
        if (rstIn) begin
            bAddPriceLevelsR[DEPTH] <= '0;
            bAddQuantLevelsR[DEPTH] <= '0;
            bAddWrEnR[DEPTH]        <= '0;
        end else begin
            bAddPriceLevelsR[DEPTH] <= buyPriceLevelsR[DEPTH];
            bAddQuantLevelsR[DEPTH] <= buyQuantLevelsR[DEPTH];
            bAddWrEnR[DEPTH]        <= 1'b0;

            if (addValidR & buySellR) begin
                if (bPriceMatchR[DEPTH]) begin
                    bAddQuantLevelsR[DEPTH] <= bSharesSumR[DEPTH];
                    bAddWrEnR[DEPTH]        <= 1'b1;
                end else if (~bAnyPriceMatchR) begin
                    if (bPriceGreatR[DEPTH] & bPriceGreatR[DEPTH-1]) begin
                        bAddPriceLevelsR[DEPTH] <= buyPriceLevelsR[DEPTH-1];
                        bAddQuantLevelsR[DEPTH] <= buyQuantLevelsR[DEPTH-1];
                        bAddWrEnR[DEPTH]        <= 1'b1;
                    end else if (bPriceGreatR[DEPTH] & ~bPriceGreatR[DEPTH-1]) begin
                        bAddPriceLevelsR[DEPTH] <= priceR;
                        bAddQuantLevelsR[DEPTH] <= sharesR;
                        bAddWrEnR[DEPTH]        <= 1'b1;
                    end
                end
            end
        end
    end

    // Decrement or delete
    always_ff @(posedge clkIn) begin : bottom_buy_del_exec_order
        if (rstIn) begin
            bDelPriceLevelsR[DEPTH] <= '0;
            bDelQuantLevelsR[DEPTH] <= '0;
            bDelWrEnR[DEPTH]        <= '0;
        end else begin
            bDelPriceLevelsR[DEPTH] <= buyPriceLevelsR[DEPTH];
            bDelQuantLevelsR[DEPTH] <= buyQuantLevelsR[DEPTH];
            bDelWrEnR[DEPTH]        <= 1'b0;

            if (delExecValidR & mapBuySellR) begin
                if (bAnyMapQuantMatchR) begin
                    bDelPriceLevelsR[DEPTH] <= '0;
                    bDelQuantLevelsR[DEPTH] <= '0;
                    bDelWrEnR[DEPTH]        <= 1'b1;
                end else if (bMapPriceMatchR[DEPTH]) begin
                    bDelQuantLevelsR[DEPTH] <= bSharesDiffR[DEPTH];
                    bDelWrEnR[DEPTH]        <= 1'b1;
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
            sAddPriceLevelsR[DEPTH] <= '1;
            sAddQuantLevelsR[DEPTH] <= '1;
            sAddWrEnR[DEPTH]        <= '0;
        end else begin
            sAddPriceLevelsR[DEPTH] <= sellPriceLevelsR[DEPTH];
            sAddQuantLevelsR[DEPTH] <= sellQuantLevelsR[DEPTH];
            sAddWrEnR[DEPTH]        <= 1'b0;

            if (addValidR & ~buySellR) begin
                if (sPriceMatchR[DEPTH]) begin
                    sAddQuantLevelsR[DEPTH] <= sSharesSumR[DEPTH];
                    sAddWrEnR[DEPTH]        <= 1'b1;
                end else if (~sAnyPriceMatchR) begin
                    if (sPriceLessR[DEPTH] & sPriceLessR[DEPTH-1]) begin
                        sAddPriceLevelsR[DEPTH] <= sellPriceLevelsR[DEPTH-1];
                        sAddQuantLevelsR[DEPTH] <= sellQuantLevelsR[DEPTH-1];
                        sAddWrEnR[DEPTH]        <= 1'b1;
                    end else if (sPriceLessR[DEPTH] & ~sPriceLessR[DEPTH-1]) begin
                        sAddPriceLevelsR[DEPTH] <= priceR;
                        sAddQuantLevelsR[DEPTH] <= sharesR;
                        sAddWrEnR[DEPTH]        <= 1'b1;
                    end
                end
            end
        end
    end

    // Decrement or delete
    always_ff @(posedge clkIn) begin : bottom_sell_del_exec_order
        if (rstIn) begin
            sDelPriceLevelsR[DEPTH] <= '1;
            sDelQuantLevelsR[DEPTH] <= '1;
            sDelWrEnR[DEPTH]        <= '0;
        end else begin
            sDelPriceLevelsR[DEPTH] <= sellPriceLevelsR[DEPTH];
            sDelQuantLevelsR[DEPTH] <= sellQuantLevelsR[DEPTH];
            sDelWrEnR[DEPTH]        <= '0;

            if (delExecValidR & ~mapBuySellR) begin
                if (sAnyMapQuantMatchR) begin
                    sDelPriceLevelsR[DEPTH] <= '1;
                    sDelQuantLevelsR[DEPTH] <= '1;
                    sDelWrEnR[DEPTH]        <= 1'b1;
                end else if (bMapPriceMatchR[DEPTH]) begin
                    sDelQuantLevelsR[DEPTH] <= sSharesDiffR[DEPTH];
                    sDelWrEnR[DEPTH]        <= 1'b1;
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
            if (|bAddWrEnR) begin
                buyPriceLevelsR <= bAddPriceLevelsR;
                buyQuantLevelsR <= bAddQuantLevelsR;
            end else if (|bDelWrEnR) begin
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
            sellPriceLevelsR <= '{default:'1};
            sellQuantLevelsR <= '{default:'1};
        end else begin
            if (|sAddWrEnR) begin
                sellPriceLevelsR <= sAddPriceLevelsR;
                sellQuantLevelsR <= sAddQuantLevelsR;
            end else if (|sDelWrEnR) begin
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
            buyUpdatedR  <= (|bAddWrEnR) | (|bDelWrEnR);
            sellUpdatedR <= (|sAddWrEnR) | (|sDelWrEnR);
        end
    end

    top_of_book_ila book_ila_inst (
        .clk(clkIn),
        .trig_in(buyUpdatedR|sellUpdatedR),
        .probe0({buyPriceLevelsR[1], buyQuantLevelsR[1]}),
        .probe1({sellPriceLevelsR[1], sellQuantLevelsR[1]}));

endmodule