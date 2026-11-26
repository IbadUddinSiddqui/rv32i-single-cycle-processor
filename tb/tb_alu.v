`timescale 1ns/1ps
module tb_alu;
    reg  [31:0] a, b;
    reg  [3:0]  ctrl;
    wire [31:0] y;
    integer errors = 0;

    alu dut (.a(a), .b(b), .alu_ctrl(ctrl), .result(y));

    task check(input [3:0] c, input [31:0] x, input [31:0] z, input [31:0] exp, input [8*8-1:0] name);
        begin
            ctrl = c; a = x; b = z; #5;
            if (y === exp) $display("PASS %-6s a=%h b=%h y=%h", name, a, b, y);
            else begin $display("FAIL %-6s a=%h b=%h y=%h expected %h", name, a, b, y, exp); errors = errors + 1; end
        end
    endtask

    initial begin
        check(4'd0,  32'd5,         32'd7,        32'd12,       "ADD");
        check(4'd0,  32'hFFFFFFFF,  32'd1,        32'd0,        "ADDwrap");
        check(4'd1,  32'd5,         32'd7,        32'hFFFFFFFE, "SUB");
        check(4'd2,  32'd1,         32'd31,       32'h80000000, "SLL");
        check(4'd3,  32'hFFFFFFFD,  32'd5,        32'd1,        "SLT");
        check(4'd3,  32'd5,         32'hFFFFFFFD, 32'd0,        "SLT2");
        check(4'd4,  32'hFFFFFFFD,  32'd5,        32'd0,        "SLTU");
        check(4'd4,  32'd5,         32'hFFFFFFFD, 32'd1,        "SLTU2");
        check(4'd5,  32'hF0F0F0F0,  32'hFF00FF00, 32'h0FF00FF0, "XOR");
        check(4'd6,  32'h80000000,  32'd4,        32'h08000000, "SRL");
        check(4'd7,  32'h80000000,  32'd4,        32'hF8000000, "SRA");
        check(4'd8,  32'hF0F0F0F0,  32'h0F0F0F0F, 32'hFFFFFFFF, "OR");
        check(4'd9,  32'hF0F0F0F0,  32'hFF00FF00, 32'hF000F000, "AND");
        check(4'd10, 32'd123,       32'hABCD0000, 32'hABCD0000, "PASSB");
        check(4'd15, 32'd1,         32'd1,        32'd0,        "DEFAULT");
        if (errors == 0) $display("tb_alu: ALL TESTS PASSED"); else $display("tb_alu: %0d FAILURES", errors);
        $finish;
    end
endmodule
