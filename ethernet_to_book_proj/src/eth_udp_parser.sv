`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev: Ian Rider
// Purpose: Parses all headers (eth, ip, udp, moldUdp64).
//          ITCH header and data is passed through with zero clock latency
//////////////////////////////////////////////////////////////////////////////////
import pkg::*;

module eth_udp_parser (
    input  logic       rstIn,
    input  logic       clkIn,

    // CDC interface
    input  logic [7:0] dataIn,
    input  logic       dataValidIn,
    input  logic       dataErrIn,

    output logic       itchDataValidOut,
    output logic [7:0] itchDataOut,
    output logic       packetLostOut);

    // Header byte offsets
    const logic [10:0] ETH_HDR_DONE  = 11'd14;
    const logic [10:0] IP_HDR_DONE   = 11'd34;
    const logic [10:0] UDP_HDR_DONE  = 11'd42;
    const logic [10:0] SESS_SEQ_DONE = 11'd60;
    const logic [10:0] MOLD_HDR_DONE = 11'd64;

    logic [10:0] byteCntR;
    logic [ 7:0] dataR;
    logic [16:0] ipChkSumAccumR;
    logic dstMacCheckR, ipV4CheckR, ipV6CheckR;
    logic ipVerCheckR, protocolCheckR, nyseIpCheckR, ipChkSumPassR, ipPackTwoBytesR, ipTogglePulseR;
    logic udpSrcCheckR, udpDstCheckR, passItch;
    logic moldDoneR;
    logic ipV4FrameDoneR, ipV6FrameDoneR, endOfFrameDetR;

    logic [31:0] sessionIdsR[1:32];
    logic [31:0] currSeqNumR;

    (* shreg_extract = "no" *) logic [15:0] udpLenR, udpLenRR, udpLenRRR;
    (* shreg_extract = "no" *) logic [15:0] ipV6LenR, ipV6LenRR, ipV6LenRRR, onesCompSumR;

    ////////////////////////////////////////////
    // Ethernet header
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
            ipV6CheckR   <= 1'b0;
        end else begin
            if (byteCntR == (ETH_HDR_DONE + 1)) begin
                if (ethHeaderR.dstMac == DEVICE_MAC)
                    dstMacCheckR <= 1'b1;

                if (ethHeaderR.ethType == ETH_IP_V4_TYPE)
                    ipV4CheckR <= 1'b1;

                // Frame igored if IPv6 but end of frame still needs to be detected
                if (ethHeaderR.ethType == ETH_IP_V6_TYPE)
                    ipV6CheckR <= 1'b1;

            end else if (endOfFrameDetR) begin
                dstMacCheckR <= 1'b0;
                ipV4CheckR   <= 1'b0;
                ipV6CheckR   <= 1'b0;
            end
        end
    end

    ////////////////////////////////////////////
    // IPv4 header
    ////////////////////////////////////////////
    ipHeaderType ipHeaderR;

    always_ff @(posedge clkIn) begin : ip_header_capture
        if (rstIn) begin
            ipHeaderR       <= '0;
            ipPackTwoBytesR <= '0;
            ipTogglePulseR  <= '0;
            ipChkSumAccumR  <= '0;
            onesCompSumR    <= '0;
            dataR           <= '0;
        end else begin
            // Capture
            ipPackTwoBytesR <= 1'b0;
            if (dataValidIn & (byteCntR < IP_HDR_DONE)) begin
                ipHeaderR       <= (ipHeaderR << 8) | dataIn;
                dataR           <= dataIn;
                ipTogglePulseR  <= ~ipTogglePulseR;
                if (ipTogglePulseR)
                    ipPackTwoBytesR <= 1'b1;
            end else if (endOfFrameDetR) begin
                dataR           <= '0;
            end

            // Checksum
            if (ipPackTwoBytesR & (byteCntR < IP_HDR_DONE) & (byteCntR >= ETH_HDR_DONE)) begin
                ipChkSumAccumR <= ipChkSumAccumR + {dataR, dataIn};
                onesCompSumR   <= ~(ipChkSumAccumR[15:0] + ipChkSumAccumR[16]);
            end else if (endOfFrameDetR) begin
                ipChkSumAccumR <= '0;
                onesCompSumR   <= '0;
            end
        end
    end

    always_ff @(posedge clkIn) begin : ip_header_check
        if (rstIn) begin
            ipVerCheckR    <= 1'b0;
            nyseIpCheckR   <= 1'b0;
            protocolCheckR <= 1'b0;
            ipChkSumPassR  <= 1'b0;
        end else begin
            if (byteCntR == (IP_HDR_DONE + 1)) begin
                if (ipHeaderR.ver == IP_V4_TYPE)
                    ipVerCheckR    <= 1'b1;
                if (ipHeaderR.dstIp == NYSE_DST_IP)
                    nyseIpCheckR   <= 1'b1;
                if (ipHeaderR.protocol == PROTOCOL)
                    protocolCheckR <= 1'b1;
                if (onesCompSumR == 17'h00)
                    ipChkSumPassR  <= 1'b1;

            end else if (endOfFrameDetR) begin
                ipVerCheckR    <= 1'b0;
                nyseIpCheckR   <= 1'b0;
                protocolCheckR <= 1'b0;
                ipChkSumPassR  <= 1'b0;
            end
        end
    end

    ////////////////////////////////////////////
    // UDP header
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
            end else if (endOfFrameDetR) begin
                udpSrcCheckR <= 1'b0;
                udpDstCheckR <= 1'b0;
            end
        end
    end

    ////////////////////////////////////////////
    // MoldUDP64 header
    ////////////////////////////////////////////
    moldHeaderType moldHeaderR;
    (* shreg_extract = "no" *) logic  [143:0] sessSeqR;
    (* shreg_extract = "no" *) logic  [ 79:0] sessIdR;
    (* shreg_extract = "no" *) logic  [ 63:0] seqNumR;
    logic          sessSeqDoneR;

    always_ff @(posedge clkIn) begin : mold_header_capture
        if (dataValidIn & (byteCntR < MOLD_HDR_DONE))
            moldHeaderR <= (moldHeaderR << 8) | dataIn;
    end

    // Need to be able to check sessId/seqNum before end of moldHeader to not induce any extra latency
    always_ff @(posedge clkIn) begin : sess_id_seq_num_capture
        if (dataValidIn & (byteCntR < SESS_SEQ_DONE))
            sessSeqR <= (sessSeqR << 8) | dataIn;
    end

    always_ff @(posedge clkIn) begin : sess_seq_pipe
        sessIdR <= sessSeqR[143:64];
        seqNumR <= sessSeqR[63:0];
    end

    always_ff @(posedge clkIn) begin : mold_header_check
        if (rstIn) begin
            packetLostOut <= 1'b0;
            sessSeqDoneR  <= 1'b0;
            currSeqNumR   <=   '0;
        end else begin
            packetLostOut <= 1'b0;
            sessSeqDoneR  <= 1'b0;
            currSeqNumR   <= sessionIdsR[sessIdR];

            if (byteCntR == (SESS_SEQ_DONE + 1))
                sessSeqDoneR <= 1'b1;

            if (sessSeqDoneR) begin
                sessionIdsR[sessIdR] <= seqNumR;

                if (seqNumR != currSeqNumR)
                    packetLostOut <= 1'b1;
            end
        end
    end

    always_ff @(posedge clkIn) begin : mold_end_detect
        if (rstIn) begin
            moldDoneR <= 1'b0;
        end else begin
            if (byteCntR == (MOLD_HDR_DONE)) begin
                moldDoneR <= 1'b1;
            end else if (endOfFrameDetR) begin
                moldDoneR <= 1'b0;
            end
        end
    end

    ////////////////////////////////////////////
    // End of frame detection
    ////////////////////////////////////////////

    // not verified
    // Handles end of frame detection incase of IPv6
    always_ff @(posedge clkIn) begin : ip_v6_len_pipe
        ipV6LenR   <= ipHeaderR.id;
        ipV6LenRR  <= ipV6LenR + ETH_HDR_DONE;
        ipV6LenRRR <= (byteCntR > (IP_HDR_DONE + 1)) ? ipV6LenRR : '1;

        if (byteCntR >= ipV6LenRRR[10:0]) begin
            ipV6FrameDoneR <= 1'b1;
        end else begin
            ipV6FrameDoneR <= 1'b0;
        end
    end

    // Reduces combo logic time on EOF comparison to pass timing
    // Latency doesn't matter becuase length isn't checked until udp header is complete
    always_ff @(posedge clkIn) begin : udp_len_pipe
        udpLenR   <= udpHeaderR.len;
        udpLenRR  <= udpLenR + IP_HDR_DONE;
        udpLenRRR <= (byteCntR > (UDP_HDR_DONE + 1)) ? udpLenRR : '1;

        if (byteCntR > udpLenRRR[10:0]) begin
            ipV4FrameDoneR <= 1'b1;
        end else begin
            ipV4FrameDoneR <= 1'b0;
        end
    end

    always_ff @(posedge clkIn) begin : end_of_frame_det
        if (rstIn) begin
            endOfFrameDetR <= 1'b0;
        end else begin
            // Should this be XOR?
            if ((ipV4FrameDoneR & ipV4CheckR) | (ipV6FrameDoneR & ipV6CheckR)) begin
                endOfFrameDetR <= 1'b1;
            end else begin
                endOfFrameDetR <= 1'b0;
            end
        end
    end

    ////////////////////////////////////////////
    // ITCH passthrough control
    ////////////////////////////////////////////
    assign passItch        =  dstMacCheckR & ipV4CheckR   & protocolCheckR &
                              udpSrcCheckR & udpDstCheckR & ipVerCheckR    &
                              moldDoneR    & nyseIpCheckR & ipChkSumPassR;

    assign itchDataOut      = dataIn;
    assign itchDataValidOut = (dataValidIn & passItch);

    ////////////////////////////////////////////
    // Byte cnt of current frame
    ////////////////////////////////////////////
    always_ff @(posedge clkIn) begin
        if (rstIn) begin
            byteCntR <= 0;
        end else begin
            if (dataValidIn) begin
                byteCntR <= byteCntR + 1;
            end else if (endOfFrameDetR) begin
                byteCntR <= 0;
            end
        end
    end


endmodule