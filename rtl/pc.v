`timescale 1ns/1ps
//==============================================================================
// pc.v : Program Counter. 32-bit register with asynchronous active-high reset.
//==============================================================================
module pc (
    input             clk,
    input             reset,      // active high, resets PC to 0
    input      [31:0] pc_next,
    output reg [31:0] pc_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) pc_out <= 32'h0000_0000;
        else       pc_out <= pc_next;
    end
endmodule
