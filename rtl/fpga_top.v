`timescale 1ns/1ps
//==============================================================================
// fpga_top.v : board wrapper for Cyclone V (DE1-SoC / DE10-Standard style pins)
//   CLOCK_50 : 50 MHz board clock
//   KEY[0]   : reset (push button, active LOW on the board)
//   SW[9]    : speed select  0 = slow (~1.5 Hz clock, you can watch it run)
//                            1 = fast (CLOCK_50 / 4 = 12.5 MHz)
//   SW[0]    : display select 0 = LEDR shows x10 (a0), 1 = LEDR shows PC[11:2]
//   LEDR     : 10 red LEDs
//   This file is NOT used in simulation - only core_top is.
//==============================================================================
module fpga_top (
    input         CLOCK_50,
    input  [3:0]  KEY,
    input  [9:0]  SW,
    output [9:0]  LEDR
);
    // ---- reset: KEY is active low, core reset is active high ----
    wire reset = ~KEY[0];

    // ---- clock divider (counter bits used as clocks; Quartus puts them on global clocks) ----
    reg [25:0] cnt = 26'd0;
    always @(posedge CLOCK_50) cnt <= cnt + 26'd1;

    wire clk_slow = cnt[24];        // 50 MHz / 2^25 = ~1.5 Hz (one instruction per cycle)
    wire clk_fast = cnt[1];         // 50 MHz / 4   = 12.5 MHz
    wire core_clk = SW[9] ? clk_fast : clk_slow;

    wire [31:0] dbg_pc, dbg_x10;

    core_top #(
        .INIT_FILE ("../sw/compiled_hex/fpga_demo.hex"),   // relative to the quartus/ project folder
        .IMEM_DEPTH(256),
        .DMEM_DEPTH(256)
    ) u_core (
        .clk    (core_clk),
        .reset  (reset),
        .dbg_pc (dbg_pc),
        .dbg_x10(dbg_x10)
    );

    assign LEDR = SW[0] ? dbg_pc[11:2] : dbg_x10[9:0];
endmodule
