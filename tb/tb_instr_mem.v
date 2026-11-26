`timescale 1ns/1ps
module tb_instr_mem;
    reg  [31:0] addr;
    wire [31:0] instr;
    integer errors = 0;

    instr_mem #(.DEPTH(256), .INIT_FILE("sw/compiled_hex/test_alu.hex")) dut (.addr(addr), .instr(instr));

    task check(input [31:0] a, input [31:0] exp, input [8*20-1:0] name);
        begin
            addr = a; #1;
            if (instr === exp) $display("PASS %0s addr=%h instr=%h", name, a, instr);
            else begin $display("FAIL %0s addr=%h instr=%h expected %h", name, a, instr, exp); errors = errors + 1; end
        end
    endtask

    initial begin
        // first three words of test_alu.hex: addi x1,x0,5 / addi x2,x0,-3 / add x3,x1,x2
        check(32'h00, 32'h00500093, "word 0");
        check(32'h04, 32'hFFD00113, "word 1");
        check(32'h08, 32'h002081B3, "word 2");
        check(32'h02, 32'h00500093, "byte offset ignored");
        check(32'h3FC, 32'h00000013, "unused word = NOP");
        if (errors == 0) $display("tb_instr_mem: ALL TESTS PASSED"); else $display("tb_instr_mem: %0d FAILURES", errors);
        $finish;
    end
endmodule
