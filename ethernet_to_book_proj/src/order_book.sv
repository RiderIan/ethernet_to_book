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

    logic [31:0]  priceLevelsR    [1:ORDER_BOOK_DEPTH];
    logic [31:0]  quantLevelsR    [1:ORDER_BOOK_DEPTH];
    logic [31:0]  addPriceLevelsR [1:ORDER_BOOK_DEPTH];
    logic [31:0]  addQuantLevelsR [1:ORDER_BOOK_DEPTH];
    logic [31:0]  delPriceLevelsR [1:ORDER_BOOK_DEPTH];
    logic [31:0]  delQuantLevelsR [1:ORDER_BOOK_DEPTH];

    logic [31:0]  priceR, sharesR, mapPriceR, mapSharesR;
    logic [ORDER_BOOK_DEPTH:1] priceMatchR, quantMatchR, priceGreatR, mapPriceMatchR, mapQuantMatchR, mapPriceGreatR, addWrEnR, delWrEnR;
    logic addValidR, delExecValidR, bookUpdatedR, bookUpdatedRR, buySellR, mapBuySellR;

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

    ////////////////////////////////////////////
    // Top node (top of book)
    ////////////////////////////////////////////
    always_ff @(posedge clkIn) begin : top_compares
        priceMatchR[1]    <= (priceLevelsR[1] == priceIn);
        quantMatchR[1]    <= (quantLevelsR[1] >= sharesIn);
        priceGreatR[1]    <= (priceLevelsR[1] <  sharesIn);

        mapPriceMatchR[1] <= (priceLevelsR[1] == mapPriceIn);
        mapQuantMatchR[1] <= (quantLevelsR[1] >= mapSharesIn);
        mapPriceGreatR[1] <= (priceLevelsR[1] <  mapSharesIn);
    end

    // Increment or insert
    always_ff @(posedge clkIn) begin : top_add_order
        if (rstIn) begin
            addWrEnR[1]        <= '0;
            addPriceLevelsR[1] <= '0;
            addQuantLevelsR[1] <= '0;
        end else begin
            addWrEnR[1]        <= 1'b0;
            addPriceLevelsR[1] <= priceLevelsR[1];
            addQuantLevelsR[1] <= quantLevelsR[1];

            if (addValidR & buySellR) begin
                if (priceMatchR[1]) begin
                    addQuantLevelsR[1] <= quantLevelsR[1] + sharesR;
                    addWrEnR[1]        <= 1'b1;
                end

                if (priceGreatR[1]) begin
                    addPriceLevelsR[1] <= priceR;
                    addQuantLevelsR[1] <= sharesR;
                    addWrEnR[1]        <= 1'b1;
                end
            end
        end
    end

    // Decrement or delete and shift up
    always_ff @(posedge clkIn) begin : top_del_exec_order
        if (rstIn) begin
            delWrEnR[1]        <= '0;
            delPriceLevelsR[1] <= '0;
            delQuantLevelsR[1] <= '0;
        end else begin
            delWrEnR[1]        <= 1'b0;
            delPriceLevelsR[1] <= priceLevelsR[1];
            delQuantLevelsR[1] <= quantLevelsR[1];

            if (delExecValidR & mapBuySellR) begin
                if (mapPriceMatchR[1]) begin
                    if (mapQuantMatchR[1]) begin
                        delPriceLevelsR[1] <= priceLevelsR[2];
                        delQuantLevelsR[1] <= quantLevelsR[2];
                        delWrEnR[1]        <= 1'b1;
                    end else begin
                        delQuantLevelsR[1]  <= quantLevelsR[1] - mapSharesR;
                        delWrEnR[1]         <= 1'b1;
                    end
                end
            end
        end
    end

    ////////////////////////////////////////////
    // Middle nodes
    ////////////////////////////////////////////
    genvar i;
    generate
        for (i = ORDER_BOOK_DEPTH - 1; i > 1; i--) begin : middle_nodes_gen

            always_ff @(posedge clkIn) begin : common_compares
                priceMatchR[i]    <= (priceLevelsR[i] == priceIn);
                quantMatchR[i]    <= (quantLevelsR[i] >= sharesIn);
                priceGreatR[i]    <= (priceLevelsR[i] <  sharesIn);

                mapPriceMatchR[i] <= (priceLevelsR[i] == mapPriceIn);
                mapQuantMatchR[i] <= (quantLevelsR[i] >= mapSharesIn);
                mapPriceGreatR[i] <= (priceLevelsR[i] <  mapSharesIn);
            end

            // Increment or insert and shift down
            always_ff @(posedge clkIn) begin : add_order
                if (rstIn) begin
                    addWrEnR[i]        <= '0;
                    addPriceLevelsR[i] <= '0;
                    addQuantLevelsR[i] <= '0;
                end else begin
                    addWrEnR[i]        <= 1'b0;
                    addPriceLevelsR[i] <= priceLevelsR[i];
                    addQuantLevelsR[i] <= quantLevelsR[i];

                    if (addValidR & buySellR) begin
                        if (priceMatchR[i]) begin
                            addQuantLevelsR[i] <= quantLevelsR[i] + sharesR;
                            addWrEnR[i]        <= 1'b1;
                        end

                        if (priceGreatR[i] & priceGreatR[i-1]) begin
                            addPriceLevelsR[i] <= priceLevelsR[i-1];
                            addQuantLevelsR[i] <= quantLevelsR[i-1];
                            addWrEnR[i]        <= 1'b1;
                        end

                        if (priceGreatR[i] & ~priceGreatR[i-1]) begin
                            addPriceLevelsR[i] <= priceR;
                            addQuantLevelsR[i] <= sharesR;
                            addWrEnR[i]        <= 1'b1;
                        end
                    end
                end
            end

            // Decrement or delete and shift up
            always_ff @(posedge clkIn) begin : del_exec_order
                if (rstIn) begin
                    delWrEnR[i]        <= '0;
                    delPriceLevelsR[i] <= '0;
                    delQuantLevelsR[i] <= '0;
                end else begin
                    delWrEnR[i]        <= 1'b0;
                    delPriceLevelsR[i] <= priceLevelsR[i];
                    delQuantLevelsR[i] <= quantLevelsR[i];

                    if (delExecValidR & mapBuySellR) begin
                        if (mapPriceMatchR[i]) begin
                            if (mapQuantMatchR[i]) begin
                                delPriceLevelsR[i] <= priceLevelsR[i+1];
                                delQuantLevelsR[i] <= quantLevelsR[i+1];
                                delWrEnR[i]        <= 1'b1;
                            end else begin
                                delQuantLevelsR[i] <= quantLevelsR[i] - mapSharesR;
                                delWrEnR[i]         <= 1'b1;
                            end
                        end
                    end
                end
            end

        end
    endgenerate

    ////////////////////////////////////////////
    // Bottom node
    ////////////////////////////////////////////
    always_ff @(posedge clkIn) begin : bottom_compares
        priceMatchR[ORDER_BOOK_DEPTH]    <= (priceLevelsR[ORDER_BOOK_DEPTH] == priceIn);
        quantMatchR[ORDER_BOOK_DEPTH]    <= (quantLevelsR[ORDER_BOOK_DEPTH] >= sharesIn);
        priceGreatR[ORDER_BOOK_DEPTH]    <= (priceLevelsR[ORDER_BOOK_DEPTH] <  sharesIn);

        mapPriceMatchR[ORDER_BOOK_DEPTH] <= (priceLevelsR[ORDER_BOOK_DEPTH] == mapPriceIn);
        mapQuantMatchR[ORDER_BOOK_DEPTH] <= (quantLevelsR[ORDER_BOOK_DEPTH] >= mapSharesIn);
        mapPriceGreatR[ORDER_BOOK_DEPTH] <= (priceLevelsR[ORDER_BOOK_DEPTH] <  mapSharesIn);
    end

    // Increment or insert and shift down
    always_ff @(posedge clkIn) begin : bottom_add_order
        if (rstIn) begin
            addWrEnR[ORDER_BOOK_DEPTH]        <= '0;
            addPriceLevelsR[ORDER_BOOK_DEPTH] <= '0;
            addQuantLevelsR[ORDER_BOOK_DEPTH] <= '0;
        end else begin
            addWrEnR[ORDER_BOOK_DEPTH]        <= 1'b0;
            addPriceLevelsR[ORDER_BOOK_DEPTH] <= priceLevelsR[ORDER_BOOK_DEPTH];
            addQuantLevelsR[ORDER_BOOK_DEPTH] <= quantLevelsR[ORDER_BOOK_DEPTH];

            if (addValidR & buySellR) begin
                if (priceMatchR[ORDER_BOOK_DEPTH]) begin
                    addQuantLevelsR[ORDER_BOOK_DEPTH] <= quantLevelsR[ORDER_BOOK_DEPTH] + sharesR;
                    addWrEnR[ORDER_BOOK_DEPTH]        <= 1'b1;
                end

                if (priceGreatR[ORDER_BOOK_DEPTH] & priceGreatR[ORDER_BOOK_DEPTH-1]) begin
                    addPriceLevelsR[ORDER_BOOK_DEPTH] <= priceLevelsR[ORDER_BOOK_DEPTH-1];
                    addQuantLevelsR[ORDER_BOOK_DEPTH] <= quantLevelsR[ORDER_BOOK_DEPTH-1];
                    addWrEnR[ORDER_BOOK_DEPTH]        <= 1'b1;
                end

                if (priceGreatR[ORDER_BOOK_DEPTH] & ~priceGreatR[ORDER_BOOK_DEPTH-1]) begin
                    addPriceLevelsR[ORDER_BOOK_DEPTH] <= priceR;
                    addQuantLevelsR[ORDER_BOOK_DEPTH] <= sharesR;
                    addWrEnR[ORDER_BOOK_DEPTH]        <= 1'b1;
                end
            end
        end
    end

    // Decrement or delete
    always_ff @(posedge clkIn) begin : bottom_del_exec_order
        if (rstIn) begin
            delWrEnR[ORDER_BOOK_DEPTH]        <= '0;
            delPriceLevelsR[ORDER_BOOK_DEPTH] <= '0;
            delQuantLevelsR[ORDER_BOOK_DEPTH] <= '0;
        end else begin
            delWrEnR[ORDER_BOOK_DEPTH]        <= 1'b0;
            delPriceLevelsR[ORDER_BOOK_DEPTH] <= priceLevelsR[ORDER_BOOK_DEPTH];
            delQuantLevelsR[ORDER_BOOK_DEPTH] <= quantLevelsR[ORDER_BOOK_DEPTH];

            if (delExecValidR & mapBuySellR) begin
                if (mapPriceMatchR[ORDER_BOOK_DEPTH]) begin
                    if (mapQuantMatchR[ORDER_BOOK_DEPTH]) begin
                        delPriceLevelsR[ORDER_BOOK_DEPTH] <= '0;
                        delQuantLevelsR[ORDER_BOOK_DEPTH] <= '0;
                        delWrEnR[ORDER_BOOK_DEPTH]        <= 1'b1;
                    end else begin
                        delQuantLevelsR[ORDER_BOOK_DEPTH] <= quantLevelsR[ORDER_BOOK_DEPTH] - mapSharesR;
                        delWrEnR[ORDER_BOOK_DEPTH]        <= 1'b1;
                    end
                end
            end
        end
    end

    ////////////////////////////////////////////
    // Buy MUX
    ////////////////////////////////////////////
    always_ff @(posedge clkIn) begin : buy_mux
        if (rstIn) begin
            priceLevelsR <= '{default:'0};
            quantLevelsR <= '{default:'0};
        end else begin
            if (|addWrEnR) begin
                priceLevelsR <= addPriceLevelsR;
                quantLevelsR <= addQuantLevelsR;
            end else if (|delWrEnR) begin
                priceLevelsR <= delPriceLevelsR;
                quantLevelsR <= delQuantLevelsR;
            end
        end
    end



    // always_ff @(posedge clkIn) begin : ila_trig_reg
    //     if (rstIn) begin
    //         bookUpdatedR  <= 1'b0;
    //         bookUpdatedRR <= 1'b0;
    //     end else begin
    //         bookUpdatedR  <= addValidDlyR | delExecValidDlyR;
    //         bookUpdatedRR <= bookUpdatedR;
    //     end
    // end

    // TODO: replace with actual signals
    top_of_book_ila book_ila_inst (
        .clk(clkIn),
        .trig_in(addValidR),
        .probe0({priceLevelsR[2], quantLevelsR[2]}),
        .probe1(addWrEnR[2]));

endmodule