`timescale 1ns / 1ps

//Although i have mentioned the operation names against the opcodes, here is a table for the reader's ease  :
// alu_control | Instruction
// 6'b000001   ADD   (R)
// 6'b000010  SUB   (R)
// 6'b000011   SLL   (R)
// 6'b000100   SLT   (R)
// 6'b000101   SLTU  (R)
// 6'b000110   XOR   (R)
// 6'b000111   SRL   (R)
// 6'b001000   SRA   (R)
// 6'b001001   OR    (R)
// 6'b001010   AND   (R)
// ------------|------------
// 6'b001011     - ADDI
// 6'b001100      - SLLI
// 6'b001101    - SLTI
// 6'b001110   - SLTIU
// 6'b001111   - XORI
// 6'b010000   - SRLI
// 6'b010001   - SRAI
// 6'b010010   - ORI
// 6'b010011   - ANDI
// ------------------------
// 6'b010100   - LB    (addr = src1 + imm)
// 6'b010101   - LH
// 6'b010110   - LW
// 6'b010111   - LBU
// 6'b011000   - LHU
// ------------------------
// 6'b011001   - SB    (addr = src1 + imm)
// 6'b011010   - SH
// 6'b011011   - SW
// ------------------------
// 6'b011100    BEQ   (result=1 if equal)
// 6'b011101    BNE   (result=1 if not equal)
// 6'b011110    BLT   (result=1 if src1 < src2 signed)
// 6'b011111    BGE   (result=1 if src1 >= src2 signed)
// 6'b100000    BLTU  (result=1 if src1 < src2 unsigned)
// 6'b100001    BGEU  (result=1 if src1 >= src2 unsigned)
// ------------|------------
// 6'b100010    LUI   (result = imm_val_r << 12, done externally; pass-through imm)
// 6'b100011    JAL   (result = PC + 4, handled externally; pass-through)
// 6'b100100    AUIPC (result = PC + imm, handled externally; pass-through)
// 6'b100101    JALR  (result = src1 + imm, LSB cleared by caller)

module alu(
    input  [31:0] src1,
    input  [31:0] src2,
    input  [5:0]  alu_control,
    input  [31:0] imm_val_r,   // sign-extended immediate
    input  [4:0]  shamt,       // shift amount (from imm[4:0] for immediate shifts)
    output reg [31:0] result
);

    always @(*) begin
        case (alu_control)
            // R-TYPE
            6'b000001: result = src1 + src2;                          // ADD
            6'b000010: result = src1 - src2;                          // SUB
            6'b000011: result = src1 << src2[4:0];                   // SLL
            6'b000100: result = ($signed(src1) < $signed(src2))       // SLT
                                    ? 32'd1 : 32'd0;
            6'b000101: result = (src1 < src2) ? 32'd1 : 32'd0;       // SLTU
            6'b000110: result = src1 ^ src2;                          // XOR
            6'b000111: result = src1 >> src2[4:0];                   // SRL
            6'b001000: result = $signed(src1) >>> src2[4:0];         // SRA
            6'b001001: result = src1 | src2;                          // OR
            6'b001010: result = src1 & src2;                          // AND
            
            // I-TYPE ALU
            
            6'b001011: result = src1 + imm_val_r;                     // ADDI
            6'b001100: result = src1 << shamt;                        // SLLI
            6'b001101: result = ($signed(src1) < $signed(imm_val_r))  // SLTI
                                    ? 32'd1 : 32'd0;
            6'b001110: result = (src1 < imm_val_r) ? 32'd1 : 32'd0;  // SLTIU (unsigned)
            6'b001111: result = src1 ^ imm_val_r;                     // XORI
            6'b010000: result = src1 >> shamt;                        // SRLI
            6'b010001: result = $signed(src1) >>> shamt;              // SRAI
            6'b010010: result = src1 | imm_val_r;                     // ORI
            6'b010011: result = src1 & imm_val_r;                     // ANDI

            // LOAD – compute effective address: src1 (base) + imm_val_r (offset)
           
            6'b010100: result = src1 + imm_val_r;  // LB
            6'b010101: result = src1 + imm_val_r;  // LH
            6'b010110: result = src1 + imm_val_r;  // LW
            6'b010111: result = src1 + imm_val_r;  // LBU
            6'b011000: result = src1 + imm_val_r;  // LHU

            // STORE – compute effective address: src1 (base) + imm_val_r (offset)
         
            6'b011001: result = src1 + imm_val_r;  // SB
            6'b011010: result = src1 + imm_val_r;  // SH
            6'b011011: result = src1 + imm_val_r;  // SW

            // BRANCH – result = 1 if branch condition is true, else 0
           
            6'b011100: result = (src1 == src2) ? 32'd1 : 32'd0;               // BEQ
            6'b011101: result = (src1 != src2) ? 32'd1 : 32'd0;               // BNE
            6'b011110: result = ($signed(src1) <  $signed(src2))               // BLT
                                    ? 32'd1 : 32'd0;
            6'b011111: result = ($signed(src1) >= $signed(src2))               // BGE
                                    ? 32'd1 : 32'd0;
            6'b100000: result = (src1 <  src2) ? 32'd1 : 32'd0;               // BLTU
            6'b100001: result = (src1 >= src2) ? 32'd1 : 32'd0;               // BGEU

            // U-TYPE / J-TYPE
            // PC-relative computation is done outside the ALU.
            // The ALU provides the partial result it can compute. 
            
            6'b100010: result = imm_val_r;              // LUI  – upper imm (already shifted by datapath)
            6'b100011: result = src1 + imm_val_r;       // JAL  – target addr (PC + imm, PC passed as src1)
            6'b100100: result = src1 + imm_val_r;       // AUIPC – PC + upper-imm
            6'b100101: result = (src1 + imm_val_r) & ~32'd1; // JALR – (src1+imm) with LSB cleared
            
            // Default / NOP
            default:   result = 32'd0;

        endcase
    end

endmodule
