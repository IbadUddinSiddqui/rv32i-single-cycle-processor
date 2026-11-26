`timescale 1ns/1ps
module tb_reg_file;
    reg         clk = 0;
    reg         we;
    reg  [4:0]  rs1, rs2, rd;
    reg  [31:0] wd;
    wire [31:0] rd1, rd2, dbg;
    integer errors = 0, i;

    reg_file dut (.clk(clk), .we(we), .rs1(rs1), .rs2(rs2), .rd(rd), .wd(wd),
                  .rd1(rd1), .rd2(rd2), .dbg_x10(dbg));

    always #5 clk = ~clk;

    task expect(input [31:0] got, input [31:0] exp, input [8*20-1:0] name);
        begin
            if (got === exp) $display("PASS %0s = %h", name, got);
            else begin $display("FAIL %0s got %h expected %h", name, got, exp); errors = errors + 1; end
        end
    endtask

    initial begin
        we = 0; rs1 = 0; rs2 = 0; rd = 0; wd = 0;
        @(negedge clk);
        // write 5 values to x1..x5
        for (i = 1; i <= 5; i = i + 1) begin
            we = 1; rd = i; wd = 32'h1000 + i;
            @(negedge clk);
        end
        we = 0;
        // read back two at a time
        rs1 = 5'd1; rs2 = 5'd5; #1;
        expect(rd1, 32'h1001, "x1");
        expect(rd2, 32'h1005, "x5");
        rs1 = 5'd3; rs2 = 5'd4; #1;
        expect(rd1, 32'h1003, "x3");
        expect(rd2, 32'h1004, "x4");
        // x0 must stay zero
        we = 1; rd = 5'd0; wd = 32'hDEADBEEF; @(negedge clk);
        rs1 = 5'd0; #1; expect(rd1, 32'h0, "x0 after write");
        // we = 0 must not write
        we = 0; rd = 5'd7; wd = 32'hCAFEBABE; @(negedge clk);
        rs1 = 5'd7; #1; expect(rd1, 32'h0, "x7 with we=0");
        // debug port x10
        we = 1; rd = 5'd10; wd = 32'h55; @(negedge clk); we = 0;
        expect(dbg, 32'h55, "dbg_x10");
        if (errors == 0) $display("tb_reg_file: ALL TESTS PASSED"); else $display("tb_reg_file: %0d FAILURES", errors);
        $finish;
    end
endmodule
