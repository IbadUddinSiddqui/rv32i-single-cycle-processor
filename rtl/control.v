`timescale 1ns/1ps
//==============================================================================
// control.v : Main control unit (opcode/funct3/funct7 -> control signals)
//
//  wb_sel   : 00 = ALU result, 01 = memory read data, 10 = PC+4
//  alu_src_a: 0 = rs1, 1 = PC          (AUIPC)
//  alu_src_b: 0 = rs2, 1 = immediate
//  FENCE / FENCE.I : NOP (single hart, no caches => architecturally correct)
//  ECALL / EBREAK  : is_ecall / is_ebreak -> trap (mepc, mcause, jump to mtvec)
//  CSRRW/S/C(+I)   : csr_op = funct3[1:0], csr_imm = funct3[2], wb_sel = 11 (CSR value)
//==============================================================================
module control (
    input      [6:0] opcode,
    input      [2:0] funct3,
    input      [6:0] funct7,
    input     [11:0] funct12,     // instr[31:20] (CSR address / ECALL-EBREAK code)
    output reg       reg_write,
    output reg       alu_src_a,
    output reg       alu_src_b,
    output reg       mem_write,
    output reg       mem_read,
    output reg [1:0] wb_sel,
    output reg       branch,
    output reg       jal,
    output reg       jalr,
    output reg [3:0] alu_ctrl,
    output reg [2:0] imm_sel,
    output reg [1:0] csr_op,      // 00 none, 01 RW, 10 RS, 11 RC
    output reg       csr_imm,     // 1 = use zero-extended uimm (rs1 field) as source
    output reg       is_ecall,
    output reg       is_ebreak
);
    // opcodes
    localparam OP_R      = 7'b0110011;
    localparam OP_I      = 7'b0010011;
    localparam OP_LOAD   = 7'b0000011;
    localparam OP_STORE  = 7'b0100011;
    localparam OP_BRANCH = 7'b1100011;
    localparam OP_JAL    = 7'b1101111;
    localparam OP_JALR   = 7'b1100111;
    localparam OP_LUI    = 7'b0110111;
    localparam OP_AUIPC  = 7'b0010111;
    localparam OP_FENCE  = 7'b0001111;   // FENCE, FENCE.I
    localparam OP_SYSTEM = 7'b1110011;   // ECALL, EBREAK, CSR*

    // ALU codes (must match alu.v)
    localparam ALU_ADD = 4'd0, ALU_SUB = 4'd1, ALU_SLL = 4'd2, ALU_SLT = 4'd3,
               ALU_SLTU = 4'd4, ALU_XOR = 4'd5, ALU_SRL = 4'd6, ALU_SRA = 4'd7,
               ALU_OR = 4'd8, ALU_AND = 4'd9, ALU_PASSB = 4'd10;

    // immediate select codes (must match imm_gen.v)
    localparam IMM_I = 3'd0, IMM_S = 3'd1, IMM_B = 3'd2, IMM_U = 3'd3, IMM_J = 3'd4;

    // ALU operation for R-type / I-type arithmetic instructions
    reg [3:0] alu_dec;
    always @(*) begin
        alu_dec = ALU_ADD;
        case (funct3)
            3'b000:  alu_dec = (opcode == OP_R && funct7[5]) ? ALU_SUB : ALU_ADD; // ADD/SUB/ADDI
            3'b001:  alu_dec = ALU_SLL;
            3'b010:  alu_dec = ALU_SLT;
            3'b011:  alu_dec = ALU_SLTU;
            3'b100:  alu_dec = ALU_XOR;
            3'b101:  alu_dec = funct7[5] ? ALU_SRA : ALU_SRL;
            3'b110:  alu_dec = ALU_OR;
            3'b111:  alu_dec = ALU_AND;
            default: alu_dec = ALU_ADD;
        endcase
    end

    always @(*) begin
        // defaults (prevent latches)
        reg_write = 1'b0;
        alu_src_a = 1'b0;
        alu_src_b = 1'b0;
        mem_write = 1'b0;
        mem_read  = 1'b0;
        wb_sel    = 2'b00;
        branch    = 1'b0;
        jal       = 1'b0;
        jalr      = 1'b0;
        alu_ctrl  = ALU_ADD;
        imm_sel   = IMM_I;
        csr_op    = 2'b00;
        csr_imm   = 1'b0;
        is_ecall  = 1'b0;
        is_ebreak = 1'b0;

        case (opcode)
            OP_R: begin
                reg_write = 1'b1;
                alu_ctrl  = alu_dec;
            end
            OP_I: begin
                reg_write = 1'b1;
                alu_src_b = 1'b1;
                imm_sel   = IMM_I;
                alu_ctrl  = alu_dec;
            end
            OP_LOAD: begin
                reg_write = 1'b1;
                alu_src_b = 1'b1;
                mem_read  = 1'b1;
                wb_sel    = 2'b01;
                imm_sel   = IMM_I;
                alu_ctrl  = ALU_ADD;
            end
            OP_STORE: begin
                alu_src_b = 1'b1;
                mem_write = 1'b1;
                imm_sel   = IMM_S;
                alu_ctrl  = ALU_ADD;
            end
            OP_BRANCH: begin
                branch    = 1'b1;
                imm_sel   = IMM_B;
            end
            OP_JAL: begin
                reg_write = 1'b1;
                jal       = 1'b1;
                wb_sel    = 2'b10;
                imm_sel   = IMM_J;
            end
            OP_JALR: begin
                reg_write = 1'b1;
                jalr      = 1'b1;
                alu_src_b = 1'b1;
                wb_sel    = 2'b10;
                imm_sel   = IMM_I;
                alu_ctrl  = ALU_ADD;
            end
            OP_LUI: begin
                reg_write = 1'b1;
                alu_src_b = 1'b1;
                imm_sel   = IMM_U;
                alu_ctrl  = ALU_PASSB;
            end
            OP_AUIPC: begin
                reg_write = 1'b1;
                alu_src_a = 1'b1;
                alu_src_b = 1'b1;
                imm_sel   = IMM_U;
                alu_ctrl  = ALU_ADD;
            end
            OP_FENCE: begin
                // FENCE / FENCE.I : no caches and in-order => nothing to do (NOP)
            end
            OP_SYSTEM: begin
                if (funct3 == 3'b000) begin
                    is_ecall  = (funct12 == 12'h000);   // ECALL
                    is_ebreak = (funct12 == 12'h001);   // EBREAK
                    // any other funct12 (e.g. MRET, WFI) is not implemented: NOP
                end else if (funct3[1:0] != 2'b00) begin
                    reg_write = 1'b1;                   // rd <- old CSR value
                    wb_sel    = 2'b11;
                    csr_op    = funct3[1:0];            // 01 RW, 10 RS, 11 RC
                    csr_imm   = funct3[2];              // 1 = immediate form
                end
            end
            default: begin
                // unknown opcode : behave as NOP
            end
        endcase
    end
endmodule
