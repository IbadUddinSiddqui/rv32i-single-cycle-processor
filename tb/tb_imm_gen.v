`timescale 1ns/1ps
module tb_imm_gen;
    reg  [31:0] instr;
    reg  [2:0]  sel;
    wire [31:0] imm;
    integer errors = 0;

    imm_gen dut (.instr(instr), .imm_sel(sel), .imm(imm));

    task check(input [31:0] i, input [2:0] s, input [31:0] exp, input [8*10-1:0] name);
        begin
            instr = i; sel = s; #5;
            if (imm === exp) $display("PASS %0s imm=%h", name, imm);
            else begin $display("FAIL %0s imm=%h expected %h", name, imm, exp); errors = errors + 1; end
        end
    endtask

    initial begin
        check(32'h00500093, 3'd0, 32'h00000005, "addi 5");     // addi x1,x0,5
        check(32'hFFD00113, 3'd0, 32'hFFFFFFFD, "addi -3");    // addi x2,x0,-3
        check(32'h04112023, 3'd1, 32'h00000040, "sw 64");      // sw x1,64(x2)
        check(32'hFE112E23, 3'd1, 32'hFFFFFFFC, "sw -4");      // sw x1,-4(x2)
        check(32'h00208463, 3'd2, 32'h00000008, "beq +8");     // beq x1,x2,+8
        check(32'hFE209EE3, 3'd2, 32'hFFFFFFFC, "bne -4");     // bne x1,x2,-4
        check(32'h123450B7, 3'd3, 32'h12345000, "lui");        // lui x1,0x12345
        check(32'h008000EF, 3'd4, 32'h00000008, "jal +8");     // jal x1,+8
        check(32'hFFDFF0EF, 3'd4, 32'hFFFFFFFC, "jal -4");     // jal x1,-4
        if (errors == 0) $display("tb_imm_gen: ALL TESTS PASSED"); else $display("tb_imm_gen: %0d FAILURES", errors);
        $finish;
    end
endmodule
