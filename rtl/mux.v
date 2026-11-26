`timescale 1ns/1ps
//==============================================================================
// mux.v : parameterised multiplexers used all over the datapath
//==============================================================================

// 2-to-1 multiplexer
module mux2 #(parameter WIDTH = 32) (
    input  [WIDTH-1:0] d0,
    input  [WIDTH-1:0] d1,
    input              sel,
    output [WIDTH-1:0] y
);
    assign y = sel ? d1 : d0;
endmodule

// 4-to-1 multiplexer (case + default => no latch)
module mux4 #(parameter WIDTH = 32) (
    input      [WIDTH-1:0] d0,
    input      [WIDTH-1:0] d1,
    input      [WIDTH-1:0] d2,
    input      [WIDTH-1:0] d3,
    input      [1:0]       sel,
    output reg [WIDTH-1:0] y
);
    always @(*) begin
        case (sel)
            2'b00:   y = d0;
            2'b01:   y = d1;
            2'b10:   y = d2;
            2'b11:   y = d3;
            default: y = {WIDTH{1'b0}};
        endcase
    end
endmodule
