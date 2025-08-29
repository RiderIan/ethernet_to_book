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

    logic       clk125;
    logic       clk250;
    logic       rstRxLcl;

    logic [7:0] rxData;
    logic       rxDataValid;
    logic [7:0] rx250Data;
    logic       rdDataValid;

    real        writeTime[0:499];
    real        readTime[0:499];

    ////////////////////////////////////////////
    // Clock gen
    ////////////////////////////////////////////
    always #(CLK_125_MHX_PERIOD/2) clk125 = ~clk125;
    // Generate random phase relationship to slower clock each run
    initial begin : clk_phase_offset
        int randInit = $urandom(1); // Not actually random so this needs to be changed manually :(
        real clkOffsetNs = $urandom_range(0, CLK_250_MHZ_PERIOD*100) / 400.000; // 0.00ns to 4.00ns
        #(clkOffsetNs);

        forever begin
            #(CLK_250_MHZ_PERIOD/2) clk250 = ~clk250;
        end
    end

    ////////////////////////////////////////////
    // DUT: rxClkLcl(125Mhz) -> 250Mhz CDC
    ////////////////////////////////////////////
    slow_fast_cdc # (
        .LOW_LAT_CDC(1'b1)) // 0=xpm afifo, 1=custom low latency afifo
    dut (
        .wrRstIn(rstRxLcl),
        .wrClkIn(clk125),
        .wrEnIn(rxDataValid),
        .wrDataIn(rxData),
        .rdRstIn(rstRxLcl),
        .rdClkIn(clk250),
        .rdDataOut(rx250Data),
        .rdDataValidOut(rdDataValid));

    ////////////////////////////////////////////
    // Write side stimulus
    ////////////////////////////////////////////
    initial begin : drive_data
        rstRxLcl    = 1'b1;
        clk125      = 1'b0;
        rxDataValid = 1'b0;
        rxData      = 8'h00;
        clk250      = 1'b0;
        #20;
        rstRxLcl    = 1'b0;
        #270 // Wait for FIFO to come out of reset

        for (int i = 0; i < 500; i++) begin
            @(posedge clk125);
            writeTime[i] = $realtime();
            rxData = i[7:0];
            rxDataValid = 1'b1;
        end

        @(posedge clk125);
        rxDataValid = 1'b0;
    end

    ////////////////////////////////////////////
    // Read check
    ////////////////////////////////////////////
    int i = 0;
    initial begin : read_data

        while(i < 500) begin
            @(posedge clk250);
            if (rdDataValid) begin
                assert(rx250Data == i[7:0]) else $fatal("Byte Received: 0x%H", rx250Data, " Expected: 0x%H", i[7:0], "  INCORRECT :(");
                readTime[i] = $realtime();
                $display("Byte Received: 0x%H", rx250Data, " Expected: 0x%H", i[7:0], "  CORRECT :)");
                $display("Write to read latency: ", readTime[i] - writeTime[i]);
                i++;
            end
        end

        $display(" --- TEST PASSED ---");
        #50
        $finish;
    end

endmodule;