`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev: Ian Rider
// Purpose: Transfer bytes from MAC domain (125Mhz) to unrelated 250Mhz domain.
//          Includes both tranditional async FIFO method as well as lower latency
//          grey-code tagged method. The latter is potentially novel and has not
//          been thoroughly verified. 
//////////////////////////////////////////////////////////////////////////////////

module slow_fast_cdc # (
    parameter logic XPERIMENTAL_LOW_LAT_CDC = 1'b0, // TRUE:  Grey-code tagged CDC (not verified) FALSE: Traditional async fifo CDC
    parameter int   GREY_WIDTH  = 8)                // Width of grey-code counter appened to data, wider=safer?
(
    input  logic       wrRstIn,
    input  logic       wrClkIn,
    input  logic       wrEnIn,
    input  logic [7:0] wrDataIn,

    input  logic       rdRstIn,
    input  logic       rdClkIn,
    output logic [7:0] rdDataOut,
    output logic       rdDataValidOut,
    output logic       rdDataErrOut);


    generate 
        if (XPERIMENTAL_LOW_LAT_CDC) begin
            // GREY-CODE TAGGED CDC (lower latency but probably not as safe as async fifio)
            // Latency is about 14ns-16ns (depends on phase relationship) compared to ~34ns latency of FIFO
            logic [GREY_WIDTH+7:0] dataGreyR, dataEncodR, dataEncodRR, dataEncodRRR; 
            logic [GREY_WIDTH-1:0] greyAppendR, nextGreyR, cntSlow, cntFast;
            logic                  newGrey, newGreyR;

            ////////////////////////////////////////////
            // Write side (slow)
            ////////////////////////////////////////////
            always_ff @(posedge wrClkIn) begin
                if (wrRstIn) begin
                    cntSlow     <= 2'b10;
                    greyAppendR <= 1'b1;
                    dataGreyR   <= '0;
                end else begin
                    if (wrEnIn) begin
                        dataGreyR   <= {greyAppendR, wrDataIn};
                        greyAppendR <= cntSlow ^ (cntSlow >> 1); // Convert to grey
                        cntSlow     <= cntSlow + 1'b1;
                    end
                end
            end

            ////////////////////////////////////////////
            // Read side (fast)
            ////////////////////////////////////////////
            // Synchonizer
            always_ff @(posedge rdClkIn) begin
                // Only rst bc control signals assigned concurrently based off these
                if (rdRstIn) begin
                    dataEncodR   <= '0;
                    dataEncodRR  <= '0; 
                    dataEncodRRR <= '0;
                end else begin
                    dataEncodR   <= dataGreyR;
                    dataEncodRR  <= dataEncodR;
                    dataEncodRRR <= dataEncodRR;
                end
            end

            // Calculate grey-code
            always_ff @(posedge rdClkIn) begin
                if (rdRstIn) begin
                    cntFast   <= 2'b10;
                    nextGreyR <= 1'b1; // Grey code initalized to 0 so first expected is 1
                    newGreyR  <= 1'b0;
                end else begin
                    // Needs to be delayed a clock to let data get through sycnhronizer
                    newGreyR     <= newGrey;

                    if (newGreyR) begin
                        nextGreyR <= cntFast ^ (cntFast >> 1); // Convert to grey
                        cntFast   <= cntFast + 1;
                    end
                end
            end

            // Only detect new grey-code on first two stable samples
            // Using 'R' and 'RR' works in sim but comparing on an unstable signal is bad practice
            assign newGrey        = (dataEncodRRR[GREY_WIDTH+7:8] != dataEncodRR[GREY_WIDTH+7:8]);
            assign rdDataValidOut = ((dataEncodRRR[GREY_WIDTH+7:8] == nextGreyR) & newGreyR);
            assign rdDataErrOut   = ((dataEncodRRR[GREY_WIDTH+7:8] != nextGreyR) & newGreyR);
            assign rdDataOut      = dataEncodRRR[7:0];
    
        end else begin
            // ASYNC FIFO
            logic wrEn;
            logic wrFull;
            logic wrRstBusy;
            logic rdEn;
            logic rdEmpty;
            logic rdRstBusy;
            // Should never be full as 250 domain will constantly read when not empty
            assign wrEn = (wrEnIn   & ~wrFull    & ~wrRstBusy & ~rdRstBusy);
            assign rdEn = (~rdEmpty & ~wrRstBusy & ~rdRstBusy);

            xpm_fifo_async #(
                .FIFO_MEMORY_TYPE("distributed"),
                .FIFO_WRITE_DEPTH(16),
                .READ_DATA_WIDTH(8),
                .READ_MODE("fwft"),
                .SIM_ASSERT_CHK(1),
                .WRITE_DATA_WIDTH(8)) 
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
                .dout(rdDataOut),         // Out
                .rd_rst_busy(rdRstBusy)); // Out

            assign rdDataValidOut = rdEn;
        end
    endgenerate

endmodule