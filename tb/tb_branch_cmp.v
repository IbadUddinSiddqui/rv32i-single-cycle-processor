`timescale 1ns/1ps
module tb_branch_cmp;
    reg  [31:0] a, b;
    reg  [2:0]  f3;
    wire        taken;
    integer errors = 0;

    branch_cmp dut (.a(a), .b(b), .funct3(f3), .taken(taken));

    task check(input [2:0] f, input [31:0] x, input [31:0] y, input exp, input [8*14-1:0] name);
        begin
            f3 = f; a = x; b = y; #1;
            if (taken === exp) $display("PASS %0s taken=%b", name, taken);
            else begin $display("FAIL %0s taken=%b expected %b", name, taken, exp); errors = errors + 1; end
        end
    endtask

    initial begin
        check(3'b000, 32'd5,        32'd5,        1, "BEQ equal");
        check(3'b000, 32'd5,        32'd6,        0, "BEQ differ");
        check(3'b001, 32'd5,        32'd6,        1, "BNE differ");
        check(3'b001, 32'd5,        32'd5,        0, "BNE equal");
        check(3'b100, 32'hFFFFFFFF, 32'd1,        1, "BLT -1<1");
        check(3'b100, 32'd1,        32'hFFFFFFFF, 0, "BLT 1<-1");
        check(3'b101, 32'd1,        32'hFFFFFFFF, 1, "BGE 1>=-1");
        check(3'b101, 32'hFFFFFFFF, 32'd1,        0, "BGE -1>=1");
        check(3'b110, 32'd1,        32'hFFFFFFFF, 1, "BLTU 1<max");
        check(3'b110, 32'hFFFFFFFF, 32'd1,        0, "BLTU max<1");
        check(3'b111, 32'hFFFFFFFF, 32'd1,        1, "BGEU max>=1");
        check(3'b111, 32'd1,        32'hFFFFFFFF, 0, "BGEU 1>=max");
        check(3'b111, 32'd7,        32'd7,        1, "BGEU equal");
        check(3'b010, 32'd1,        32'd1,        0, "invalid f3");
        if (errors == 0) $display("tb_branch_cmp: ALL TESTS PASSED"); else $display("tb_branch_cmp: %0d FAILURES", errors);
        $finish;
    end
endmodule
