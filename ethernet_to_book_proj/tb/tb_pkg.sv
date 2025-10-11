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
            @(posedge rxIf.clk);
            rxIf.ctrl = 1'b1;
            rxIf.data = dataByte[7:4];
            @(negedge rxIf.clk);
            rxIf.ctrl = 1'b1;
            rxIf.data = dataByte[3:0];
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

    task send_eth_header_rgmii (
        virtual rgmii_rx_if rxIf,
        input ethHeaderType ethHeader);

        begin
            $display("--- SENDING ETHERNET HEADER ---");
            $display("Destination mac: 0x%H", ethHeader.dstMac);
            $display("Source mac:      0x%H", ethHeader.srcMac);
            $display("Ethernet type:   0x%H", ethHeader.ethType);
            for (int i = 0; i < 14; i++) begin
                send_rgmii_byte(rxIf, ethHeader.dstMac[47:40]);
                ethHeader = ethHeader << 8;
            end
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
        end
    endtask

    task send_ip_header_rgmii (
        virtual rgmii_rx_if rxIf,
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
                send_rgmii_byte(rxIf, ipHeader.ver);
                ipHeader = ipHeader << 8;
            end
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
        end
    endtask

    task send_udp_header_rgmii (
        virtual rgmii_rx_if rxIf,
        input udpHeaderType udpHeader);

        begin
            $display("--- SENDING UDP HEADER ---");
            $display("Source port:      0x%H",   udpHeader.srcPort);
            $display("Destination port: 0x%H",   udpHeader.dstPort);
            $display("Udp length:       0x%H",   udpHeader.len);
            $display("Check sum:        0x%H",   udpHeader.chkSum);
            for (int i = 0; i < 8; i++) begin
                send_rgmii_byte(rxIf, udpHeader.srcPort[15:8]);
                udpHeader = udpHeader << 8;
            end
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
        end
    endtask

    task send_mold_header_rgmii (
        virtual rgmii_rx_if rxIf,
        input moldHeaderType moldHeader);

        begin
            $display("--- SENDING MOLD HEADER ---");
            $display("Session ID:      0x%H",   moldHeader.sessId);
            $display("Sequence number: 0x%H",   moldHeader.seqNum);
            $display("Message count:   0x%H",   moldHeader.msgCnt);
            $display("Mold length:     0x%H",   moldHeader.moldLen);
            for (int i = 0; i < 22; i++) begin
                send_rgmii_byte(rxIf, moldHeader.sessId[79:72]);
                moldHeader = moldHeader << 8;
            end
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
        end
    endtask

    task send_itch_order_rgmii (
        virtual rgmii_rx_if rxIf,
        input itchAddOrderType itchData);

        begin
            $display("--- SENDING ITCH ADD ORDER ---");
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
                send_rgmii_byte(rxIf, itchData.msgType);
                itchData = itchData << 8;
            end
        end
    endtask;

    task send_itch_delete_rgmii (
        virtual rgmii_rx_if rxIf,
        input itchDeleteOrderType itchData);

        begin
            $display("--- SENDING ITCH DELETE ORDER ---");
            $display("Message type:           0x%H", itchData.msgType);
            $display("Stock locate:           0x%H", itchData.locate);
            $display("Tracking number:        0x%H", itchData.trackNum);
            $display("Timestamp:              0x%H", itchData.timeStamp);
            $display("Order reference number: 0x%H", itchData.refNum);
            for (int i = 0; i < 19; i++) begin
                send_rgmii_byte(rxIf, itchData.msgType);
                itchData = itchData << 8;
            end
        end
    endtask;

    task send_itch_execute_rgmii (
        virtual rgmii_rx_if rxIf,
        input itchOrderExecutedType itchData);

        begin
            $display("--- SENDING ITCH EXECUTE ORDER ---");
            $display("Message type:           0x%H", itchData.msgType);
            $display("Stock locate:           0x%H", itchData.locate);
            $display("Tracking number:        0x%H", itchData.trackNum);
            $display("Timestamp:              0x%H", itchData.timeStamp);
            $display("Order reference number: 0x%H", itchData.refNum);
            $display("Executed shares:        0x%H", itchData.execShares);
            $display("Match number:           0x%H", itchData.matchNum);

            for (int i = 0; i < 31; i++) begin
                send_rgmii_byte(rxIf, itchData.msgType);
                itchData = itchData << 8;
            end
        end
    endtask;

    task send_itch_order (
        virtual eth_udp_if parserIf,
        input itchAddOrderType itchData);

        begin
            $display("--- SENDING ADD ITCH ORDER ---");
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
                @(posedge parserIf.clk);
                parserIf.dataValid = 1'b0;
                itchData = itchData << 8;
            end
        end
    endtask;

    task send_itch_del_order (
        virtual eth_udp_if parserIf,
        input itchDeleteOrderType itchData);

        begin
            $display("--- SENDING ITCH DELETE ORDER ---");
            $display("Message type:           0x%H", itchData.msgType);
            $display("Stock locate:           0x%H", itchData.locate);
            $display("Tracking number:        0x%H", itchData.trackNum);
            $display("Timestamp:              0x%H", itchData.timeStamp);
            $display("Order reference number: 0x%H", itchData.refNum);

            for (int i = 0; i < 19; i++) begin
                send_eth_udp_byte(parserIf, itchData.msgType);
                @(posedge parserIf.clk);
                parserIf.dataValid = 1'b0;
                itchData = itchData << 8;
            end
        end
    endtask;

    task send_itch_exec_order (
        virtual eth_udp_if parserIf,
        input itchOrderExecutedType itchData);

        begin
            $display("--- SENDING ITCH EXECUTE ORDER ---");
            $display("Message type:           0x%H", itchData.msgType);
            $display("Stock locate:           0x%H", itchData.locate);
            $display("Tracking number:        0x%H", itchData.trackNum);
            $display("Timestamp:              0x%H", itchData.timeStamp);
            $display("Order reference number: 0x%H", itchData.refNum);
            $display("Executed shares:        0x%H", itchData.execShares);
            $display("Match number:           0x%H", itchData.matchNum);

            for (int i = 0; i < 31; i++) begin
                send_eth_udp_byte(parserIf, itchData.msgType);
                @(posedge parserIf.clk);
                parserIf.dataValid = 1'b0;
                itchData = itchData << 8;
            end
        end
    endtask;

    task check_eth_udp_byte (
        virtual eth_udp_output_if parserOutIf,
        input logic [7:0] expectedDataByte);

        begin
            @(posedge parserOutIf.dataValid);
            assert(parserOutIf.data == expectedDataByte) else $fatal("Byte Received: 0x%H Expected: 0x%H   INCORRECT :(", parserOutIf.data, expectedDataByte);
            $display("Byte Received: 0x%H", parserOutIf.data, " Expected: 0x%H", expectedDataByte, "  CORRECT :)");
        end
    endtask

    task check_rgmii_byte (
        virtual rgmii_rx_output_if rxIf,
        input logic [7:0] expectedDataByte);

        begin
            @(posedge rxIf.rxClkLcl);
            if (rxIf.rxDataValid == 1'b1) begin
                assert(rxIf.rxData == expectedDataByte) else $fatal("Byte Received: 0x%H", rxIf.rxData, " Expected: 0x%H", expectedDataByte, "  INCORRECT :(");
                $display("Byte Received: 0x%H", rxIf.rxData, " Expected: 0x%H", expectedDataByte, "  CORRECT :)");
            end
        end
    endtask

    task check_itch_add (
        virtual itch_add_output_if addIf,
        input itchAddOrderType addOrder);

        logic buySellStim;

        @(posedge addIf.valid);
        assert(addIf.locate  == addOrder.locate)   else $fatal ("Incorrect locate received : %H Expected: %H", addIf.locate,  addOrder.locate);
        assert(addIf.refNum  == addOrder.refNum)   else $fatal ("Incorrect refNum received : %H Expected: %H", addIf.refNum,  addOrder.refNum);
        assign buySellStim  = (addOrder.buySell == BUY) ? 1'b1 : 1'b0;
        assert(addIf.buySell == buySellStim)       else $fatal ("Incorrect buySell received: %H Expected: %H", addIf.buySell, addOrder.buySell);
        assert(addIf.shares  == addOrder.shares)   else $fatal ("Incorrect shares received : %H Expected: %H", addIf.shares,  addOrder.shares);
        assert(addIf.price   == addOrder.price)    else $fatal ("Incorrect price received  : %H Expected: %H", addIf.price,   addOrder.price);
    endtask

    task check_itch_del (
        virtual itch_del_output_if delIf,
        input itchDeleteOrderType delOrder);

        @(posedge delIf.valid);
        assert(delIf.locate  == delOrder.locate)   else $fatal ("Incorrect locate received : %H Expected: %H", delIf.locate,  delOrder.locate);
        assert(delIf.refNum  == delOrder.refNum)   else $fatal ("Incorrect refNum received : %H Expected: %H", delIf.refNum,  delOrder.refNum);
    endtask

    task check_itch_exec (
        virtual itch_exec_output_if execIf,
        input itchOrderExecutedType execOrder);

        @(posedge execIf.valid);
        assert(execIf.locate  == execOrder.locate)   else $fatal ("Incorrect locate received : %H Expected: %H", execIf.locate,  execOrder.locate);
        assert(execIf.refNum  == execOrder.refNum)   else $fatal ("Incorrect refNum received : %H Expected: %H", execIf.refNum,  execOrder.refNum);
    endtask

    function automatic check_price_levels (
        input logic [31:0] priceLevels [],
        input logic [31:0] expectedLevels []);

        for (int i = $left(priceLevels); i <= $right(priceLevels); i++) begin
            assert(priceLevels[i] == expectedLevels[i]) else $fatal("Price level : %D incorrect. Received: %H Expected: %H", (i + 1), priceLevels[i], expectedLevels[i]);
            $display("Correct price level ", (i + 1), " received: ", priceLevels[i]);
        end

    endfunction

    function automatic check_quant_levels (
        input logic [31:0] quantLevels [],
        input logic [31:0] expectedLevels []);

        for (int i = $left(quantLevels); i <= $right(quantLevels); i++) begin
            assert(quantLevels[i] == expectedLevels[i]) else $fatal("Quant level : %D incorrect. Received: %H Expected: %H", (i + 1), quantLevels[i], expectedLevels[i]);
            $display("Correct quant level ", (i + 1), " received: ", quantLevels[i]);
        end

    endfunction

    function automatic logic [15:0] ip_header_chksum_calc (
        input ipHeaderType ipHeader);

        logic [16:0] sum     = '0;
        logic [15:0] onesSum = '0;

        for (int i = 0; i < ($bits(ipHeader))/16; i++) begin
            sum = sum + ipHeader[$bits(ipHeader)-1:$bits(ipHeader)-16];
            onesSum = (sum[15:0] + sum[16]);
            ipHeader = ipHeader << 16;
        end

        ip_header_chksum_calc = ~onesSum;

    endfunction
endpackage