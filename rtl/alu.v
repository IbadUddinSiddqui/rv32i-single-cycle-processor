`timescale 1ns/1ps
//==============================================================================
// alu.v : Arithmetic Logic Unit (combinational, no latches)
//==============================================================================
module alu (
    input      [31:0] a,
    input      [31:0] b,
    input      [3:0]  alu_ctrl,
    output reg [31:0] result
);
    localparam ALU_ADD   = 4'd0;
    localparam ALU_SUB   = 4'd1;
    localparam ALU_SLL   = 4'd2;
    localparam ALU_SLT   = 4'd3;
    localparam ALU_SLTU  = 4'd4;
    localparam ALU_XOR   = 4'd5;
    localparam ALU_SRL   = 4'd6;
    localparam ALU_SRA   = 4'd7;
    localparam ALU_OR    = 4'd8;
    localparam ALU_AND   = 4'd9;
    localparam ALU_PASSB = 4'd10;     // used by LUI

    wire [4:0] shamt = b[4:0];

    always @(*) begin
        result = 32'h0000_0000;       // default value => no inferred latch
        case (alu_ctrl)
            ALU_ADD:   result = a + b;
            ALU_SUB:   result = a - b;
            ALU_SLL:   result = a << shamt;
            ALU_SLT:   result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            ALU_SLTU:  result = (a < b) ? 32'd1 : 32'd0;
            ALU_XOR:   result = a ^ b;
            ALU_SRL:   result = a >> shamt;
            ALU_SRA:   result = $signed(a) >>> shamt;
            ALU_OR:    result = a | b;
            ALU_AND:   result = a & b;
            ALU_PASSB: result = b;
            default:   result = 32'h0000_0000;
        endcase
    end
endmodule
