`timescale 1ns/1ps
//==============================================================================
// tb_core.v : self-checking testbench for the whole processor.
// Loads each test program into the instruction memory, resets the core, runs it
// for a fixed number of cycles and compares registers with expected values.
// Run from the project root:  see README.md / run_sim.sh
//==============================================================================
module tb_core;
    reg clk = 0, reset = 1;
    wire [31:0] dbg_pc, dbg_x10;
    integer errors = 0, total_errors = 0, i;

    core_top dut (.clk(clk), .reset(reset), .dbg_pc(dbg_pc), .dbg_x10(dbg_x10));

    always #5 clk = ~clk;           // 100 MHz simulation clock

    // ---- load program, clear data memory, reset, run ----
    task run_test(input [8*40-1:0] file, input integer cycles);
        begin
            errors = 0;
            for (i = 0; i < 256; i = i + 1) dut.u_imem.mem[i] = 32'h0000_0013;
            $readmemh(file, dut.u_imem.mem);
            for (i = 0; i < 256; i = i + 1) dut.u_dmem.mem[i] = 32'h0;
            for (i = 0; i < 32;  i = i + 1) dut.u_rf.regs[i]  = 32'h0;
            reset = 1; @(negedge clk); @(negedge clk); reset = 0;
            repeat (cycles) @(negedge clk);
            $display("---- %0s : executed %0d cycles, PC = 0x%h ----", file, cycles, dbg_pc);
        end
    endtask

    task chk(input integer r, input [31:0] exp);
        reg [31:0] got;
        begin
            got = dut.u_rf.regs[r];
            if (got === exp) $display("  PASS x%0d = 0x%h", r, got);
            else begin $display("  FAIL x%0d = 0x%h, expected 0x%h", r, got, exp); errors = errors + 1; end
        end
    endtask

    // check one word of data memory directly (memory-update verification)
    task chkmem(input integer word, input [31:0] exp);
        reg [31:0] got;
        begin
            got = dut.u_dmem.mem[word];
            if (got === exp) $display("  PASS dmem[addr 0x%h] = 0x%h", word*4, got);
            else begin $display("  FAIL dmem[addr 0x%h] = 0x%h, expected 0x%h", word*4, got, exp); errors = errors + 1; end
        end
    endtask

    task summary(input [8*20-1:0] name);
        begin
            if (errors == 0) $display("==> %0s : PASSED\n", name);
            else $display("==> %0s : FAILED (%0d errors)\n", name, errors);
            total_errors = total_errors + errors;
        end
    endtask

    initial begin
        $dumpfile("tb/waves/tb_core.vcd");
        $dumpvars(0, tb_core);

        // ------------------------------------------------ ALU test
        run_test("sw/compiled_hex/test_alu.hex", 60);
        chk(1, 32'd5);          chk(2, 32'hFFFFFFFD);   chk(3, 32'd2);          chk(4, 32'd8);
        chk(5, 32'd5);          chk(6, 32'hFFFFFFFD);   chk(7, 32'hFFFFFFF8);   chk(8, 32'd1);
        chk(9, 32'd0);          chk(10, 32'd80);        chk(11, 32'd15);        chk(12, 32'hFFFFFFFF);
        chk(13, 32'd3);         chk(14, 32'd40);        chk(15, 32'h1FFFFFFF);  chk(16, 32'hFFFFFFFF);
        chk(17, 32'd1);         chk(18, 32'd1);         chk(19, 32'd250);       chk(20, 32'd117);
        chk(21, 32'd13);        chk(22, 32'h12345000);  chk(23, 32'h00001058);  chk(24, 32'h12345678);
        chk(25, 32'd0);         chk(0, 32'd0);
        summary("test_alu");

        // ------------------------------------------------ loop test
        run_test("sw/compiled_hex/test_loop.hex", 100);
        chk(10, 32'd55);  chk(11, 32'd11);  chk(13, 32'd0);  chk(14, 32'd20);
        summary("test_loop");

        // ------------------------------------------------ load/store test
        run_test("sw/compiled_hex/test_loadstore.hex", 40);
        chk(1,  32'h12345678);  chk(3,  32'h12345678);  chk(4,  32'h00000078);  chk(5,  32'h00000012);
        chk(6,  32'hFFFFFFFF);  chk(7,  32'hFFFFFFFF);  chk(8,  32'h000000FF);  chk(9,  32'h000000FF);
        chk(10, 32'hFFFFFFFE);  chk(11, 32'hFFFFFFFE);  chk(12, 32'h0000FFFE);  chk(13, 32'h5678FFFE);
        chk(14, 32'h00005678);  chk(15, 32'h00007800);
        chkmem(16, 32'h12345678);   // sw  x1,64
        chkmem(17, 32'h000000FF);   // sb  x6,68
        chkmem(18, 32'h5678FFFE);   // sh  x10,72 + sh x1,74
        chkmem(19, 32'h00007800);   // sb  x1,77
        summary("test_loadstore");

        // ------------------------------------------------ branch/jump test
        run_test("sw/compiled_hex/test_branch.hex", 50);
        chk(10, 32'd234);  chk(5, 32'd68);
        summary("test_branch");

        // ------------------------------------------------ system test (FENCE, FENCE.I, ECALL, EBREAK, CSR x6)
        run_test("sw/compiled_hex/test_system.hex", 120);
        chk(1,  32'h00000084);  // handler address
        chk(3,  32'h00000000);  chk(4,  32'h00000055);  chk(6,  32'h00000055);  chk(8,  32'h0000005F);
        chk(9,  32'h0000004E);  chk(10, 32'h0000004E);  chk(11, 32'h00000015);  chk(12, 32'h0000001F);
        chk(13, 32'h0000001C);  chk(14, 32'h00000007);                      // fences did not disturb execution
        chk(22, 32'd2);         chk(25, 32'd2);         chk(26, 32'h40000100);
        chk(28, 32'h0000006C);  chk(29, 32'd11);                            // mepc / mcause seen after ECALL
        chk(15, 32'd3);         chk(16, 32'h0000007C);                      // last trap = EBREAK, returned to 0x7C
        chk(17, 32'd2);         chk(19, 32'd14);        chk(18, 32'd99);    // 2 traps, causes 11+3, program completed
        summary("test_system");

        if (total_errors == 0) $display("##### ALL CORE TESTS PASSED #####");
        else                   $display("##### %0d CORE TEST ERRORS #####", total_errors);
        $finish;
    end
endmodule
