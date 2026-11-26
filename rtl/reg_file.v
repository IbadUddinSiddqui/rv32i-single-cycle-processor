`timescale 1ns/1ps
//==============================================================================
// reg_file.v : 32 x 32-bit register file
//   - 2 asynchronous read ports, 1 synchronous write port
//   - x0 is hard-wired to zero (never written, always reads 0)
//   - dbg_x10 : extra read of register a0 (x10) used for LEDs/debug
//==============================================================================
module reg_file (
    input         clk,
    input         we,
    input  [4:0]  rs1,
    input  [4:0]  rs2,
    input  [4:0]  rd,
    input  [31:0] wd,
    output [31:0] rd1,
    output [31:0] rd2,
    output [31:0] dbg_x10
);
    reg [31:0] regs [0:31];

    integer i;
    // synthesis translate_off
    initial for (i = 0; i < 32; i = i + 1) regs[i] = 32'h0;   // avoid X in simulation
    // synthesis translate_on

    always @(posedge clk) begin
        if (we && (rd != 5'd0)) regs[rd] <= wd;
    end

    assign rd1     = (rs1 == 5'd0) ? 32'h0 : regs[rs1];
    assign rd2     = (rs2 == 5'd0) ? 32'h0 : regs[rs2];
    assign dbg_x10 = regs[10];
endmodule
