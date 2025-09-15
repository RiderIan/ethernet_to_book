`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev: Ian Rider
// Purpose: Variable depth map that store reference number, price, shares, and side
//          of every received order.
//////////////////////////////////////////////////////////////////////////////////
import pkg::*;

module order_map # (
    // Must be power of two
    // max 65536 for hash key calc (way too large for Artix 7 anyways
    parameter int ORDER_MAP_DEPTH)(

    input  logic        rstIn,
    input  logic        clkIn,

    input  logic        addValidIn,
    input  logic        delValidIn,
    input  logic        execValidIn,

    input  logic [63:0] refNumIn,
    input  logic [15:0] locateIn,
    input  logic [31:0] priceIn,
    input  logic [31:0] sharesIn,
    input  logic        buySellIn,

    output logic        delExecValidOut,
    output logic [15:0] locateOut,
    output logic [31:0] priceOut,
    output logic [31:0] sharesOut,
    output logic        buySellOut,

    output orderDataType orderDataOut, // temp
    output logic [64:0]  refDataOut);  // temp


    localparam int ADDR_BITS        = $clog2(ORDER_MAP_DEPTH);
    localparam int REF_IDXING       = ADDR_BITS - 1;
    localparam int REF_DATA_WIDTH   = $bits(refNumIn);
    localparam int ORDER_INFO_WIDTH = $bits(priceIn) + $bits(sharesIn) + $bits(sharesIn);

    logic addrMissR, wrEnA, waitReadAR;

    logic [REF_DATA_WIDTH-1:0]   refNumRamR    [0:ORDER_MAP_DEPTH-1];
    orderDataType                orderInfoRamR [0:ORDER_MAP_DEPTH-1];

    logic [ADDR_BITS-1:0]        hashKey;
    logic [ADDR_BITS-1:0]        addrAR, addrARR;
    logic [REF_DATA_WIDTH-1:0]   refDataI;
    logic [REF_DATA_WIDTH-1:0]   refDataOR, refDataORR;
    orderDataType                orderDataI, orderData;
    orderDataType                orderDataOR, orderDataORR;

    ////////////////////////////////////////////
    // RAMS
    ////////////////////////////////////////////
    initial $readmemh("D:/FPGA/git_wa/ethernet_to_book_proj/src/reuse/init_ram_zeros.mem", refNumRamR);
    initial $readmemh("D:/FPGA/git_wa/ethernet_to_book_proj/src/reuse/init_ram_zeros.mem", orderInfoRamR);

    always_ff @(posedge clkIn) begin : ref_num_ram_a
        if (wrEnA)
            refNumRamR[addrARR] <= refDataI;
        refDataOR  <= refNumRamR[addrARR];
        refDataORR <= refDataOR
    end

    always_ff @(posedge clkIn) begin : order_info_ram_a
        if (wrEnA)
            orderInfoRamR[addrARR] <= orderDataI;
        orderDataOR  <= orderInfoRamR[addrARR];
        orderDataORR <= orderDataOR
    end


    ////////////////////////////////////////////
    // Write side (add only)
    ////////////////////////////////////////////
    assign hashKey = refNumIn[ADDR_BITS-1      :0]                 ^
                     refNumIn[(ADDR_BITS-1)*2+1:ADDR_BITS]         ^
                     refNumIn[(ADDR_BITS-1)*3+2:(ADDR_BITS-1)*2+2] ^
                     refNumIn[(ADDR_BITS-1)*4+3:(ADDR_BITS-1)*3+3];

    assign orderData = {priceIn, sharesIn, buySellIn};

    always_ff @(posedge clkIn) begin : insert_order
        if (rstIn) begin
            refDataI   <= '0;
            orderDataI <= '0;
            addrAR     <= '0;
            addrARR    <= '0;
            wrEnA      <= '0;
            addrMissR  <= '0;
            waitReadAR <= '0;
        end else begin
            addrAR  <= hashKey;
            addrARR <= addrAR;
            wrEnA   <= 1'b0;

            if (addValidIn | addrMissR) begin
                if (refDataORR == '0) begin
                    refDataI   <= refNumIn;
                    orderDataI <= orderData;
                    wrEnA      <= 1'b1;
                    addrMissR  <= 1'b0;
                    addrAR     <= addrAR;
                end else begin
                    // Need one extra clock after addr increment to get new value back
                    // Asynchronous read not really possible with BRAM (too large for distrubuted)
                    if (~waitReadAR)
                        addrAR      <= addrAR + 1;

                    waitReadAR <= ~waitReadAR;
                    addrMissR <= 1'b1;
                end
            end
        end
    end


    ////////////////////////////////////////////
    // Read side
    ////////////////////////////////////////////

    ////////////////////////////////////////////
    // Outputs
    ////////////////////////////////////////////
    assign orderDataOut = orderDataORR;  // temp
    assign refDataOut   = refDataORR;      // temp




endmodule