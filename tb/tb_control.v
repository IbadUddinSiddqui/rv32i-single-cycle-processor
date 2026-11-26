`timescale 1ns/1ps
module tb_control;
    reg  [6:0] opcode, funct7;
    reg [11:0] funct12 = 12'h0;
    wire [1:0] csr_op;
    wire       csr_imm, is_ecall, is_ebreak;
    reg  [2:0] funct3;
    wire       reg_write, alu_src_a, alu_src_b, mem_write, mem_read, branch, jal, jalr;
    wire [1:0] wb_sel;
    wire [3:0] alu_ctrl;
    wire [2:0] imm_sel;
    integer errors = 0;

    control dut (.opcode(opcode), .funct3(funct3), .funct7(funct7), .funct12(funct12),
        .csr_op(csr_op), .csr_imm(csr_imm), .is_ecall(is_ecall), .is_ebreak(is_ebreak),
        .reg_write(reg_write), .alu_src_a(alu_src_a), .alu_src_b(alu_src_b),
        .mem_write(mem_write), .mem_read(mem_read), .wb_sel(wb_sel),
        .branch(branch), .jal(jal), .jalr(jalr), .alu_ctrl(alu_ctrl), .imm_sel(imm_sel));

    task chk(input [8*8-1:0] name, input [6:0] op, input [2:0] f3, input [6:0] f7,
             input [15:0] exp);
        // exp = {reg_write, alu_src_a, alu_src_b, mem_write, mem_read, branch, jal, jalr, wb_sel[1:0], ...}
        reg [15:0] got;
        begin
            opcode = op; funct3 = f3; funct7 = f7; #2;
            got = {reg_write, alu_src_a, alu_src_b, mem_write, mem_read, branch, jal, jalr, wb_sel, 6'b0};
            if (got[15:6] === exp[15:6]) $display("PASS %0s ctrl=%b alu=%0d imm=%0d", name, got[15:6], alu_ctrl, imm_sel);
            else begin $display("FAIL %0s got %b expected %b", name, got[15:6], exp[15:6]); errors = errors + 1; end
        end
    endtask

    initial begin
        //           rw a  b  mw mr br jl jr wb
        chk("ADD",   7'b0110011, 3'b000, 7'b0000000, {10'b1_0_0_0_0_0_0_0_00, 6'b0});
        chk("LW",    7'b0000011, 3'b010, 7'b0000000, {10'b1_0_1_0_1_0_0_0_01, 6'b0});
        chk("SW",    7'b0100011, 3'b010, 7'b0000000, {10'b0_0_1_1_0_0_0_0_00, 6'b0});
        chk("BEQ",   7'b1100011, 3'b000, 7'b0000000, {10'b0_0_0_0_0_1_0_0_00, 6'b0});
        chk("JAL",   7'b1101111, 3'b000, 7'b0000000, {10'b1_0_0_0_0_0_1_0_10, 6'b0});
        chk("JALR",  7'b1100111, 3'b000, 7'b0000000, {10'b1_0_1_0_0_0_0_1_10, 6'b0});
        chk("LUI",   7'b0110111, 3'b000, 7'b0000000, {10'b1_0_1_0_0_0_0_0_00, 6'b0});
        chk("AUIPC", 7'b0010111, 3'b000, 7'b0000000, {10'b1_1_1_0_0_0_0_0_00, 6'b0});
        chk("ECALL", 7'b1110011, 3'b000, 7'b0000000, 16'b0);
        if (is_ecall === 1'b1 && is_ebreak === 1'b0) $display("PASS ECALL flag");
        else begin $display("FAIL ECALL flag"); errors = errors + 1; end
        funct12 = 12'h001; chk("EBREAK", 7'b1110011, 3'b000, 7'b0000000, 16'b0);
        if (is_ecall === 1'b0 && is_ebreak === 1'b1) $display("PASS EBREAK flag");
        else begin $display("FAIL EBREAK flag"); errors = errors + 1; end
        funct12 = 12'h302; chk("MRET=NOP", 7'b1110011, 3'b000, 7'b0011000, 16'b0);   // not implemented: must do nothing
        if (is_ecall === 1'b0 && is_ebreak === 1'b0) $display("PASS unknown SYSTEM = NOP");
        else begin $display("FAIL unknown SYSTEM"); errors = errors + 1; end
        funct12 = 12'h340;
        chk("CSRRW",  7'b1110011, 3'b001, 7'b0, {10'b1_0_0_0_0_0_0_0_11, 6'b0});
        if (csr_op === 2'b01 && csr_imm === 1'b0) $display("PASS CSRRW  op/imm"); else begin $display("FAIL CSRRW op=%b imm=%b", csr_op, csr_imm); errors = errors + 1; end
        chk("CSRRS",  7'b1110011, 3'b010, 7'b0, {10'b1_0_0_0_0_0_0_0_11, 6'b0});
        if (csr_op === 2'b10 && csr_imm === 1'b0) $display("PASS CSRRS  op/imm"); else begin $display("FAIL CSRRS"); errors = errors + 1; end
        chk("CSRRC",  7'b1110011, 3'b011, 7'b0, {10'b1_0_0_0_0_0_0_0_11, 6'b0});
        if (csr_op === 2'b11 && csr_imm === 1'b0) $display("PASS CSRRC  op/imm"); else begin $display("FAIL CSRRC"); errors = errors + 1; end
        chk("CSRRWI", 7'b1110011, 3'b101, 7'b0, {10'b1_0_0_0_0_0_0_0_11, 6'b0});
        if (csr_op === 2'b01 && csr_imm === 1'b1) $display("PASS CSRRWI op/imm"); else begin $display("FAIL CSRRWI"); errors = errors + 1; end
        chk("CSRRSI", 7'b1110011, 3'b110, 7'b0, {10'b1_0_0_0_0_0_0_0_11, 6'b0});
        if (csr_op === 2'b10 && csr_imm === 1'b1) $display("PASS CSRRSI op/imm"); else begin $display("FAIL CSRRSI"); errors = errors + 1; end
        chk("CSRRCI", 7'b1110011, 3'b111, 7'b0, {10'b1_0_0_0_0_0_0_0_11, 6'b0});
        if (csr_op === 2'b11 && csr_imm === 1'b1) $display("PASS CSRRCI op/imm"); else begin $display("FAIL CSRRCI"); errors = errors + 1; end
        funct12 = 12'h0;
        chk("FENCE",  7'b0001111, 3'b000, 7'b0, 16'b0);
        chk("FENCE.I",7'b0001111, 3'b001, 7'b0, 16'b0);
        // ALU codes
        opcode = 7'b0110011; funct3 = 3'b000; funct7 = 7'b0100000; #2;
        if (alu_ctrl === 4'd1) $display("PASS SUB alu_ctrl"); else begin $display("FAIL SUB alu_ctrl=%0d", alu_ctrl); errors = errors + 1; end
        opcode = 7'b0010011; funct3 = 3'b000; funct7 = 7'b1111111; #2;   // ADDI with negative imm must stay ADD
        if (alu_ctrl === 4'd0) $display("PASS ADDI(neg) alu_ctrl"); else begin $display("FAIL ADDI alu_ctrl=%0d", alu_ctrl); errors = errors + 1; end
        opcode = 7'b0010011; funct3 = 3'b101; funct7 = 7'b0100000; #2;
        if (alu_ctrl === 4'd7) $display("PASS SRAI alu_ctrl"); else begin $display("FAIL SRAI alu_ctrl=%0d", alu_ctrl); errors = errors + 1; end
        if (errors == 0) $display("tb_control: ALL TESTS PASSED"); else $display("tb_control: %0d FAILURES", errors);
        $finish;
    end
endmodule
