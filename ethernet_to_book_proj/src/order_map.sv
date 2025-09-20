`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev: Ian Rider
// Purpose: Variable depth map that store reference number, price, shares, and side
//          of every received order.
//////////////////////////////////////////////////////////////////////////////////
import pkg::*;

////////////////////////////////////////////
// IN PROGRESS
////////////////////////////////////////////

////////////////////////////////////////////
// IN PROGRESS
////////////////////////////////////////////

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

    logic addrMissR, wrEnA, wrEnB;
    logic [1:0] waitReadAR;

    logic [REF_DATA_WIDTH-1:0]   refNumRamR    [0:ORDER_MAP_DEPTH-1];
    orderDataType                orderInfoRamR [0:ORDER_MAP_DEPTH-1];

    logic [ADDR_BITS-1:0]        hashKey;
    logic [ADDR_BITS-1:0]        addrAR, addrBR;
    logic [REF_DATA_WIDTH-1:0]   refDataAI, refDataBIR;
    logic [REF_DATA_WIDTH-1:0]   refDataOAR, refDataOARR, refDataOBR;
    orderDataType                orderDataAI, orderDataBIO, rderData;
    orderDataType                orderDataOAR, orderDataOBR;
    logic                        addValidR, delValidR, execValidR;

    ////////////////////////////////////////////
    // Input regs - delays to account for RAM reads
    ////////////////////////////////////////////
    always_ff @(posedge clkIn) begin : input_regs
        if (rstIn) begin
            addValidR  <= 1'b0;
            delValidR  <= 1'b0;
            execValidR <= 1'b0;
        end else begin
            addValidR  <= addValidIn;
            delValidR  <= delValidIn;
            execValidR <= execValidIn;
        end
    end

    ////////////////////////////////////////////
    // RAMS
    ////////////////////////////////////////////
    initial $readmemh("D:/FPGA/git_wa/ethernet_to_book_proj/src/reuse/init_ram_zeros.mem", refNumRamR);
    initial $readmemh("D:/FPGA/git_wa/ethernet_to_book_proj/src/reuse/init_ram_zeros.mem", orderInfoRamR);

    always_ff @(posedge clkIn) begin : ref_num_ram_port_a
        if (wrEnA)
            refNumRamR[addrAR] <= refDataAI;
        refDataOAR  <= refNumRamR[addrAR];
    end

    always_ff @(posedge clkIn) begin : ref_num_ram_port_b
        if (wrEnB)
            refNumRamR[addrBR] <= refDataBIR;
        refDataOBR  <= refNumRamR[addrBR];
    end

    always_ff @(posedge clkIn) begin : order_info_ram_port_a
        if (wrEnA)
            orderInfoRamR[addrAR] <= orderDataAI;
        orderDataOAR  <= orderInfoRamR[addrAR];
    end

    always_ff @(posedge clkIn) begin : order_info_ram_port_b
        if (wrEnB)
            orderInfoRamR[addrBR] <= orderDataBIO;
        orderDataOBR  <= orderInfoRamR[addrBR];
    end


    ////////////////////////////////////////////
    // Write side (add only)
    ////////////////////////////////////////////
    assign hashKey = refNumIn[ADDR_BITS-1      :0]                 ^
                     refNumIn[(ADDR_BITS-1)*2+1:ADDR_BITS]         ^
                     refNumIn[(ADDR_BITS-1)*3+2:(ADDR_BITS-1)*2+2] ^
                     refNumIn[(ADDR_BITS-1)*4+3:(ADDR_BITS-1)*3+3];

    always_ff @(posedge clkIn) begin : ram_a_input_reg
        orderDataAI <= {priceIn, sharesIn, buySellIn};
        refDataAI   <= refNumIn;
        refDataOARR <= refDataOAR;
    end

    always_ff @(posedge clkIn) begin : insert_order
        if (rstIn) begin
            addrAR       <= '0;
            wrEnA        <= '0;
            addrMissR    <= '0;
            waitReadAR   <= '0;
        end else begin
            wrEnA        <= 1'b0;

            if (addValidIn)
                addrAR  <= hashKey;

            if (addValidR | addrMissR) begin
                if (refDataOARR == '0) begin
                    wrEnA        <= 1'b1;
                    addrMissR    <= 1'b0;
                end else begin
                    // Need one extra clock after addr increment to get new value back
                    // Asynchronous read not really possible with BRAM (too large for distrubuted)
                    if (waitReadAR == '0)
                        addrAR      <= addrAR + 1;

                    waitReadAR <= waitReadAR + 1;
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
    assign orderDataOut = orderDataOAR;  // temp
    assign refDataOut   = refDataOAR;    // temp




endmodule