`timescale 1ns/1ps
//==============================================================================
// csr_file.v : Minimal machine-mode CSR file + trap registers
//
//  Supports the six Zicsr instructions (CSRRW/CSRRS/CSRRC and immediate forms)
//  and the ECALL / EBREAK trap (mepc <= PC, mcause <= cause).
//
//  Implemented CSRs
//    0x300 mstatus   R/W   (storage only, no interrupt logic)
//    0x301 misa      R     0x40000100 = RV32, "I" extension
//    0x305 mtvec     R/W   trap handler address (direct mode, bits [1:0] = 0)
//    0x340 mscratch  R/W
//    0x341 mepc      R/W   PC of the trapping instruction (bits [1:0] = 0)
//    0x342 mcause    R/W   11 = ECALL, 3 = EBREAK
//    0xC00 cycle / 0xC80 cycleh        R   64-bit clock-cycle counter
//    0xC02 instret / 0xC82 instreth    R   64-bit retired-instruction counter
//    0xF14 mhartid   R     0
//  Any other CSR reads as 0.  Writes to read-only / unknown CSRs are ignored
//  (a full core would raise an illegal-instruction trap; not implemented here).
//
//  csr_op : 00 none, 01 CSRRW, 10 CSRRS, 11 CSRRC
//  rs1_nz : instruction rs1 field != 0 (CSRRS/CSRRC do not write when it is 0)
//==============================================================================
module csr_file (
    input             clk,
    input             reset,
    input      [11:0] csr_addr,
    input      [1:0]  csr_op,
    input      [31:0] csr_src,        // rs1 value, or zero-extended uimm
    input             rs1_nz,
    input             trap,           // ECALL or EBREAK executing
    input      [31:0] trap_pc,
    input      [31:0] trap_cause,
    output reg [31:0] rdata,          // old CSR value (goes to rd)
    output     [31:0] mtvec_out       // trap vector for next-PC logic
);
    localparam CSR_MSTATUS  = 12'h300;
    localparam CSR_MISA     = 12'h301;
    localparam CSR_MTVEC    = 12'h305;
    localparam CSR_MSCRATCH = 12'h340;
    localparam CSR_MEPC     = 12'h341;
    localparam CSR_MCAUSE   = 12'h342;
    localparam CSR_CYCLE    = 12'hC00;
    localparam CSR_INSTRET  = 12'hC02;
    localparam CSR_CYCLEH   = 12'hC80;
    localparam CSR_INSTRETH = 12'hC82;
    localparam CSR_MHARTID  = 12'hF14;

    reg [31:0] mstatus, mtvec, mscratch, mepc, mcause;
    reg [63:0] cycle_cnt, instret_cnt;

    // ---------------- read ----------------
    always @(*) begin
        rdata = 32'h0000_0000;
        case (csr_addr)
            CSR_MSTATUS:  rdata = mstatus;
            CSR_MISA:     rdata = 32'h4000_0100;
            CSR_MTVEC:    rdata = mtvec;
            CSR_MSCRATCH: rdata = mscratch;
            CSR_MEPC:     rdata = mepc;
            CSR_MCAUSE:   rdata = mcause;
            CSR_CYCLE:    rdata = cycle_cnt[31:0];
            CSR_CYCLEH:   rdata = cycle_cnt[63:32];
            CSR_INSTRET:  rdata = instret_cnt[31:0];
            CSR_INSTRETH: rdata = instret_cnt[63:32];
            CSR_MHARTID:  rdata = 32'h0000_0000;
            default:      rdata = 32'h0000_0000;
        endcase
    end

    // ---------------- read-modify-write value ----------------
    reg [31:0] wnew;
    always @(*) begin
        wnew = rdata;
        case (csr_op)
            2'b01:   wnew = csr_src;              // CSRRW
            2'b10:   wnew = rdata |  csr_src;     // CSRRS
            2'b11:   wnew = rdata & ~csr_src;     // CSRRC
            default: wnew = rdata;
        endcase
    end

    // CSRRW always writes; CSRRS/CSRRC only when the rs1 field is not x0
    wire do_write = (csr_op == 2'b01) | ((csr_op != 2'b00) & rs1_nz);

    // ---------------- write / trap / counters ----------------
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            mstatus     <= 32'h0;
            mtvec       <= 32'h0;
            mscratch    <= 32'h0;
            mepc        <= 32'h0;
            mcause      <= 32'h0;
            cycle_cnt   <= 64'h0;
            instret_cnt <= 64'h0;
        end else begin
            cycle_cnt   <= cycle_cnt   + 64'd1;
            instret_cnt <= instret_cnt + 64'd1;      // single cycle: CPI = 1
            if (trap) begin
                mepc   <= {trap_pc[31:2], 2'b00};
                mcause <= trap_cause;
            end else if (do_write) begin
                case (csr_addr)
                    CSR_MSTATUS:  mstatus  <= wnew;
                    CSR_MTVEC:    mtvec    <= {wnew[31:2], 2'b00};
                    CSR_MSCRATCH: mscratch <= wnew;
                    CSR_MEPC:     mepc     <= {wnew[31:2], 2'b00};
                    CSR_MCAUSE:   mcause   <= wnew;
                    default:      ;                  // read-only / unknown: ignored
                endcase
            end
        end
    end

    assign mtvec_out = mtvec;
endmodule
