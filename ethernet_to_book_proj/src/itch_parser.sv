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
    logic [10:0] byteCntR, byteCntRR;
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
            if (dataValidIn & (byteCntR == 0)) begin
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
        if (dataValidIn & (byteCntR < LOCATE_DONE)) begin
            locateR <= (locateR << 8) | dataIn;
        end
    end

    ////////////////////////////////////////////
    // Reference number
    ////////////////////////////////////////////
    always_ff @(posedge clkIn) begin : ref_num_capture
        if (dataValidIn & (byteCntR < REF_NUM_DONE)) begin
            refNumR <= (refNumR << 8) | dataIn;
        end
    end

    ////////////////////////////////////////////
    // Buy/sell
    ////////////////////////////////////////////
    always_ff @(posedge clkIn) begin : buy_sell_capture
        // No reset becuase both '0' and '1' are valid states
        // Might not be the most safe way to do this
        if (dataValidIn & (byteCntR == BUY_SELL_DONE  - 1)) begin
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
        if (dataValidIn & (byteCntRR < SHARES_DONE))
            sharesR <= (sharesR << 8) | dataIn;
    end

    ////////////////////////////////////////////
    // Price
    ////////////////////////////////////////////
    always_ff @(posedge clkIn) begin : price_capture
        if (dataValidIn & (byteCntR < PRICE_DONE))
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
        end else begin
            addValidR      <= 1'b0;
            delValidR      <= 1'b0;
            execValidR     <= 1'b0;
            msgDone        <= 1'b0;

            // TODO: Simplify to &
            addValidR      <= msgDone ? addTypeR  : 1'b0;
            delValidR      <= msgDone ? delTypeR  : 1'b0;

            case (byteCntR)
                (PRICE_DONE - 1) : begin
                    if (addTypeR & ~msgDone) begin
                        msgDone <= 1'b1;
                    end
                end

                (REF_NUM_DONE - 1) : begin
                    if (delTypeR & ~msgDone) begin
                        msgDone <= 1'b1;
                    end
                end

                // Execute valid asserts before exec shares and match number
                // If executed shares is implement this will need to be bumped up to that
                REF_NUM_DONE : begin
                    if (execTypeR & ~execValidR) begin
                        execValidR <= 1'b1;
                    end
                end

                (MATCH_NUM_DONE - 1) : begin
                    if (execTypeR & ~msgDone) begin
                        msgDone <= 1'b1;
                    end
                end

            endcase
        end
    end

    ////////////////////////////////////////////
    // Byte cnt of current frame
    ////////////////////////////////////////////
    always_ff @(posedge clkIn) begin
        if (rstIn) begin
            byteCntR <= '0;
        end else begin
            if (msgDone)
                byteCntR <= '0;
            else if (dataValidIn)
                byteCntR <= byteCntR + 1;
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