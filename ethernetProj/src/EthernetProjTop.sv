`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Ian Rider
// 
//////////////////////////////////////////////////////////////////////////////////
`include "RGMII.sv"

module EthernetProjTop (
    output logic       mmcm0LockedOut, // simulation only
    output logic       mmcm1LockedOut, // simulation only
    output logic       txClkFabricOut, // simulation only
    output logic       rxClkFabricOut, // simulation only

    input    logic     clkIn,
    input    logic     rstIn,
    //inout  logic       mdioBi,
    //output logic       mdClkOut,

    input  logic [3:0] rxDataIn,    
    input  logic       rxCtrlIn,
    input  logic       rxClkIn,

    output logic [3:0] txDataOut,
    output logic       txCtrlOut,
    output logic       txClkOut,

    input  logic       intBIn,
    output logic       phyRstBOut);

    // Signals
    logic clkLcl;
    logic rstLcl;
    logic clk125;
    logic clk125Rx;
    logic clk250;
    logic mmcm0Locked; 
    logic mmcm1Locked;

    /////////////////////////////////
    // Clocks and Resets
    /////////////////////////////////
    BUFG BUFG_inst (
        .I(clkIn),
        .O(clkLcl));

    // Synchronize de-assertion of reset
    always @(posedge clkLcl or posedge rstIn) begin : reset_deassert_sync_inst
        if (rstIn)
            rstLcl <= 1'b1;
        else
            rstLcl <= 1'b0;
    end

    system_clocks_gen mmcm0_inst (
        .clk_out1(clk125),            // Local 125Mhz for RGMII
        .clk_out2(txClkOut),          // 125Mhz clock delayed by 1.5ns for PHY tx clock
        .clk_out3(clk250),            // 250Mhz system clock for parsers/book builder
        .reset(rstLcl),               // reset
        .locked(mmcm0Locked),         // Indicated ouput clocks are locked/valid
        .clk_in1(clkIn));             // 100Mhz reference clock

    rx_clk_shift mmcm1_inst (
        .clk_out1(clk125Rx),          // 125Mhz clock delayed for mgii rx logic
        .reset(rstLcl),               // reset
        .locked(mmcm1Locked),         // Indicated ouput clock is locked/valid
        .clk_in1(rxClkIn));           // 125 MHz reference clock provided by PHY

    /////////////////////////////////
    // RGMII
    /////////////////////////////////
    RGMII mac_inst (
        .rstIn(rstLcl),
        .clk125In(clk125),
        .rxClkIn(clk125Rx),
        .rxCtrlIn(rxCtrlIn),
        .intBIn(intBIn),
        .mmcm0LockedIn(mmcm0Locked),
        .mmcm1LockedIn(mmcm1Locked),

        .txDataOut(txDataOut),
        .txCtrlOut(txCtrlOut),
        .phyRstBOut(phyRstBOut));

    // Ports for sim only
    assign mmcm0LockedOut = mmcm0Locked;
    assign mmcm1LockedOut = mmcm1Locked;
    assign txClkFabricOut = clk125;
    assign rxClkFabricOut = clk125Rx;

endmodule
