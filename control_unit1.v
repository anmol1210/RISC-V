module control_unit1(
    input  [6:0] funct7,
    input        reset,
    input  [2:0] funct3,
    input  [6:0] opcode,
    output reg [5:0] alu_control,

    output reg lb_control,          // load byte
    output reg lh_control,          // load half
    output reg lw_control,          // load word
    output reg lbu_control,         // load byte unsigned
    output reg lhu_control,         // load half unsigned

    output reg mem_to_reg,          //data flow from memory to register

    output reg bneq_control,
    output reg beq_control,
    output reg bgeq_control,
    output reg blt_control,
    output reg bltu_control,
    output reg bgeu_control,

    output reg sb_control,          
    output reg sh_control,
    output reg sw_control,

    output reg jalr_control,
    output reg jal_control,

    output reg lui_control,
    output reg auipc_control
);

    always @(*) begin

        
        alu_control   = 6'b000000;
        lb_control    = 0; lh_control   = 0; lw_control  = 0;
        lbu_control   = 0; lhu_control  = 0;
        sb_control    = 0; sh_control   = 0; sw_control  = 0;
        mem_to_reg    = 0;
        beq_control   = 0; bneq_control = 0;
        blt_control   = 0; bgeq_control = 0;
        bltu_control  = 0; bgeu_control = 0;
        jal_control   = 0; jalr_control = 0;
        lui_control   = 0; auipc_control = 0;

        if (reset) begin
            alu_control = 6'b000000;   
        end else begin

            case (opcode)
                // R-TYPE INSTRUCTIONS  (opcode = 0110011)
                7'b0110011: begin
                    case (funct3)
                        3'b000: begin
                            if      (funct7 == 7'b0000000) alu_control = 6'b000001; // ADD
                            else if (funct7 == 7'b0100000) alu_control = 6'b000010; // SUB
                        end
                        3'b001: if (funct7 == 7'b0000000) alu_control = 6'b000011;  // SLL
                        3'b010: if (funct7 == 7'b0000000) alu_control = 6'b000100;  // SLT
                        3'b011: if (funct7 == 7'b0000000) alu_control = 6'b000101;  // SLTU
                        3'b100: if (funct7 == 7'b0000000) alu_control = 6'b000110;  // XOR
                        3'b101: begin
                            if      (funct7 == 7'b0000000) alu_control = 6'b000111; // SRL
                            else if (funct7 == 7'b0100000) alu_control = 6'b001000; // SRA
                        end
                        3'b110: if (funct7 == 7'b0000000) alu_control = 6'b001001;  // OR
                        3'b111: if (funct7 == 7'b0000000) alu_control = 6'b001010;  // AND
                        default: alu_control = 6'b000000;
                    endcase
                end
                // I-TYPE ALU INSTRUCTIONS  (opcode = 0010011)
                7'b0010011: begin
                    case (funct3)
                        3'b000: alu_control = 6'b001011;                             // ADDI
                        3'b001: if (funct7 == 7'b0000000) alu_control = 6'b001100;  // SLLI
                        3'b010: alu_control = 6'b001101;                             // SLTI
                        3'b011: alu_control = 6'b001110;                             // SLTIU
                        3'b100: alu_control = 6'b001111;                             // XORI
                        3'b101: begin
                            if      (funct7 == 7'b0000000) alu_control = 6'b010000; // SRLI
                            else if (funct7 == 7'b0100000) alu_control = 6'b010001; // SRAI
                        end
                        3'b110: alu_control = 6'b010010;                             // ORI
                        3'b111: alu_control = 6'b010011;                             // ANDI
                        default: alu_control = 6'b000000;
                    endcase
                end
                
                // I-TYPE LOAD INSTRUCTIONS  (opcode = 0000011)
                7'b0000011: begin
                    case (funct3)
                        3'b000: begin alu_control = 6'b010100; lb_control  = 1; mem_to_reg = 1; end // LB
                        3'b001: begin alu_control = 6'b010101; lh_control  = 1; mem_to_reg = 1; end // LH
                        3'b010: begin alu_control = 6'b010110; lw_control  = 1; mem_to_reg = 1; end // LW
                        3'b100: begin alu_control = 6'b010111; lbu_control = 1; mem_to_reg = 1; end // LBU
                        3'b101: begin alu_control = 6'b011000; lhu_control = 1; mem_to_reg = 1; end // LHU
                        default: alu_control = 6'b000000;
                    endcase
                end
                // S-TYPE STORE INSTRUCTIONS  (opcode = 0100011)
                7'b0100011: begin
                    case (funct3)
                        3'b000: begin alu_control = 6'b011001; sb_control = 1; end  // SB
                        3'b001: begin alu_control = 6'b011010; sh_control = 1; end  // SH
                        3'b010: begin alu_control = 6'b011011; sw_control = 1; end  // SW
                        default: alu_control = 6'b000000;
                    endcase
                end
                // B-TYPE BRANCH INSTRUCTIONS  (opcode = 1100011)
                7'b1100011: begin
                    case (funct3)
                        3'b000: begin alu_control = 6'b011100; beq_control  = 1; end // BEQ
                        3'b001: begin alu_control = 6'b011101; bneq_control = 1; end // BNE
                        3'b100: begin alu_control = 6'b011110; blt_control  = 1; end // BLT
                        3'b101: begin alu_control = 6'b011111; bgeq_control = 1; end // BGE
                        3'b110: begin alu_control = 6'b100000; bltu_control = 1; end // BLTU
                        3'b111: begin alu_control = 6'b100001; bgeu_control = 1; end // BGEU
                        default: alu_control = 6'b000000;
                    endcase
                end
                // U-TYPE: LUI  (opcode = 0110111)
                7'b0110111: begin
                    alu_control = 6'b100010;
                    lui_control = 1;
                end
                // U-TYPE: AUIPC  (opcode = 0010111)
                7'b0010111: begin
                    alu_control   = 6'b100100;
                    auipc_control = 1;
                end
                // J-TYPE: JAL  (opcode = 1101111)
                7'b1101111: begin
                    alu_control = 6'b100011;
                    jal_control = 1;
                end
                // I-TYPE: JALR  (opcode = 1100111)
                7'b1100111: begin
                    if (funct3 == 3'b000) begin
                        alu_control  = 6'b100101;
                        jalr_control = 1;
                    end
                end

                default: alu_control = 6'b000000;

            endcase
        end
    end

endmodule
