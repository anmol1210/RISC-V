`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: register_file


module register_file (
    input         clk,
    input         rst,
input  [4:0]  read_reg_num1,   // rs1
    input  [4:0]  read_reg_num2,   // rs2
    output [31:0] read_data1,       // rs1 value
    output [31:0] read_data2,       // rs2 value

        input  [4:0]  write_reg_num1,  // rd
    input         reg_write,        // write-enable for R/I-type ALU results
    input  [31:0] alu_result,

                 // Load controls  (from control unit)
    input         lb_control,
    input         lh_control,
    input         lw_control,
    input         lbu_control,
    input         lhu_control,
    input         mem_to_reg,       // 1 = write memory data into rd

    // Data from data memory (already fetched at the word level)
    input  [31:0] write_data_dm,

    // Store controls  (from control unit)
    input         sb_control,
    input         sh_control,
    input         sw_control,

    // Store data outputs to data memory (from rs2)
    output [7:0]  data_out_sb,      // byte  store
    output [15:0] data_out_sh,      // half  store
    output [31:0] data_out_sw,      // word  store

    // LUI
    input         lui_control,
    input  [31:0] lui_imm_val,      // upper-immediate (already shifted left 12 by datapath)

    // AUIPC / JAL / JALR  – write ALU result (PC+imm or PC+4) into rd
    input         auipc_control,
    input         jal_control,
    input         jalr_control
);

    reg [31:0] reg_mem [31:0];
    integer i;

    // Asynchronous read  (x0 always returns 0)
    assign read_data1   = (read_reg_num1 == 5'd0) ? 32'd0 : reg_mem[read_reg_num1];
    assign read_data2   = (read_reg_num2 == 5'd0) ? 32'd0 : reg_mem[read_reg_num2];

    // Store data outputs – directly driven from rs2 (combinational)
    assign data_out_sb  = reg_mem[read_reg_num2][7:0];
    assign data_out_sh  = reg_mem[read_reg_num2][15:0];
    assign data_out_sw  = reg_mem[read_reg_num2];

    // Synchronous write
    always @(posedge clk) begin
        if (rst) begin
            // Initialise all registers to their index value (keeps original behaviour)
            for (i = 0; i < 32; i = i + 1)
                reg_mem[i] <= i;
        end
        else begin
            // x0 is hardwired to 0 – never write to it
            if (write_reg_num1 != 5'd0) begin

                // --- Load instructions: write sign/zero-extended memory data ---
                if (mem_to_reg) begin
                    if (lb_control)
                        // LB: sign-extend byte
                        reg_mem[write_reg_num1] <= {{24{write_data_dm[7]}},  write_data_dm[7:0]};

                    else if (lh_control)
                        // LH: sign-extend halfword
                        reg_mem[write_reg_num1] <= {{16{write_data_dm[15]}}, write_data_dm[15:0]};

                    else if (lw_control)
                        // LW: full word
                        reg_mem[write_reg_num1] <= write_data_dm;

                    else if (lbu_control)
                        // LBU: zero-extend byte
                        reg_mem[write_reg_num1] <= {24'd0, write_data_dm[7:0]};

                    else if (lhu_control)
                        // LHU: zero-extend halfword
                        reg_mem[write_reg_num1] <= {16'd0, write_data_dm[15:0]};
                end

	
                else if (lui_control)
                    reg_mem[write_reg_num1] <= lui_imm_val;

                else if (auipc_control || jal_control || jalr_control)
                    reg_mem[write_reg_num1] <= alu_result;

                else if (reg_write)
                    reg_mem[write_reg_num1] <= alu_result;

            end
            
        end
    end

endmodule
