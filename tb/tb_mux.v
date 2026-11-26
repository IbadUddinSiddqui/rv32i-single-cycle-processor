`timescale 1ns/1ps
module tb_mux;
    reg  [31:0] d0, d1, d2, d3;
    reg  [1:0]  sel4;
    reg         sel2;
    wire [31:0] y2, y4;
    reg  [7:0]  a8, b8;
    wire [7:0]  y8;
    integer errors = 0;

    mux2 #(32) u2 (.d0(d0), .d1(d1), .sel(sel2), .y(y2));
    mux4 #(32) u4 (.d0(d0), .d1(d1), .d2(d2), .d3(d3), .sel(sel4), .y(y4));
    mux2 #(8)  u8 (.d0(a8), .d1(b8), .sel(sel2), .y(y8));   // parameter WIDTH check

    task expect(input [31:0] got, input [31:0] exp, input [8*14-1:0] name);
        begin
            if (got === exp) $display("PASS %0s y=%h", name, got);
            else begin $display("FAIL %0s y=%h expected %h", name, got, exp); errors = errors + 1; end
        end
    endtask

    initial begin
        d0 = 32'h11111111; d1 = 32'h22222222; d2 = 32'h33333333; d3 = 32'h44444444;
        a8 = 8'hAA; b8 = 8'h55;
        sel2 = 0; #1; expect(y2, d0, "mux2 sel=0"); expect(y8, 32'hAA, "mux2 8bit s=0");
        sel2 = 1; #1; expect(y2, d1, "mux2 sel=1"); expect(y8, 32'h55, "mux2 8bit s=1");
        sel4 = 2'd0; #1; expect(y4, d0, "mux4 sel=0");
        sel4 = 2'd1; #1; expect(y4, d1, "mux4 sel=1");
        sel4 = 2'd2; #1; expect(y4, d2, "mux4 sel=2");
        sel4 = 2'd3; #1; expect(y4, d3, "mux4 sel=3");
        if (errors == 0) $display("tb_mux: ALL TESTS PASSED"); else $display("tb_mux: %0d FAILURES", errors);
        $finish;
    end
endmodule
