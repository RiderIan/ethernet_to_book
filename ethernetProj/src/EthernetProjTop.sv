`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Ian Rider
// 
//////////////////////////////////////////////////////////////////////////////////


module EthernetProjTop(
    output logic       mcmm0LockedOut, // simulation only
    output logic       clk125Out,      // simulation only
    // RTL_SYNTHESIS ON
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
    logic mcmm0locked; logic mcmm1locked;

    /////////////////////////////////
    // Clocks and Resets
    /////////////////////////////////
    BUFG BUFG_inst (
        .I(clkIn),
        .O(clkLcl));

    // Synchronize de-assertion of reset
    always @(posedge clkLcl or posedge rstIn) begin
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
        .locked(mcmm0locked),         // Indicated ouput clocks are locked/valid
        .clk_in1(clkIn));             // 100Mhz reference clock

    rx_clk_shift mmcm1_inst (
        .clk_out1(clk125Rx),          // 125Mhz clock delayed for mgii rx logic
        .reset(rstLcl),               // reset
        .locked(mcmm1locked),         // Indicated ouput clock is locked/valid
        .clk_in1(rxClkIn));           // 125 MHz reference clock provided by PHY

    // Ports for sim only
    assign mcmm0LockedOut = mcmm0locked;
    assign clk125Out      = clk125;


endmodule
