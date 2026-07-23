`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: instruction_fetch_unit (ifu)
// Description: RISC-V Instruction Fetch Unit
//   - Increments PC by 4 for sequential execution
//   - Adds branch offset (PC + imm) for taken branches (BEQ/BNE/BLT/BGE/BLTU/BGEU)
//   - Adds jump offset (PC + imm) for JAL
//   - Uses ALU-computed target for JALR (rs1 + imm, LSB cleared)
//   - Stores PC+4 as return address (current_pc) for JAL/JALR
//
// Priority (highest → lowest):
//   1. reset
//   2. JALR  (target from ALU via jalr_target)
//   3. JAL   (PC + imm)
//   4. Branch taken (PC + imm)
//   5. PC + 4
//////////////////////////////////////////////////////////////////////////////////

module instruction_fetch_unit (
    input         clk,
    input         reset,

    // Branch/jump immediate offset (from imm_gen, via top)
    input  [31:0] imm_val_branch,    // B-type offset
    input  [31:0] imm_val_jump,      // J-type offset (JAL)

    // JALR target computed by ALU: (rs1 + imm) with LSB cleared
    input  [31:0] jalr_target,

    // Branch taken signals (from datapath)
    input         beq,
    input         bne,
    input         blt,
    input         bge,
    input         bltu,
    input         bgeu,

    // Jump control signals (from control unit)
    input         jal_control,
    input         jalr_control,

    // PC outputs
    output reg [31:0] pc,            // current programme counter
    output reg [31:0] current_pc     // PC+4 (return address for JAL/JALR)
);

    // Any branch taken
    wire branch_taken = beq | bne | blt | bge | bltu | bgeu;

    always @(posedge clk) begin
        if (reset) begin
            pc         <= 32'd0;
            current_pc <= 32'd0;
        end
        else begin
            // Always save return address before changing PC
            current_pc <= pc + 32'd4;

            if (jalr_control)
                // JALR: jump to ALU-computed target (rs1 + imm, LSB already 0)
                pc <= jalr_target;

            else if (jal_control)
                // JAL: PC-relative jump
                pc <= pc + imm_val_jump;

            else if (branch_taken)
                // Any taken branch: PC-relative
                pc <= pc + imm_val_branch;

            else
                // Sequential: next instruction
                pc <= pc + 32'd4;
        end
    end

endmodule
