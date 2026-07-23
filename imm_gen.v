`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: imm_gen
// Description: RISC-V Immediate Generator
//              Extracts and sign-extends the immediate value from a 32-bit
//              instruction based on its opcode (instruction format).
//
// Supported formats and opcodes:
//   R-type  : 7'b0110011  – no immediate (output 0)
//   I-type  : 7'b0010011  – ALU immediate
//   I-type  : 7'b0000011  – Load (LB/LH/LW/LBU/LHU)
//   I-type  : 7'b1100111  – JALR
//   S-type  : 7'b0100011  – Store (SB/SH/SW)
//   B-type  : 7'b1100011  – Branch (BEQ/BNE/BLT/BGE/BLTU/BGEU)
//   U-type  : 7'b0110111  – LUI
//   U-type  : 7'b0010111  – AUIPC
//   J-type  : 7'b1101111  – JAL
//////////////////////////////////////////////////////////////////////////////////

module imm_gen (
    input  [31:0] instr_memory,   // full 32-bit instruction
    output [31:0] imm_val_r       // sign-extended immediate output
);

    wire [6:0] opcode;
    reg  [31:0] imm_val_reg;

    assign opcode = instr_memory[6:0];   // correct: only bits [6:0]

    always @(*) begin
        case (opcode)

            // I-type: ALU immediate (ADDI, SLTI, XORI, ORI, ANDI, SLLI, SRLI, SRAI)
            7'b0010011: imm_val_reg = {{20{instr_memory[31]}}, instr_memory[31:20]};

            // I-type: Load (LB, LH, LW, LBU, LHU)
            7'b0000011: imm_val_reg = {{20{instr_memory[31]}}, instr_memory[31:20]};

            // I-type: JALR
            7'b1100111: imm_val_reg = {{20{instr_memory[31]}}, instr_memory[31:20]};

            // S-type: Store (SB, SH, SW)
            // imm[11:5] = inst[31:25], imm[4:0] = inst[11:7]
            7'b0100011: imm_val_reg = {{20{instr_memory[31]}},
                                        instr_memory[31:25],
                                        instr_memory[11:7]};

            // B-type: Branch (BEQ, BNE, BLT, BGE, BLTU, BGEU)
            // imm[12]   = inst[31]
            // imm[11]   = inst[7]
            // imm[10:5] = inst[30:25]
            // imm[4:1]  = inst[11:8]
            // imm[0]    = 0 (always, byte-address aligned)
            7'b1100011: imm_val_reg = {{19{instr_memory[31]}},
                                        instr_memory[31],
                                        instr_memory[7],
                                        instr_memory[30:25],
                                        instr_memory[11:8],
                                        1'b0};

            // U-type: LUI
            // imm[31:12] = inst[31:12], imm[11:0] = 0
            7'b0110111: imm_val_reg = {instr_memory[31:12], 12'b0};

            // U-type: AUIPC
            // imm[31:12] = inst[31:12], imm[11:0] = 0
            7'b0010111: imm_val_reg = {instr_memory[31:12], 12'b0};

            // J-type: JAL
            // imm[20]    = inst[31]
            // imm[19:12] = inst[19:12]
            // imm[11]    = inst[20]
            // imm[10:1]  = inst[30:21]
            // imm[0]     = 0
            7'b1101111: imm_val_reg = {{11{instr_memory[31]}},
                                        instr_memory[31],
                                        instr_memory[19:12],
                                        instr_memory[20],
                                        instr_memory[30:21],
                                        1'b0};

            // R-type: no immediate
            7'b0110011: imm_val_reg = 32'd0;

            // Default / unknown opcode
            default:    imm_val_reg = 32'd0;

        endcase
    end

    assign imm_val_r = imm_val_reg;

endmodule
