`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev: Ian Rider
// Purpose: Common stimulus for all tests
//////////////////////////////////////////////////////////////////////////////////
`include "tb_pkg.sv"
import tb_pkg::*;

module tb_env (
    output logic rstOut,
    output logic clk100Out,
    output logic rxClkOut);

    // Clock gen
    const int CLK_100_MHX_PERIOD = 10;
    const int CLK_125_MHZ_PERIOD = 8;

    always #(CLK_100_MHX_PERIOD/2) clk100Out = ~clk100Out;
    always #(CLK_125_MHZ_PERIOD/2) rxClkOut  = ~rxClkOut;

    // Initial reset assert/de-assert
    initial begin
        clk100Out = 1'b0;
        rxClkOut  = 1'b0;
        apply_reset(rstOut);
    end

endmodule