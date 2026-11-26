`timescale 1ns/1ps
//==============================================================================
// instr_mem.v : Instruction memory (ROM), asynchronous read, word addressed.
// Loaded from a hex file (one 32-bit word per line) with $readmemh.
// Unused locations are filled with NOP (addi x0,x0,0 = 0x00000013).
//==============================================================================
module instr_mem #(
    parameter DEPTH     = 256,                              // words
    parameter INIT_FILE = "sw/compiled_hex/test_loop.hex"
) (
    input  [31:0] addr,          // byte address (PC)
    output [31:0] instr
);
    localparam AW = $clog2(DEPTH);

    reg [31:0] mem [0:DEPTH-1];

    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1) mem[i] = 32'h0000_0013;   // NOP
        $readmemh(INIT_FILE, mem);
    end

    assign instr = mem[addr[AW+1:2]];    // drop the 2 LSBs: instructions are 4 bytes
endmodule
