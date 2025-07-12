`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Dev: Ian Rider
// Purpose: Re-use synthesizable functions
//////////////////////////////////////////////////////////////////////////////////

package pkg;
    virtual class grey_code #(parameter WIDTH=8);
        static function automatic logic bin_to_grey (input logic [WIDTH-1:0] bin);
            bin_to_grey = bin ^ (bin >> 1);
        endfunction

        static function automatic logic [WIDTH-1:0] grey_to_bin(input logic [WIDTH-1:0] grey);
            logic [WIDTH-1:0] bin;
            integer i;

            bin[WIDTH-1:0] = grey[WIDTH-1:0];  // MSB is the same
            for (i = WIDTH-2; i >= 0; i--) begin
                bin[i] = bin[i+1] ^ grey[i];
            end
            grey_to_bin = bin; 
        endfunction
    endclass
endpackage