`timescale 1ns/1ps
//==============================================================================
// data_mem.v : Data memory with byte / halfword / word access (little endian)
//   funct3 : 000 LB/SB, 001 LH/SH, 010 LW/SW, 100 LBU, 101 LHU
//   Write is synchronous (byte enables), read is asynchronous.
//   Addresses are assumed naturally aligned (misaligned access is not handled).
//==============================================================================
module data_mem #(
    parameter DEPTH = 256          // words (256 words = 1 KB)
) (
    input             clk,
    input             mem_write,
    input      [2:0]  funct3,
    input      [31:0] addr,
    input      [31:0] wdata,
    output reg [31:0] rdata
);
    localparam AW = $clog2(DEPTH);

    reg [31:0] mem [0:DEPTH-1];

    wire [AW-1:0] idx = addr[AW+1:2];
    wire [1:0]    off = addr[1:0];

    // ---------------- write path ----------------
    reg [3:0]  be;
    reg [31:0] wdata_s;
    always @(*) begin
        be      = 4'b0000;
        wdata_s = wdata;
        case (funct3[1:0])
            2'b00:   begin be = 4'b0001 << off;                       wdata_s = {4{wdata[7:0]}};  end // SB
            2'b01:   begin be = off[1] ? 4'b1100 : 4'b0011;           wdata_s = {2{wdata[15:0]}}; end // SH
            2'b10:   begin be = 4'b1111;                              wdata_s = wdata;            end // SW
            default: begin be = 4'b0000;                              wdata_s = wdata;            end
        endcase
    end

    always @(posedge clk) begin
        if (mem_write) begin
            if (be[0]) mem[idx][7:0]   <= wdata_s[7:0];
            if (be[1]) mem[idx][15:8]  <= wdata_s[15:8];
            if (be[2]) mem[idx][23:16] <= wdata_s[23:16];
            if (be[3]) mem[idx][31:24] <= wdata_s[31:24];
        end
    end

    // ---------------- read path ----------------
    wire [31:0] word  = mem[idx];
    wire [7:0]  byte_ = word >> (8 * off);
    wire [15:0] half  = off[1] ? word[31:16] : word[15:0];

    always @(*) begin
        rdata = word;
        case (funct3)
            3'b000:  rdata = {{24{byte_[7]}},  byte_};   // LB
            3'b001:  rdata = {{16{half[15]}},  half};    // LH
            3'b010:  rdata = word;                       // LW
            3'b100:  rdata = {24'h0, byte_};             // LBU
            3'b101:  rdata = {16'h0, half};              // LHU
            default: rdata = word;
        endcase
    end

    integer i;
    // synthesis translate_off
    initial for (i = 0; i < DEPTH; i = i + 1) mem[i] = 32'h0;
    // synthesis translate_on
endmodule
