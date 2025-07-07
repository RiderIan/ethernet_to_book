`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev: Ian Rider
// Purpose: Verify read write functionality of CDC fifo
//////////////////////////////////////////////////////////////////////////////////
import tb_pkg::*;

module rx_fifo_test;

    // Clock gen
    const int CLK_125_MHX_PERIOD = 8;
    const int CLK_250_MHZ_PERIOD = 4;

    logic clk125;
    logic clk250;
    logic rstRxLcl;

    logic       rxDataValid;
    logic [7:0] rxData;
    logic       udpRdEn;
    logic [7:0] rx250Data;
    logic       rdEmpty;
    logic       rdRstBusy;
    logic       wrRstBusy;
    logic       wrFull;

    always #(CLK_125_MHX_PERIOD/2) clk125 = ~clk125;
    always #(CLK_250_MHZ_PERIOD/2) clk250 = ~clk250;

    ////////////////////////////////////////////
    // rxClkLcl(125Mhz) -> 250Mhz CDC
    ////////////////////////////////////////////
    fifo_cdc dut (
        .wrRstIn(rstRxLcl),        
        .wrClkIn(clk125),
        .wrEnIn(rxDataValid),
        .wrDataIn(rxData),
        .wrFullOut(wrFull),
        .wrRstBusyOut(wrRstBusy),
        .rdClkIn(clk250),
        .rdEnIn(udpRdEn),
        .rdEmptyOut(rdEmpty),
        .rdDataOut(rx250Data),
        .rdRstBusyOut(rdRstBusy));

    initial begin : drive_data
        rstRxLcl = 1'b1;
        clk125   = 1'b0;
        rxDataValid = 1'b0;;
        rxData = 8'h00;
        clk250 = 1'b0;
        udpRdEn = 1'b0;
        #20;
        rstRxLcl = 1'b0;

        wait(wrRstBusy == 1'b0 && rdRstBusy == 1'b0);

        for (int i = 0; i < 10; i++) begin
            @(posedge clk125);
            if (wrFull == 1'b0) begin
                rxData = i;
                rxDataValid = 1'b1;
            end else begin
                rxDataValid = 1'b0;
            end
        end

        @(posedge clk125);
        rxDataValid = 1'b0;
    end

    int i = 0;
    initial begin : read_data

        wait(wrRstBusy == 1'b0 && rdRstBusy == 1'b0);
        while(i < 10) begin
            @(posedge clk250);
            if(rdEmpty == 0) begin
                udpRdEn = 1'b1;
                @(posedge clk250);
                assert(rx250Data == i) else $fatal("Byte Received: 0x%H", rx250Data, " Expected: 0x%H", i, "  INCORRECT :(");
                $display("Byte Received: 0x%H", rx250Data, " Expected: 0x%H", i, "  CORRECT :(");
                i++;
            end else begin
                udpRdEn = 1'b0;
            end
        end

        $display(" --- TEST PASSED ---");
        $finish;

    end

endmodule;