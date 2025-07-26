`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev: Ian Rider
// Purpose: Re-use test bench interface, tasks, and functions 
//////////////////////////////////////////////////////////////////////////////////
`include "tb_interfaces.sv"

package tb_pkg;

    task automatic apply_reset (
        ref logic rst);
        begin
            rst = 1'b1;
            #20;
            rst = 1'b0;
        end
    endtask

    task automatic wait_mmcm_locks (
        ref logic lock0,
        ref logic lock1);

        begin
            wait(lock0 == 1'b1 && lock1 == 1'b1);
        end
    endtask

    task send_rgmii_byte (
        virtual rgmii_rx_if rxIf,
        input logic [7:0] dataByte);

        begin
            @(posedge rxIf.rxClk);
            rxIf.rxCtrl = 1'b1;
            rxIf.rxData = dataByte[7:4];
            @(negedge rxIf.rxClk);
            rxIf.rxCtrl = 1'b1;
            rxIf.rxData = dataByte[3:0];
        end
    endtask

    task send_eth_udp_byte (
        virtual eth_udp_if parserIf,
        input logic [7:0] dataByte);

        begin
            @(posedge parserIf.clk);
            parserIf.dataValid = 1'b1;
            parserIf.data = dataByte;
        end
    endtask

    task check_eth_udp_byte (
        virtual eth_udp_output_if parserOutIf,
        input logic [7:0] expectedDataByte);

        begin
            @(posedge parserOutIf.clk);
            if (parserOutIf.dataValid == 1'b1)
                assert(parserOutIf.data == expectedDataByte) else $fatal("Byte Received: 0x%H", parserOutIf.data, " Expected: 0x%H", expectedDataByte, "  INCORRECT :(");
            $display("Byte Received: 0x%H", parserOutIf.data, " Expected: 0x%H", expectedDataByte, "  CORRECT :)");
        end
    endtask

    task check_rgmii_byte (
        virtual rgmii_rx_output_if rxIf,
        input logic [7:0] expectedDataByte);

        begin
            @(posedge rxIf.rxClkLcl);
            if (rxIf.rxDataValid == 1'b1)
                assert(rxIf.rxData == expectedDataByte) else $fatal("Byte Received: 0x%H", rxIf.rxData, " Expected: 0x%H", expectedDataByte, "  INCORRECT :(");
            $display("Byte Received: 0x%H", rxIf.rxData, " Expected: 0x%H", expectedDataByte, "  CORRECT :)");
        end
    endtask
endpackage