`timescale 1ns / 1ps

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
    output reg [31:0] pc,  
    output reg [31:0] current_pc 
);
    wire branch_taken = beq | bne | blt | bge | bltu | bgeu;

    always @(posedge clk) begin
        if (reset) begin
            pc         <= 32'd0;
            current_pc <= 32'd0;
        end
        else begin
            current_pc <= pc + 32'd4;

            if (jalr_control)
                pc <= jalr_target;

            else if (jal_control)
                pc <= pc + imm_val_jump;

            else if (branch_taken)
                pc <= pc + imm_val_branch;

            else
                pc <= pc + 32'd4;
        end
    end

endmodule
