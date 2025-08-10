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
    output logic [7:0] itchDataOut);

    // Header byte offsets
    const logic [10:0] ETH_HDR_DONE  = 11'd14;
    const logic [10:0] IP_HDR_DONE   = 11'd34;
    const logic [10:0] UDP_HDR_DONE  = 11'd42;
    const logic [10:0] MOLD_HDR_DONE = 11'd64;

    logic [10:0] byteCntR;
    logic dstMacCheckR, ipV4CheckR, ipV6CheckR;
    logic ipVerCheckR, protocolCheckR, nyseIpCheckR;
    logic udpSrcCheckR, udpDstCheckR, passItchR;
    logic moldSeqValidR;
    logic ipV4FrameDoneR, ipV6FrameDoneR, endOfFrameDetR;

    (* shreg_extract = "no" *) logic [15:0] udpLenR, udpLenRR, udpLenRRR, ipV6LenR, ipV6LenRR, ipV6LenRRR;
    (* shreg_extract = "no" *) logic [15:0] sessIdR, sessIdRR, sessIdRRR, seqNumR, seqNumRR, seqNumRRR;

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
    // IPv4 header capture
    ////////////////////////////////////////////
    // TODO: Check IP checksum?
    ipHeaderType ipHeaderR;

    always_ff @(posedge clkIn) begin : ip_header_capture
        if (dataValidIn & (byteCntR < IP_HDR_DONE))
            ipHeaderR <= (ipHeaderR << 8) | dataIn;  
    end

    always_ff @(posedge clkIn) begin : ip_header_check
        if (rstIn) begin
            ipVerCheckR    <= 1'b0;
            nyseIpCheckR   <= 1'b0;
            protocolCheckR <= 1'b0;
        end else begin
            if (byteCntR == (IP_HDR_DONE + 1)) begin
                if (ipHeaderR.ver == IP_V4_TYPE)
                    ipVerCheckR    <= 1'b1;
                if (ipHeaderR.dstIp == NYSE_DST_IP)
                    nyseIpCheckR   <= 1'b1;
                if (ipHeaderR.protocol == PROTOCOL)
                    protocolCheckR <= 1'b1;
            end else if (endOfFrameDetR) begin
                ipVerCheckR    <= 1'b0;
                nyseIpCheckR   <= 1'b0;
                protocolCheckR <= 1'b0;
            end
        end
    end

    // not verified
    // IPv6 length is at same offset of ID of IPv4
    always_ff @(posedge clkIn) begin : ip_v6_len_pipe
        ipV6LenR   <= ipHeaderR.id;
        ipV6LenRR  <= ipV6LenR + ETH_HDR_DONE;
        ipV6LenRRR <= (byteCntR > (IP_HDR_DONE + 1)) ? ipV6LenRR : '1;

        if (byteCntR >= (ipV6LenRRR[10:0] - 1)) begin
            ipV6FrameDoneR <= 1'b1;
        end else begin
            ipV6FrameDoneR <= 1'b0;
        end
    end

    ////////////////////////////////////////////
    // UDP header capture
    ////////////////////////////////////////////
    // TODO: UDP checksum?
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

    // Reduces combo logic time on EOF comparison to pass timing
    // Latency doesn't matter becuase length isn't checked until udp header is complete
    always_ff @(posedge clkIn) begin : udp_len_pipe
        udpLenR   <= udpHeaderR.len;
        udpLenRR  <= udpLenR + IP_HDR_DONE;
        udpLenRRR <= (byteCntR > (UDP_HDR_DONE + 1)) ? udpLenRR : '1;

        if (byteCntR >= (udpLenRRR[10:0] - 1)) begin
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
    // MoldUDP64 header capture
    ////////////////////////////////////////////
    // TODO: implement sessionID/sequence number checker
    moldHeaderType moldHeaderR;

    always_ff @(posedge clkIn) begin : mold_header_capture
        if (dataValidIn & (byteCntR < MOLD_HDR_DONE))
            moldHeaderR <= (moldHeaderR << 8) | dataIn; 
    end

    always_ff @(posedge clkIn) begin : sess_seq_pipe
        sessIdR   <= moldHeaderR.sessId;
        sessIdRR  <= sessIdR;
        sessIdRRR <= sessIdRR;

        seqNumR   <= moldHeaderR.seqNum;
        seqNumRR  <= seqNumR;
        seqNumRRR <= seqNumRRR;
        
    end

    always_ff @(posedge clkIn) begin : mold_header_check
        if (rstIn) begin
            moldSeqValidR <= 1'b0;
        end else begin
            if (byteCntR == (MOLD_HDR_DONE - 1)) begin
                moldSeqValidR <= 1'b1;                    // not implemented, just stand in for first round sim
            end else if (endOfFrameDetR) begin
                moldSeqValidR <= 1'b0;
            end
        end
    end

    ////////////////////////////////////////////
    // ITCH passthrough control
    ////////////////////////////////////////////
    assign passItchR        = dstMacCheckR & ipV4CheckR & protocolCheckR & udpSrcCheckR & udpDstCheckR & moldSeqValidR;
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
                byteCntR <= byteCntR + 1;
            end else if (endOfFrameDetR) begin
                byteCntR <= 0;
            end
        end
    end


endmodule