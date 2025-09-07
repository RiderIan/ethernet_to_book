`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev: Ian Rider
// Purpose: Parses itch messages and output to book builder
//////////////////////////////////////////////////////////////////////////////////
import pkg::*;

(* shreg_extract = "no" *)
module itch_parser (
    input  logic        rstIn,
    input  logic        clkIn,

    input  logic [ 7:0] dataIn,
    input  logic        dataValidIn,
    input  logic        packetLostIn,

    output logic        addValidOut,
    output logic        delValidOut,
    output logic        execValidOut,
    output logic [63:0] refNumOut,

    output logic [15:0] locateOut,
    output logic [31:0] priceOut,
    output logic [31:0] sharesOut,
    output logic        buySellOut);

    const logic [10:0] MSG_TYPE_DONE    = 10'd1;
    const logic [10:0] LOCATE_DONE      = 10'd3;
    const logic [10:0] TRK_NUM_DONE     = 10'd5;
    const logic [10:0] TIME_STMP_DONE   = 10'd11;
    const logic [10:0] REF_NUM_DONE     = 10'd19;
    const logic [10:0] EXEC_SHARES_DONE = 10'd23;
    const logic [10:0] MATCH_NUM_DONE   = 10'd31;
    const logic [10:0] BUY_SELL_DONE    = 10'd20;
    const logic [10:0] SHARES_DONE      = 10'd24;
    const logic [10:0] STOCK_DONE       = 10'd32;
    const logic [10:0] PRICE_DONE       = 10'd36;


    logic        addTypeR, addValidR, delTypeR, delValidR, execTypeR, execValidR, msgDone;
    logic        addTypeStickyR, delTypeStickyR, execTypeStickyR, dataValidFallingR, dataValidR;
    logic [10:0] byteCntR, byteCntRR, msgTypeOffsetR, msgTypeOffsetNext, locateOffsetR, refNumOffsetR, refNumEndR, matchNumEndR;
    logic [10:0] buySellOffsetR, sharesOffsetR, priceOffsetR, priceEndR;
    logic [15:0] locateR;
    logic [31:0] priceR, sharesR;
    logic [63:0] refNumR;

    ////////////////////////////////////////////
    // Msg type detect
    ////////////////////////////////////////////
    always_ff @(posedge clkIn) begin : msg_type_detect
        if (rstIn) begin
            addTypeR  <= 1'b0;
            delTypeR  <= 1'b0;
            execTypeR <= 1'b0;
        end else begin
            if (dataValidIn & (byteCntR == msgTypeOffsetR)) begin
                if (dataIn == ADD_MSG_TYPE)
                    addTypeR  <= 1'b1;
                else
                    addTypeR  <= 1'b0;

                if (dataIn == DELETE_MSG_TYPE)
                    delTypeR  <= 1'b1;
                else
                    delTypeR  <= 1'b0;

                if (dataIn == EXECUTED_MSG_TYPE)
                    execTypeR <= 1'b1;
                else
                    execTypeR <= 1'b0;
            end
        end
    end

    ////////////////////////////////////////////
    // Locate
    ////////////////////////////////////////////
    always_ff @(posedge clkIn) begin : locate_capture
        if (dataValidIn & (byteCntR < locateOffsetR)) begin
            locateR <= (locateR << 8) | dataIn;
        end
    end

    ////////////////////////////////////////////
    // Reference number
    ////////////////////////////////////////////
    always_ff @(posedge clkIn) begin : ref_num_capture
        if (dataValidIn & (byteCntR < refNumOffsetR)) begin
            refNumR <= (refNumR << 8) | dataIn;
        end
    end

    ////////////////////////////////////////////
    // Buy/sell
    ////////////////////////////////////////////
    always_ff @(posedge clkIn) begin : buy_sell_capture
        // No reset becuase both '0' and '1' are valid states
        // Might not be the most safe way to do this
        if (dataValidIn & (byteCntR == buySellOffsetR)) begin
            if (dataIn == BUY) begin
                buySellOut  <= 1'b1;
            end else if (dataIn == SELL) begin
                buySellOut <= 1'b0;
            end
        end
    end

    ////////////////////////////////////////////
    // Shares
    ////////////////////////////////////////////
    always_ff @(posedge clkIn) begin : shares_capture
        byteCntRR <= byteCntR;
        if (dataValidIn & (byteCntRR < sharesOffsetR))
            sharesR <= (sharesR << 8) | dataIn;
    end

    ////////////////////////////////////////////
    // Price
    ////////////////////////////////////////////
    always_ff @(posedge clkIn) begin : price_capture
        if (dataValidIn & (byteCntR < priceOffsetR))
            priceR <= (priceR << 8) | dataIn;
    end

    ////////////////////////////////////////////
    // End of msg detect
    ////////////////////////////////////////////
    always_ff @(posedge clkIn) begin : drive_valids
        if (rstIn) begin
            addValidR      <= 1'b0;
            delValidR      <= 1'b0;
            execValidR     <= 1'b0;
            msgDone        <= 1'b0;
            msgTypeOffsetR <= MSG_TYPE_DONE - 1;
        end else begin
            addValidR      <= 1'b0;
            delValidR      <= 1'b0;
            execValidR     <= 1'b0;
            msgDone        <= 1'b0;

            case (byteCntR)
                priceEndR : begin
                    if (addTypeR) begin
                        msgTypeOffsetR <= msgTypeOffsetNext;
                        addValidR      <= 1'b1;
                        msgDone        <= 1'b1;
                    end
                end

                refNumEndR : begin
                    if (delTypeR) begin
                        msgTypeOffsetR <= msgTypeOffsetNext;
                        delValidR      <= 1'b1;
                        msgDone        <= 1'b1;
                    end
                end

                matchNumEndR : begin
                    if (execTypeR) begin
                        msgTypeOffsetR <= msgTypeOffsetNext;
                        execValidR     <= 1'b1;
                        msgDone        <= 1'b1;
                    end
                end
            endcase

            if (dataValidFallingR)
                msgTypeOffsetR <= MSG_TYPE_DONE - 1;
        end
    end

    assign msgTypeOffsetNext = byteCntR + MSG_TYPE_DONE;

    ////////////////////////////////////////////
    // Byte cnt of current frame
    ////////////////////////////////////////////
    always_ff @(posedge clkIn) begin
        if (rstIn) begin
            byteCntR          <= 0;
            locateOffsetR     <= LOCATE_DONE;
            refNumOffsetR     <= REF_NUM_DONE;
            refNumEndR        <= REF_NUM_DONE   - 1;
            matchNumEndR      <= MATCH_NUM_DONE - 1;
            buySellOffsetR    <= BUY_SELL_DONE  - 1;
            sharesOffsetR     <= SHARES_DONE    - 1;
            priceOffsetR      <= PRICE_DONE;
            priceEndR         <= PRICE_DONE     - 1;
            dataValidFallingR <= 1'b0;
            dataValidR        <= 1'b0;
        end else begin
            if (dataValidIn)
                byteCntR       <= byteCntR + 1;
            else if (dataValidFallingR)
                byteCntR       <= '0;

            dataValidR         <= dataValidIn;
            dataValidFallingR  <= dataValidR & ~dataValidIn;

            if (msgDone) begin
                locateOffsetR  <= byteCntR + LOCATE_DONE;
                refNumOffsetR  <= byteCntR + REF_NUM_DONE;
                refNumEndR     <= byteCntR + REF_NUM_DONE   - 1;
                matchNumEndR   <= byteCntR + MATCH_NUM_DONE - 1;
                buySellOffsetR <= byteCntR + BUY_SELL_DONE  - 1;
                sharesOffsetR  <= byteCntR + SHARES_DONE    - 1;
                priceOffsetR   <= byteCntR + PRICE_DONE;
                priceEndR      <= byteCntR + PRICE_DONE     - 1;
            end

            if (dataValidFallingR) begin
                locateOffsetR     <= LOCATE_DONE;
                refNumOffsetR     <= REF_NUM_DONE;
                refNumEndR        <= REF_NUM_DONE   - 1;
                matchNumEndR      <= MATCH_NUM_DONE - 1;
                buySellOffsetR    <= BUY_SELL_DONE  - 1;
                sharesOffsetR     <= SHARES_DONE    - 1;
                priceOffsetR      <= PRICE_DONE;
                priceEndR         <= PRICE_DONE     - 1;
            end
        end
    end

    assign addValidOut  = addValidR;
    assign delValidOut  = delValidR;
    assign execValidOut = execValidR;
    assign locateOut    = locateR;
    assign refNumOut    = refNumR;
    assign sharesOut    = sharesR;
    assign priceOut     = priceR;

endmodule