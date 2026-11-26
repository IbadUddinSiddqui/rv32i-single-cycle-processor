`timescale 1ns/1ps
module tb_csr_file;
    reg         clk = 0, reset = 1;
    reg  [11:0] addr = 0;
    reg  [1:0]  op = 0;
    reg  [31:0] src = 0;
    reg         nz = 0, trap = 0;
    reg  [31:0] tpc = 0, tcause = 0;
    wire [31:0] rdata, mtvec;
    integer errors = 0;
    reg [31:0] c1, c2;

    csr_file dut (.clk(clk), .reset(reset), .csr_addr(addr), .csr_op(op), .csr_src(src),
                  .rs1_nz(nz), .trap(trap), .trap_pc(tpc), .trap_cause(tcause),
                  .rdata(rdata), .mtvec_out(mtvec));
    always #5 clk = ~clk;

    // perform one CSR instruction (takes effect on the next rising edge)
    task csr(input [1:0] o, input [11:0] a, input [31:0] s, input n);
        begin addr = a; op = o; src = s; nz = n; @(negedge clk); op = 0; end
    endtask
    task expect(input [11:0] a, input [31:0] exp, input [8*22-1:0] name);
        begin
            addr = a; op = 0; #1;
            if (rdata === exp) $display("PASS %0s = %h", name, rdata);
            else begin $display("FAIL %0s = %h expected %h", name, rdata, exp); errors = errors + 1; end
        end
    endtask

    initial begin
        @(negedge clk); @(negedge clk); reset = 0;
        expect(12'h340, 32'h0,        "mscratch after reset");
        csr(2'b01, 12'h340, 32'hA5A5_0F0F, 1);  expect(12'h340, 32'hA5A50F0F, "CSRRW write");
        csr(2'b10, 12'h340, 32'h0000_F000, 1);  expect(12'h340, 32'hA5A5FF0F, "CSRRS set bits");
        csr(2'b11, 12'h340, 32'h0000_00FF, 1);  expect(12'h340, 32'hA5A5FF00, "CSRRC clear bits");
        csr(2'b10, 12'h340, 32'hFFFF_FFFF, 0);  expect(12'h340, 32'hA5A5FF00, "CSRRS rs1=x0 no write");
        csr(2'b11, 12'h340, 32'hFFFF_FFFF, 0);  expect(12'h340, 32'hA5A5FF00, "CSRRC rs1=x0 no write");
        csr(2'b01, 12'h305, 32'h0000_1003, 1);  expect(12'h305, 32'h0000_1000, "mtvec low bits = 0");
        if (mtvec === 32'h1000) $display("PASS mtvec_out = 1000"); else begin $display("FAIL mtvec_out=%h", mtvec); errors = errors + 1; end
        // trap
        tpc = 32'h0000_006C; tcause = 32'd11; trap = 1; @(negedge clk); trap = 0;
        expect(12'h341, 32'h0000_006C, "mepc after trap");
        expect(12'h342, 32'd11,        "mcause after trap");
        // read-only / unknown CSRs
        expect(12'h301, 32'h4000_0100, "misa (RV32I)");
        csr(2'b01, 12'h301, 32'hFFFF_FFFF, 1);  expect(12'h301, 32'h4000_0100, "misa write ignored");
        expect(12'hF14, 32'h0,         "mhartid");
        expect(12'h7C0, 32'h0,         "unknown CSR reads 0");
        // counters
        addr = 12'hC00; #1; c1 = rdata; @(negedge clk); #1; c2 = rdata;
        if (c2 === c1 + 32'd1) $display("PASS cycle counter +1 per clock (%0d -> %0d)", c1, c2);
        else begin $display("FAIL cycle counter %0d -> %0d", c1, c2); errors = errors + 1; end
        addr = 12'hC02; #1; c1 = rdata; @(negedge clk); #1; c2 = rdata;
        if (c2 === c1 + 32'd1) $display("PASS instret counter +1 per clock"); else begin $display("FAIL instret"); errors = errors + 1; end
        // reset clears everything
        reset = 1; #1; expect(12'h342, 32'h0, "mcause after reset"); reset = 0;
        if (errors == 0) $display("tb_csr_file: ALL TESTS PASSED"); else $display("tb_csr_file: %0d FAILURES", errors);
        $finish;
    end
endmodule
