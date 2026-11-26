`timescale 1ns/1ps
module tb_pc;
    reg         clk = 0, reset;
    reg  [31:0] pc_next;
    wire [31:0] pc_out;
    integer errors = 0, i;

    pc dut (.clk(clk), .reset(reset), .pc_next(pc_next), .pc_out(pc_out));
    always #5 clk = ~clk;

    task expect(input [31:0] exp, input [8*24-1:0] name);
        begin
            if (pc_out === exp) $display("PASS %0s pc=%h", name, pc_out);
            else begin $display("FAIL %0s pc=%h expected %h", name, pc_out, exp); errors = errors + 1; end
        end
    endtask

    initial begin
        reset = 1; pc_next = 32'h1234;
        #1; expect(32'h0, "async reset to 0");
        @(negedge clk); expect(32'h0, "held in reset");
        reset = 0; pc_next = 32'h4;
        @(negedge clk); expect(32'h4, "first clock after reset");
        for (i = 0; i < 4; i = i + 1) begin
            pc_next = pc_out + 32'd4;
            @(negedge clk);
        end
        expect(32'h14, "counts by 4 (5 steps)");
        pc_next = 32'h100; @(negedge clk); expect(32'h100, "jump / branch target");
        pc_next = 32'hABC; #2; expect(32'h100, "no change between clock edges");
        reset = 1; #1; expect(32'h0, "async reset mid-run");
        if (errors == 0) $display("tb_pc: ALL TESTS PASSED"); else $display("tb_pc: %0d FAILURES", errors);
        $finish;
    end
endmodule
