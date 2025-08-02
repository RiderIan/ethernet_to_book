`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev: Ian Rider
// Purpose: Parser ethernet and MoldUdp64 headers, pass itch data straight through
//////////////////////////////////////////////////////////////////////////////////
import tb_pkg::*;

module eth_udp_parser (
    input  logic       rstIn,
    input  logic       clkIn,

    // CDC interface
    input  logic [7:0] dataIn,
    input  logic       dataValidIn,
    input  logic       dataErrIn,
   
    output logic [7:0] itchDataOut,
    output logic       itchDataValidOut);

    // Header byte offsets
    const int unsigned ETH_HDR_DONE  = 14;
    const int unsigned IP_HDR_DONE   = 34;
    const int unsigned UDP_HDR_DONE  = 42;
    const int unsigned MOLD_HDR_DONE = 62;

    const logic [47:0] DEVICE_MAC        = 48'hA846D2197E2B;
    const logic [15:0] IP_V4_TYPE        =  8'h0800;
    const logic [31:0] NYSE_DST_IP       = 32'hE0000000; // NYSE integrated feed multicast dest
    const logic [15:0] NYSE_UDP_SRC_PORT = 16'h3E80;
    const logic [15:0] UDP_DEST_PORT     = 16'h2710;

    int unsigned byteCntR;
    // TODO: Find a way to clear all of these check bits after a frame has completed
    logic dataLastDetR, dstMacCheckR, ipV4CheckR, nyseIpCheck, udpSrcCheckR, udpDstCheckR, passItchR;

    ////////////////////////////////////////////
    // Ethernet header capture
    ////////////////////////////////////////////
    ethHeaderType ethHeaderR;

    always_ff @(posedge clkIn) begin : eth_header_capture
        if (dataValidIn & (byteCntR < ETH_HDR_DONE))
            ethHeaderR <= (ethHeaderR << 8) | dataIn;  
    end

    always_ff @(posedge clkIn) begin : eth_header_check
        if (rstIn) begin
            dstMacCheckR <= 1'b0;
            ipV4CheckR   <= 1'b0;
        end else begin
            if (byteCntR == (ETH_HDR_DONE + 1)) begin
                if (ethHeaderR.dstMac == DEVICE_MAC)
                    dstMacCheckR <= 1'b1;
                
                if (ethHeaderR.ethType == IP_V4_TYPE)
                    ipV4CheckR <= 1'b1;
            end
        end
    end

    ////////////////////////////////////////////
    // IPv4 header capture
    ////////////////////////////////////////////
    ipHeaderType ipHeaderR;

    always_ff @(posedge clkIn) begin : ip_header_capture
        if (dataValidIn & (byteCntR < IP_HDR_DONE))
            ipHeaderR <= (ipHeaderR << 8) | dataIn;  
    end

    always_ff @(posedge clkIn) begin : ip_header_check
        if (rstIn) begin
            nyseIpCheck <= 1'b0;
        end else begin
            if (byteCntR == (IP_HDR_DONE + 1)) begin
                if (ipHeaderR.dstIp == NYSE_DST_IP)
                    nyseIpCheck <= 1'b1;
            end
        end
    end

    // TODO: Check IP checksum?

    ////////////////////////////////////////////
    // UDP header capture
    ////////////////////////////////////////////
    udpHeaderType udpHeaderR;

    always_ff @(posedge clkIn) begin : udp_header_capture
        if (dataValidIn & (byteCntR < UDP_HDR_DONE))
            udpHeaderR <= (udpHeaderR << 8) | dataIn; 
    end

    always_ff @(posedge clkIn) begin : udp_header_check
        if (rstIn) begin
            udpSrcCheckR <= 1'b0;
            udpDstCheckR <= 1'b0;
        end else begin
            if (byteCntR == (UDP_HDR_DONE + 1)) begin
                if (udpHeaderR.srcPort == NYSE_UDP_SRC_PORT)
                    udpSrcCheckR <= 1'b1;
                
                if (udpHeaderR.dstPort == UDP_DEST_PORT)
                    udpDstCheckR <= 1'b1;
            end
        end
    end

    // TODO: UDP checksum?

    ////////////////////////////////////////////
    // MoldUDP64 header capture
    ////////////////////////////////////////////
    moldHeaderType moldHeaderR;

    always_ff @(posedge clkIn) begin : mold_header_capture
        if (dataValidIn & (byteCntR < MOLD_HDR_DONE))
            moldHeaderR <= (moldHeaderR << 8) | dataIn; 
    end

    // TODO: implement sessionID/sequence number checker
    always_ff @(posedge clkIn) begin : mold_header_check
        if (rstIn) begin

        end else begin

        end
    end

    ////////////////////////////////////////////
    // ITCH passthrough control TODO: Drive passItchR here
    ////////////////////////////////////////////
    assign itchDataOut      = dataIn;
    assign itchDataValidOut = (dataValidIn & passItchR);

    ////////////////////////////////////////////
    // Byte cnt of current frame
    ////////////////////////////////////////////
    always_ff @(posedge clkIn) begin
        if (rstIn) begin
            byteCntR <= 0;
        end else begin
            if (dataValidIn) begin
                if (dataLastDetR||dataErrIn)
                    byteCntR <= 0;
                else
                    byteCntR <= byteCntR + 1;
            end
        end
    end


endmodule