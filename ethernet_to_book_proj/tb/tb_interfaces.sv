`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev: Ian Rider
// Purpose: Re-use interfaces
//////////////////////////////////////////////////////////////////////////////////

// RGMII RX interface as seen by the PHY
interface rgmii_rx_if(input clk);
    logic       ctrl;
    logic [7:0] data;

    task automatic reset();
        ctrl = 1'b0;
        data = 8'h00;
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
    logic       packetLost;

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

interface itch_add_output_if(input clk);
    logic        valid;
    logic [15:0] locate;
    logic [63:0] refNum;
    logic        buySell;
    logic [31:0] shares;
    logic [31:0] price;

    task automatic reset();
        valid    = '0;
        locate   = '0;
        refNum   = '0;
        buySell  = '0;
        shares   = '0;
        price    = '0;
    endtask
endinterface

interface itch_del_output_if(input clk);
    logic        valid;
    logic [15:0] locate;
    logic [63:0] refNum;

    task automatic reset();
        valid    = '0;
        locate   = '0;
        refNum   = '0;
    endtask
endinterface

interface itch_exec_output_if(input clk);
    logic        valid;
    logic [15:0] locate;
    logic [63:0] refNum;

    task automatic reset();
        valid    = '0;
        locate   = '0;
        refNum   = '0;
    endtask
endinterface