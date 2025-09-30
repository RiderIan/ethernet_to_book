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
    output logic        buySellOut);


    localparam int ADDR_BITS        = $clog2(ORDER_MAP_DEPTH);
    localparam int REF_IDXING       = ADDR_BITS - 1;
    localparam int REF_DATA_WIDTH   = $bits(refNumIn);
    localparam int ORDER_INFO_WIDTH = $bits(priceIn) + $bits(sharesIn) + $bits(sharesIn);

    logic addrMissR, wrEnA, wrEnB;
    logic [1:0] waitReadAR, waitReadBR;

    (* ram_style = "block" *) logic [REF_DATA_WIDTH-1:0] refNumRamR    [0:ORDER_MAP_DEPTH-1];
    (* ram_style = "block" *) orderDataType              orderInfoRamR [0:ORDER_MAP_DEPTH-1];

    logic [ADDR_BITS-1:0]        hashKey;
    logic [ADDR_BITS-1:0]        addrAR, addrBR;
    logic [REF_DATA_WIDTH-1:0]   refDataAI, refDataDly;
    logic [REF_DATA_WIDTH-1:0]   refDataOAR, refDataOARR, refDataOBR, refDataOBRR;
    orderDataType                orderDataAI, orderData;
    orderDataType                orderDataOBR, orderDataOAR;
    logic                        addValidDlyR, delValidDlyR, execValidDlyR, refNumWrongR, delExecValidR;

    ////////////////////////////////////////////
    // Input regs - delays to account for RAM reads
    ////////////////////////////////////////////
    pipe #(.DEPTH(3)) add_valid_dly_inst  (.rstIn(rstIn), .clkIn(clkIn), .DIn(addValidIn),  .QOut(addValidDlyR));
    pipe #(.DEPTH(3)) del_valid_dly_inst  (.rstIn(rstIn), .clkIn(clkIn), .DIn(delValidIn),  .QOut(delValidDlyR));
    pipe #(.DEPTH(3)) exec_valid_dly_inst (.rstIn(rstIn), .clkIn(clkIn), .DIn(execValidIn), .QOut(execValidDlyR));

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
            refNumRamR[addrBR] <= '0;
        refDataOBR  <= refNumRamR[addrBR];
    end

    always_ff @(posedge clkIn) begin : ref_ram_data_dly_reg
        refDataOBRR <= refDataOBR;
        refDataOARR <= refDataOAR;
    end

    always_ff @(posedge clkIn) begin : order_info_ram_port_a
        if (wrEnA)
            orderInfoRamR[addrAR] <= orderDataAI;
        orderDataOAR  <= orderInfoRamR[addrAR];
    end

    always_ff @(posedge clkIn) begin : order_info_ram_port_b
        if (wrEnB)
            orderInfoRamR[addrBR] <= '0;
        orderDataOBR  <= orderInfoRamR[addrBR];
    end

    ////////////////////////////////////////////
    // Add order
    ////////////////////////////////////////////
    assign hashKey = refNumIn[ADDR_BITS-1      :0]                 ^
                     refNumIn[(ADDR_BITS-1)*2+1:ADDR_BITS]         ^
                     refNumIn[(ADDR_BITS-1)*3+2:(ADDR_BITS-1)*2+2] ^
                     refNumIn[(ADDR_BITS-1)*4+3:(ADDR_BITS-1)*3+3];

    assign orderData = {priceIn, sharesIn, buySellIn};

    pipe #(.DEPTH(3), .WIDTH(ORDER_INFO_WIDTH)) order_data_ram (.rstIn(rstIn), .clkIn(clkIn), .DIn(orderData), .QOut(orderDataAI));
    pipe #(.DEPTH(3), .WIDTH(REF_DATA_WIDTH))   ref_num_ram    (.rstIn(rstIn), .clkIn(clkIn), .DIn(refNumIn),  .QOut(refDataAI));
    pipe #(.DEPTH(3), .WIDTH(REF_DATA_WIDTH))   ref_num_logic  (.rstIn(rstIn), .clkIn(clkIn), .DIn(refNumIn),  .QOut(refDataDly));

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

            if (addValidDlyR | addrMissR) begin
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
    // Delete/Execute order
    ////////////////////////////////////////////
    always_ff @(posedge clkIn) begin : lookup_order
        if (rstIn) begin
            addrBR          <= '0;
            refNumWrongR    <= '0;
            waitReadBR      <= '0;
            wrEnB           <= '0;
            delExecValidOut <= 1'b0;
        end else begin
            wrEnB           <= 1'b0;
            delExecValidOut <= 1'b0;

            if (delValidIn | execValidIn)
                addrBR <= hashKey;

            if (delValidDlyR | execValidDlyR | refNumWrongR) begin
                if (refDataOBRR == refDataDly) begin
                    // Writes zeros to both BRAMs
                    wrEnB           <= 1'b1;
                    refNumWrongR    <= 1'b0;
                    // Drive outputs to book
                    delExecValidOut <= 1'b1;
                end else begin
                    if (waitReadBR == '0)
                        addrBR <= addrBR + 1;

                    waitReadBR   <= waitReadBR + 1;
                    refNumWrongR <= 1'b1;
                end
            end
        end
    end

    ////////////////////////////////////////////
    // Outputs
    ////////////////////////////////////////////
    pipe #(.DEPTH(2), .WIDTH(32)) price_out_inst   (.rstIn(1'b0), .clkIn(clkIn), .DIn(orderDataOBR.price),   .QOut(priceOut));
    pipe #(.DEPTH(2), .WIDTH(32)) shares_out_inst  (.rstIn(1'b0), .clkIn(clkIn), .DIn(orderDataOBR.shares),  .QOut(sharesOut));
    pipe #(.DEPTH(2), .WIDTH( 1)) buysell_out_inst (.rstIn(1'b0), .clkIn(clkIn), .DIn(orderDataOBR.buySell), .QOut(buySellOut));

endmodule