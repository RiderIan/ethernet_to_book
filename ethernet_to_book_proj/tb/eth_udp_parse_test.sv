`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev:     Ian Rider
// Purpose: Verify ethernet/ip/MoldUdp64 parser
//////////////////////////////////////////////////////////////////////////////////
import tb_pkg::*;

module eth_udp_parse_test;

    const int CLK_250_MHZ_PERIOD = 4;

    const int ETH_HEADER_LEN     = 14;
    const int IP_HEADER_LEN      = 20;
    const int UDP_HEADER_LEN     = 8;
    const int MOLD_HEADER_LEN    = 20;
    const int ITCH_DATA_LEN      = 133;
    const int IP_V4_TOTAL_LEN    = ITCH_DATA_LEN + MOLD_HEADER_LEN + UDP_HEADER_LEN + IP_HEADER_LEN + ETH_HEADER_LEN;

    logic [7:0] data, itchData;
    logic       rst, clk250, dataErr, dataValid, itchDataValid;
    eth_udp_if  parserIf(clk250);

    ////////////////////////////////////////////
    // Clock gen
    ////////////////////////////////////////////
    always #(CLK_250_MHZ_PERIOD/2) clk250 = ~clk250;

    ////////////////////////////////////////////
    // DUT: rxClkLcl(125Mhz) -> 250Mhz CDC
    ////////////////////////////////////////////
    eth_udp_parser dut (
        .rstIn(rst),
        .clkIn(clk250),
        .dataIn(parserIf.data),
        .dataValidIn(parserIf.dataValid),
        .dataErrIn(parserIf.dataErr),
        .itchDataOut(itchData),
        .itchDataValidOut(itchDataValid));

    ////////////////////////////////////////////
    // Stimulus
    ////////////////////////////////////////////
    initial begin : drive_data
        rst    = 1'b1;
        clk250 = 1'b0;
        parserIf.reset();
        #20;
        rst    = 1'b0;

        // Send ethernet header
        for (int i = 0; i < ETH_HEADER_LEN; i++) begin
            // Only care about sending ipver=Ipv4 for now
            if (i == 12) begin
                send_eth_udp_byte(parserIf, 8'h08);
            end else if (i == 13) begin
                send_eth_udp_byte(parserIf, 8'h00);
            end else begin
                send_eth_udp_byte(parserIf, i[7:0]);
            end
        end

        // Send Ipv4 header
        for (int i = 0; i < IP_HEADER_LEN; i++) begin
            if (i == 2) begin
                send_eth_udp_byte(parserIf, IP_V4_TOTAL_LEN[15:8]);
            end else if(i == 3) begin
                send_eth_udp_byte(parserIf, IP_V4_TOTAL_LEN[7:0]);
            end else begin
                send_eth_udp_byte(parserIf, i[7:0]);
            end
        end

        // Send UDP header
        for (int i = 0; i < UDP_HEADER_LEN; i++) begin

        end

        // Send MoldUdp64 header
        for (int i = 0; i < MOLD_HEADER_LEN; i++) begin

        end

        // Send itch data
        for (int i = 0; i < ITCH_DATA_LEN; i++) begin

        end






    end

    ////////////////////////////////////////////
    // Output check
    ////////////////////////////////////////////
    initial begin : check_data
        #2000;
        $finish;

    end

endmodule