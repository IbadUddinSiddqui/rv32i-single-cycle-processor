`timescale 1ns/1ps
module tb_data_mem;
    reg         clk = 0, we;
    reg  [2:0]  f3;
    reg  [31:0] addr, wd;
    wire [31:0] rd;
    integer errors = 0;

    data_mem #(.DEPTH(64)) dut (.clk(clk), .mem_write(we), .funct3(f3), .addr(addr), .wdata(wd), .rdata(rd));
    always #5 clk = ~clk;

    task write(input [2:0] f, input [31:0] a, input [31:0] d);
        begin we = 1; f3 = f; addr = a; wd = d; @(negedge clk); we = 0; end
    endtask
    task read(input [2:0] f, input [31:0] a, input [31:0] exp, input [8*8-1:0] name);
        begin
            f3 = f; addr = a; #2;
            if (rd === exp) $display("PASS %0s rd=%h", name, rd);
            else begin $display("FAIL %0s rd=%h expected %h", name, rd, exp); errors = errors + 1; end
        end
    endtask

    initial begin
        we = 0; f3 = 0; addr = 0; wd = 0; @(negedge clk);
        write(3'b010, 32'h10, 32'h8899AABB);            // SW
        read (3'b010, 32'h10, 32'h8899AABB, "LW");
        read (3'b000, 32'h10, 32'hFFFFFFBB, "LB  0");
        read (3'b000, 32'h11, 32'hFFFFFFAA, "LB  1");
        read (3'b100, 32'h13, 32'h00000088, "LBU 3");
        read (3'b001, 32'h10, 32'hFFFFAABB, "LH  0");
        read (3'b101, 32'h12, 32'h00008899, "LHU 2");
        write(3'b000, 32'h11, 32'h000000FF);            // SB into byte 1
        read (3'b010, 32'h10, 32'h8899FFBB, "SB->LW");
        write(3'b001, 32'h12, 32'h00001234);            // SH into upper half
        read (3'b010, 32'h10, 32'h1234FFBB, "SH->LW");
        if (errors == 0) $display("tb_data_mem: ALL TESTS PASSED"); else $display("tb_data_mem: %0d FAILURES", errors);
        $finish;
    end
endmodule
