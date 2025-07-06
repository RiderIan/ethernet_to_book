`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev: Ian Rider
// Purpose: Generate local clocks with 100Mhz board clock and 125Mhz PHY rxClk
//////////////////////////////////////////////////////////////////////////////////

module low_latency_cdc (
    input logic        rstIn,
    input logic        clk125In,
    input logic        clk250In,
    input logic [7:0]  rxDataIn,
    input logic        rxDataValidIn,
    input logic        rxDataLastIn,
    
    output logic [7:0] macDataOut);

    xpm_fifo_async #(
        .FIFO_MEMORY_TYPE("distributed"),
        .FIFO_WRITE_DEPTH(4),
        .READ_DATA_WIDTH(8),
        .SIM_ASSERT_CHK(1),
        .WRITE_DATA_WIDTH(8)

    ) xpm_fifo_async_inst (
        .rst(rstIn),
        .wr_clk(clk125In),
        .wr_en(rxDataValidIn),
        .din(rxDataIn)

        .rd_clk(clk250In),
        .rd_en(1'b1),
        .dout(macDataOut)


    );

endmodule