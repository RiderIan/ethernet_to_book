`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev: Ian Rider
// Purpose: Re-use interfaces
//////////////////////////////////////////////////////////////////////////////////

// RGMII RX interface as seen by the PHY
interface rgmii_rx_if(input rxClk);
    logic       rxCtrl;
    logic [7:0] rxData;

    task automatic reset();
        rxCtrl = 1'b0;
        rxData = 8'h00;
    endtask
endinterface

interface eth_udp_if(input clk);
    logic [7:0] data;
    logic       dataValid;
    logic       dataErr;

    task automatic reset();
        dataValid = 1'b0;
        dataErr   = 1'b0;
        data      = 8'h00;
    endtask;
endinterface

interface eth_udp_output_if(input clk);
    logic [7:0] data;
    logic       dataValid;

    task automatic reset();
        dataValid = 1'b0;
        data      = 8'h00;
    endtask;
endinterface

// Output interface of RGMII module as seen by upstream logic
interface rgmii_rx_output_if(input rxClkLcl);
    logic       rxDataValid;
    logic       rxDataLast;
    logic [7:0] rxData;

    task automatic reset();
        rxDataValid = 1'b0;
        rxDataLast  = 1'b0;
        rxData      = 8'h00;
    endtask
endinterface