`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev: Ian Rider
// Purpose: Testbench only tasks, functions, etc
//////////////////////////////////////////////////////////////////////////////////
`include "tb_interfaces.sv"

package tb_pkg;
    import pkg::*;

    ////////////////////////////////////////////
    // Tasks - TB ONLY
    ////////////////////////////////////////////
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

    task send_eth_header (
        virtual eth_udp_if parserIf,
        input ethHeaderType ethHeader);

        begin
            $display("--- SENDING ETHERNET HEADER ---");
            $display("Destination mac: 0x%H", ethHeader.dstMac);
            $display("Source mac:      0x%H", ethHeader.srcMac);
            $display("Ethernet type:   0x%H", ethHeader.ethType);
            for (int i = 0; i < 14; i++) begin
                send_eth_udp_byte(parserIf, ethHeader.dstMac[47:40]);
                ethHeader = ethHeader << 8;
            end
            $display("--- DONE SENDING ETHERNET HEADER ---");
        end
    endtask

    task send_ip_header (
        virtual eth_udp_if parserIf,
        input ipHeaderType ipHeader);

        begin
            $display("--- SENDING IP HEADER ---");
            $display("Version:        0x%H",   ipHeader.ver);
            $display("DSCP/ECN:       0x%H",   ipHeader.dscpEcn);
            $display("Total length:   0x%H",   ipHeader.len);
            $display("ID:             0x%H",   ipHeader.id);
            $display("Flags:          0x%H",   ipHeader.flags);
            $display("TTL:            0x%H",   ipHeader.ttl);
            $display("Protocol:       0x%H",   ipHeader.protocol);
            $display("Check sum:      0x%H",   ipHeader.chkSum);
            $display("Source IP:      0x%H",   ipHeader.srcIp);
            $display("Destination IP: 0x%H",   ipHeader.dstIp);
            for (int i = 0; i < 20; i++) begin
                send_eth_udp_byte(parserIf, ipHeader.ver);
                ipHeader = ipHeader << 8;
            end
            $display("--- DONE SENDING IP HEADER ---");
        end
    endtask

    task send_udp_header (
        virtual eth_udp_if parserIf,
        input udpHeaderType udpHeader);

        begin
            $display("--- SENDING UDP HEADER ---");
            $display("Source port:      0x%H",   udpHeader.srcPort);
            $display("Destination port: 0x%H",   udpHeader.dstPort);
            $display("Udp length:       0x%H",   udpHeader.len);
            $display("Check sum:        0x%H",   udpHeader.chkSum);
            for (int i = 0; i < 8; i++) begin
                send_eth_udp_byte(parserIf, udpHeader.srcPort[15:8]);
                udpHeader = udpHeader << 8;
            end
            $display("--- DONE SENDING UDP HEADER ---");
        end
    endtask

    task send_mold_header (
        virtual eth_udp_if parserIf,
        input moldHeaderType moldHeader);

        begin
            $display("--- SENDING MOLD HEADER ---");
            $display("Session ID:      0x%H",   moldHeader.sessId);
            $display("Sequence number: 0x%H",   moldHeader.seqNum);
            $display("Message count:   0x%H",   moldHeader.msgCnt);
            $display("Mold length:     0x%H",   moldHeader.moldLen);
            for (int i = 0; i < 22; i++) begin
                send_eth_udp_byte(parserIf, moldHeader.sessId[79:72]);
                moldHeader = moldHeader << 8;
            end
            $display("--- DONE SENDING MOLD HEADER ---");
        end
    endtask

    task send_itch_data (
        virtual eth_udp_if parserIf,
        input itchAddOrderType itchData);

        begin
            $display("--- SENDING ITCH DATA ---");
            $display("Message type:           0x%H", itchData.msgType);
            $display("Stock locate:           0x%H", itchData.locate);
            $display("Tracking number:        0x%H", itchData.trackNum);
            $display("Timestamp:              0x%H", itchData.timeStamp);
            $display("Order reference number: 0x%H", itchData.refNum);
            $display("Buy/sell indicator:     0x%H", itchData.buySell);
            $display("Shares:                 0x%H", itchData.shares);
            $display("Stock:                  0x%H", itchData.stock);
            $display("Price:                  0x%H", itchData.price);

            for (int i = 0; i < 36; i++) begin
                send_eth_udp_byte(parserIf, itchData.msgType);
                itchData = itchData << 8;
            end
            $display("--- DONE SENDING ITCH DATA ---");
        end
    endtask;

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