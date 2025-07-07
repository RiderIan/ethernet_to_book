`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev: Ian Rider
// Purpose: Generate local clocks with 100Mhz board clock and 125Mhz PHY rxClk
//////////////////////////////////////////////////////////////////////////////////

// TODO: Replace this with custom async fifo that is only 4 deep

module fifo_cdc (
    input  logic       wrRstIn,
    input  logic       wrClkIn,
    input  logic       wrEnIn,
    input  logic [7:0] wrDataIn,
    output logic       wrFullOut,
    output logic       wrRstBusyOut,

    input  logic       rdClkIn,
    input  logic       rdEnIn,
    output logic [7:0] rdDataOut,
    output logic       rdEmptyOut,
    output logic       rdRstBusyOut);

    logic wrEn;
    logic wrFull;
    logic wrRstBusy;
    logic rdEn;
    logic rdEmpty;
    logic rdRstBusy;

    // Should never be full as 250 domain will constantly read when not empty
    assign wrEn = (wrEnIn & ~wrFull  & ~wrRstBusy & ~rdRstBusy);
    assign rdEn = (rdEnIn & ~rdEmpty & ~wrRstBusy & ~rdRstBusy);
    
    // May want to implement custom 4-deep async fifo to reduce latency
    xpm_fifo_async #(
        .FIFO_MEMORY_TYPE("distributed"),
        .FIFO_WRITE_DEPTH(16),
        .READ_DATA_WIDTH(8),
        .SIM_ASSERT_CHK(1),
        .WRITE_DATA_WIDTH(8)) 
    xpm_fifo_async_inst (
        .rst(1'b0),               // Write domain

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
        .dout(rdDataOut),         // Out
        .rd_rst_busy(rdRstBusy)); // Out

    assign wrRstBusyOut = wrRstBusy;
    assign wrFullOut    = wrFull;
    assign rdEmptyOut   = rdEmpty;
    assign rdRstBusyOut = rdRstBusy;

endmodule