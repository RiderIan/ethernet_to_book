`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev: Ian Rider
// Purpose: Simple flip-flop based synchronizer of variable width and depth
//////////////////////////////////////////////////////////////////////////////////

module pipe #(
    parameter int   DEPTH     = 2,
    parameter int   WIDTH     = 1,
    parameter logic ALLOW_SRL = 1'b1)(

    input     logic             rstIn,
    input     logic             clkIn,
    input     logic [WIDTH-1:0] DIn,
    output    logic [WIDTH-1:0] QOut);

    localparam string SRL_EN = ALLOW_SRL ? "yes" : "no";

    initial begin
        if (DEPTH < 2)
            $fatal ("synchronizer_ff: DEPTH must be 2 or greater");
        if (WIDTH < 1)
            $fatal ("synchronizer_ff: WIDTH must be creater than zero");
    end

    `ifdef ALLOW_SRL
        (* shreg_extract = "yes" *)
    `else
        (* shreg_extract = "no" *)
    `endif
    logic [WIDTH-1:0] regsR [0:DEPTH-1];

    always_ff @(posedge clkIn) begin : pipe
        if (rstIn) begin
            regsR <= '{default:'0};
        end else begin
            regsR[0] <= DIn;
            for (int i = 1; i < DEPTH; i++) begin
                regsR[i] <= regsR[i-1];
            end
        end
    end

    assign QOut = regsR[DEPTH-1];

endmodule