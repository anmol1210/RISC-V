`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Engineer    : TADAKAMALLA GOURAV
// Module Name : top_riscv
// Description : Top-level RISC-V processor.
//               Connects all six submodules:
//                 1. instruction_fetch_unit  (IFU)
//                 2. instruction_memory      (IMU)
//                 3. imm_gen                 (Immediate Generator)
//                 4. control_unit            (CU)
//                 5. data_path               (DP)  – contains register_file, alu, data_memory
//
// Signal flow:
//   PC → IMU → instruction_out
//   instruction_out → imm_gen  → imm_val (all formats)
//   instruction_out → CU       → all control signals
//   instruction_out[rs1/rs2/rd] + control + imm_val → data_path → branch signals + jalr_target
//   branch signals + jalr_target → IFU → next PC
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module top_riscv (
    input clk,
    input reset
	output [31:0] pc_out,
	output [31:0] instruction_out,
	output [31:0] imm_out,
	output beq_out
);

    // -------------------------------------------------------------------------
    // Programme Counter & instruction bus
    // -------------------------------------------------------------------------
    wire [31:0] pc;
    wire [31:0] current_pc;          // PC+4 return address (available if needed)
    wire [31:0] instruction_out;     // 32-bit instruction word

    // -------------------------------------------------------------------------
    // Immediate value (single bus – imm_gen selects correct format by opcode)
    // -------------------------------------------------------------------------
    wire [31:0] imm_val;

    // -------------------------------------------------------------------------
    // Control unit outputs
    // -------------------------------------------------------------------------
    wire [5:0]  alu_control;
    wire        reg_write;
    wire        mem_to_reg;
    // Load
    wire        lb_control;
    wire        lh_control;
    wire        lw_control;
    wire        lbu_control;
    wire        lhu_control;
    // Store
    wire        sb_control;
    wire        sh_control;
    wire        sw_control;
    // Branch
    wire        beq_control;
    wire        bne_control;
    wire        blt_control;
    wire        bge_control;
    wire        bltu_control;
    wire        bgeu_control;
    // Upper-immediate / jump
    wire        lui_control;
    wire        auipc_control;
    wire        jal_control;
    wire        jalr_control;

    // -------------------------------------------------------------------------
    // Datapath → IFU: branch taken flags and JALR target
    // -------------------------------------------------------------------------
    wire        beq;
    wire        bne;
    wire        blt;
    wire        bge;
    wire        bltu;
    wire        bgeu;
    wire [31:0] jalr_target;        // ALU result for JALR: (rs1+imm) with LSB=0

    // =========================================================================
    // 1. INSTRUCTION FETCH UNIT
    // =========================================================================
    instruction_fetch_unit ifu (
        .clk            (clk),
        .reset          (reset),
        // Offsets from imm_gen (same wire – correct format selected per opcode)
        .imm_val_branch (imm_val),
        .imm_val_jump   (imm_val),
        // JALR absolute target from ALU
        .jalr_target    (jalr_target),
        // Branch taken flags
        .beq            (beq),
        .bne            (bne),
        .blt            (blt),
        .bge            (bge),
        .bltu           (bltu),
        .bgeu           (bgeu),
        // Jump controls
        .jal_control    (jal_control),
        .jalr_control   (jalr_control),
        // Outputs
        .pc             (pc),
        .current_pc     (current_pc)
    );

    // =========================================================================
    // 2. INSTRUCTION MEMORY
    // =========================================================================
    instruction_memory imu (
        .clk             (clk),
        .reset           (reset),
        .pc              (pc),
        .instruction_out (instruction_out)
    );

    // =========================================================================
    // 3. IMMEDIATE GENERATOR
    //    Decodes instruction format from opcode and sign-extends the immediate.
    //    One output covers all formats: I, S, B, U, J.
    // =========================================================================
    imm_gen imm_generator (
        .instr_memory (instruction_out),
        .imm_val_r    (imm_val)
    );

    // =========================================================================
    // 4. CONTROL UNIT
    //    Inputs: funct7[31:25], funct3[14:12], opcode[6:0]
    // =========================================================================
    control_unit1 cu (
        .reset         (reset),
        .funct7        (instruction_out[31:25]),
        .funct3        (instruction_out[14:12]),
        .opcode        (instruction_out[6:0]),
        // ALU
        .alu_control   (alu_control),
        .reg_write     (reg_write),
        // Load
        .lb_control    (lb_control),
        .lh_control    (lh_control),
        .lw_control    (lw_control),
        .lbu_control   (lbu_control),
        .lhu_control   (lhu_control),
        .mem_to_reg    (mem_to_reg),
        // Store
        .sb_control    (sb_control),
        .sh_control    (sh_control),
        .sw_control    (sw_control),
        // Branch
        .beq_control   (beq_control),
        .bne_control   (bne_control),
        .blt_control   (blt_control),
        .bge_control   (bge_control),
        .bltu_control  (bltu_control),
        .bgeu_control  (bgeu_control),
        // Upper-immediate / jump
        .lui_control   (lui_control),
        .auipc_control (auipc_control),
        .jal_control   (jal_control),
        .jalr_control  (jalr_control)
    );

    // =========================================================================
    // 5. DATA PATH
    //    Contains: register_file, alu, data_memory
    //
    //    Register fields from instruction:
    //      rs1  = instruction_out[19:15]
    //      rs2  = instruction_out[24:20]
    //      rd   = instruction_out[11:7]
    //      shamt= instruction_out[24:20]  (same field as rs2 for shift immediates)
    // =========================================================================
    data_path dpu (
        .clk            (clk),
        .rst            (reset),
        // Register addresses
        .read_reg_num1  (instruction_out[19:15]),   // rs1
        .read_reg_num2  (instruction_out[24:20]),   // rs2
        .write_reg_num1 (instruction_out[11:7]),    // rd
        // ALU
        .alu_control    (alu_control),
        .imm_val        (imm_val),
        .shamt          (instruction_out[24:20]),   // shift amount = rs2 field [4:0]
        // Write-back
        .reg_write      (reg_write),
        .mem_to_reg     (mem_to_reg),
        // Load
        .lb_control     (lb_control),
        .lh_control     (lh_control),
        .lw_control     (lw_control),
        .lbu_control    (lbu_control),
        .lhu_control    (lhu_control),
        // Store
        .sb_control     (sb_control),
        .sh_control     (sh_control),
        .sw_control     (sw_control),
        // Branch controls
        .beq_control    (beq_control),
        .bne_control    (bne_control),
        .blt_control    (blt_control),
        .bge_control    (bge_control),
        .bltu_control   (bltu_control),
        .bgeu_control   (bgeu_control),
        // Branch taken → IFU
        .beq            (beq),
        .bne            (bne),
        .blt            (blt),
        .bge            (bge),
        .bltu           (bltu),
        .bgeu           (bgeu),
        // Upper-immediate / jump
        .lui_control    (lui_control),
        .lui_imm_val    (imm_val),        // LUI immediate from imm_gen
        .auipc_control  (auipc_control),
        .jal_control    (jal_control),
        .jalr_control   (jalr_control),
        // JALR target back to IFU (ALU result: rs1 + imm, LSB cleared)
        .jalr_target    (jalr_target)
    );

endmodule
