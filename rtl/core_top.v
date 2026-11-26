`timescale 1ns/1ps
//==============================================================================
// core_top.v : Single-cycle RV32I processor (top level)
//   Fetch -> Decode -> Execute -> Memory -> Write-back in ONE clock cycle.
//   dbg_pc / dbg_x10 are observation ports (LEDs on the FPGA board).
//   Implements all 47 RV32I-era instructions: 37 base + FENCE, FENCE.I, ECALL,
//   EBREAK and the 6 CSR instructions (csr_file.v).
//==============================================================================
module core_top #(
    parameter INIT_FILE  = "sw/compiled_hex/test_loop.hex",
    parameter IMEM_DEPTH = 256,
    parameter DMEM_DEPTH = 256
) (
    input         clk,
    input         reset,           // active high
    output [31:0] dbg_pc,
    output [31:0] dbg_x10
);
    // ---------------- wires ----------------
    wire [31:0] pc, pc_next, pc_plus4, branch_target, jalr_target;
    wire [31:0] instr, imm;
    wire [31:0] rs1_data, rs2_data;
    wire [31:0] alu_a, alu_b, alu_result;
    wire [31:0] mem_rdata, wb_data;
    wire        br_taken;
    wire [31:0] csr_rdata, csr_src, mtvec;
    wire        csr_imm, is_ecall, is_ebreak, trap;
    wire [1:0]  csr_op;

    // control signals
    wire        reg_write, alu_src_a, alu_src_b, mem_write, mem_read;
    wire        branch, jal, jalr;
    wire [1:0]  wb_sel;
    wire [3:0]  alu_ctrl;
    wire [2:0]  imm_sel;

    // instruction fields
    wire [6:0] opcode = instr[6:0];
    wire [4:0] rd     = instr[11:7];
    wire [2:0] funct3 = instr[14:12];
    wire [4:0] rs1    = instr[19:15];
    wire [4:0] rs2    = instr[24:20];
    wire [6:0] funct7 = instr[31:25];

    assign dbg_pc = pc;

    // ---------------- FETCH ----------------
    pc u_pc (.clk(clk), .reset(reset), .pc_next(pc_next), .pc_out(pc));

    instr_mem #(.DEPTH(IMEM_DEPTH), .INIT_FILE(INIT_FILE)) u_imem (
        .addr(pc), .instr(instr)
    );

    assign pc_plus4 = pc + 32'd4;

    // ---------------- DECODE ----------------
    control u_ctrl (
        .opcode(opcode), .funct3(funct3), .funct7(funct7),
        .reg_write(reg_write), .alu_src_a(alu_src_a), .alu_src_b(alu_src_b),
        .mem_write(mem_write), .mem_read(mem_read), .wb_sel(wb_sel),
        .branch(branch), .jal(jal), .jalr(jalr),
        .alu_ctrl(alu_ctrl), .imm_sel(imm_sel),
        .funct12(instr[31:20]),
        .csr_op(csr_op), .csr_imm(csr_imm), .is_ecall(is_ecall), .is_ebreak(is_ebreak)
    );

    imm_gen u_imm (.instr(instr), .imm_sel(imm_sel), .imm(imm));

    reg_file u_rf (
        .clk(clk), .we(reg_write),
        .rs1(rs1), .rs2(rs2), .rd(rd), .wd(wb_data),
        .rd1(rs1_data), .rd2(rs2_data), .dbg_x10(dbg_x10)
    );

    // ---------------- EXECUTE ----------------
    mux2 #(32) u_mux_alu_a (.d0(rs1_data), .d1(pc),  .sel(alu_src_a), .y(alu_a));
    mux2 #(32) u_mux_alu_b (.d0(rs2_data), .d1(imm), .sel(alu_src_b), .y(alu_b));

    alu u_alu (.a(alu_a), .b(alu_b), .alu_ctrl(alu_ctrl), .result(alu_result));

    branch_cmp u_bcmp (.a(rs1_data), .b(rs2_data), .funct3(funct3), .taken(br_taken));

    // ---------------- CSR / TRAP (Zicsr, ECALL, EBREAK) ----------------
    assign csr_src = csr_imm ? {27'b0, rs1} : rs1_data;   // uimm lives in the rs1 field
    assign trap    = is_ecall | is_ebreak;

    csr_file u_csr (
        .clk(clk), .reset(reset),
        .csr_addr(instr[31:20]), .csr_op(csr_op), .csr_src(csr_src),
        .rs1_nz(rs1 != 5'd0),
        .trap(trap), .trap_pc(pc),
        .trap_cause(is_ebreak ? 32'd3 : 32'd11),          // 11 = ECALL (M-mode), 3 = EBREAK
        .rdata(csr_rdata), .mtvec_out(mtvec)
    );

    // ---------------- MEMORY ----------------
    data_mem #(.DEPTH(DMEM_DEPTH)) u_dmem (
        .clk(clk), .mem_write(mem_write), .funct3(funct3),
        .addr(alu_result), .wdata(rs2_data), .rdata(mem_rdata)
    );

    // ---------------- WRITE-BACK ----------------
    mux4 #(32) u_mux_wb (
        .d0(alu_result), .d1(mem_rdata), .d2(pc_plus4), .d3(csr_rdata),
        .sel(wb_sel), .y(wb_data)
    );

    // ---------------- NEXT PC ----------------
    assign branch_target = pc + imm;                     // branches and JAL
    assign jalr_target   = {alu_result[31:1], 1'b0};     // JALR clears bit 0

    wire       take_branch = branch & br_taken;
    wire [1:0] pc_sel      = trap                  ? 2'b11 :      // ECALL/EBREAK -> mtvec
                             jalr                  ? 2'b10 :
                             (jal | take_branch)   ? 2'b01 : 2'b00;

    mux4 #(32) u_mux_pc (
        .d0(pc_plus4), .d1(branch_target), .d2(jalr_target), .d3(mtvec),
        .sel(pc_sel), .y(pc_next)
    );
endmodule
