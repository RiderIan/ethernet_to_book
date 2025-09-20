`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev: Ian Rider
// Purpose: Transfer bytes from MAC domain (125Mhz) to unrelated 250Mhz domain.
//          Includes both tranditional async FIFO method as well as lower latency
//          circular AFIFO approach.
//
//          Custom AFIFO has 14ns of latency as is compared to 42ns of latency of xpm
//          AFIFIO without any additional pipelining (which is required to pass timing).
//          Latency was measure with slow/fast clocks perfectly in phase.
//////////////////////////////////////////////////////////////////////////////////

module slow_fast_cdc # (
    parameter logic LOW_LAT_CDC = 1'b0,
    parameter int   RAM_DEPTH   = 8) (

    input  logic       wrRstIn,
    input  logic       wrClkIn,
    input  logic       wrEnIn,
    input  logic [7:0] wrDataIn,

    input  logic       rdRstIn,
    input  logic       rdClkIn,
    output logic [7:0] rdDataOut,
    output logic       rdDataValidOut);

    localparam int DATA_WIDTH = $bits(wrDataIn);

    generate

        ////////////////////////////////////////////
        // Custom low-latency CDC approach
        // 14ns of latency from wrEnIn='1' to rdDataValidOut='1'
        ////////////////////////////////////////////
        if (LOW_LAT_CDC) begin

            localparam int ADDR_BITS = $clog2(RAM_DEPTH);
            logic [DATA_WIDTH-1:0] cdcRamR [0:RAM_DEPTH-1], wrDataR, rdData;
            logic [ADDR_BITS-1:0]  wrAddrR, rdAddr, grayAddr, graySyncR, graySyncRR, graySyncRRR;
            logic                  wrEnR, rdDataValid;

            ////////////////////////////////////////////
            // Circular AFIFO write side
            ////////////////////////////////////////////
            always_ff @(posedge wrClkIn) begin : write_data_pipe
                if (wrRstIn) begin
                    wrEnR   <= '0;
                    wrDataR <= '0;
                end else begin
                    wrEnR   <= wrEnIn;
                    wrDataR <= wrDataIn;
                end
            end

            always_ff @(posedge wrClkIn) begin : addr_generator
                if (wrRstIn) begin
                    wrAddrR <= '0;
                end else begin
                    if (wrEnIn)
                        wrAddrR <= wrAddrR + 1;
                end
            end

            assign grayAddr = grayBin#(ADDR_BITS)::bin2gray(wrAddrR);

            always_ff @(posedge wrClkIn) begin : ram_write_port
                if (wrEnR)
                    cdcRamR[wrAddrR] <= wrDataR;
            end

            ////////////////////////////////////////////
            // Circular AFIFO read side
            ////////////////////////////////////////////
            always_ff @(posedge rdClkIn) begin : gray_sync
                if (rdRstIn) begin
                    graySyncR   <= '0;
                    graySyncRR  <= '0;
                    graySyncRRR <= '0;
                end else begin
                    graySyncR   <= grayAddr;
                    graySyncRR  <= graySyncR;
                    graySyncRRR <= graySyncRR;
                end
            end

            assign rdAddr         = grayBin#(ADDR_BITS)::gray2bin(graySyncRR);

            always_ff @(posedge rdClkIn) begin : ram_data_reg
                rdDataOut      <= cdcRamR[rdAddr];
            end

            always_ff @(posedge rdClkIn) begin : data_valid_reg
                if (rdRstIn) begin
                    rdDataValidOut <= 1'b0;
                end else begin
                    rdDataValidOut <= graySyncRRR != graySyncRR;
                end
            end

        ////////////////////////////////////////////
        // Standard Xilinx AFIFO CDC approach
        // 42ns of latency from wrEnIn='1' to rdDataValidOut='1'
        ////////////////////////////////////////////
        end else begin
            logic wrEn;
            logic wrFull;
            logic wrRstBusy;
            logic rdEn;
            logic rdEmpty;
            logic rdRstBusy;
            logic [7:0] rdData;
            // Should never be full as 250 domain will constantly read when not empty
            assign wrEn = (wrEnIn   & ~wrFull    & ~wrRstBusy & ~rdRstBusy);
            assign rdEn = (~rdEmpty & ~wrRstBusy & ~rdRstBusy);

            xpm_fifo_async #(
                .FIFO_MEMORY_TYPE("distributed"),
                .FIFO_WRITE_DEPTH(16),
                .READ_DATA_WIDTH(DATA_WIDTH),
                .READ_MODE("fwft"),
                .SIM_ASSERT_CHK(1),
                .WRITE_DATA_WIDTH(DATA_WIDTH))
            xpm_fifo_async_inst (
                .rst(wrRstIn),            // Write domain

                // Write domain 125Mhz
                .wr_clk(wrClkIn),         // In
                .wr_en(wrEn),             // In
                .din(wrDataIn),           // In
                .full(wrFull),            // Out
                .wr_rst_busy(wrRstBusy),  // Out

                // Read domain 250Mhz
                .rd_clk(rdClkIn),         // In
                .rd_en(rdEn),             // In
                .empty(rdEmpty),          // Out
                .dout(rdData),            // Out
                .rd_rst_busy(rdRstBusy)); // Out

            // Latency benchmark based off these connections
            // assign rdDataOut = rdData;
            // assign rdDataValidOut = rdEn;

            // Required to pass timing last time it was checked
            always_ff @(posedge rdClkIn) begin : data_out_pipe
                rdDataOut <= rdData;
            end

            always_ff @(posedge rdClkIn) begin : valid_out_pipe
                if (rdRstIn) begin
                    rdDataValidOut <= '0;
                end else begin
                    rdDataValidOut <= rdEn;
                end
            end
        end
    endgenerate

endmodule