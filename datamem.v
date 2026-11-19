`timescale 1ns / 1ps
//comments to make understanding easy :
  // Writes  – synchronous (posedge clk), controlled by store signals:
//    sb_control  → write 1 byte  (wr_data[7:0]  → mem[wr_addr])
//    sh_control  → write 2 bytes (wr_data[15:0] → mem[wr_addr+1:wr_addr])
//    sw_control  → write 4 bytes (wr_data[31:0] → mem[wr_addr+3:wr_addr])
//
//  Reads   – asynchronous (combinational), always outputs a full 32-bit word
//    assembled from 4 consecutive bytes at rd_addr.
//    Sign / zero extension is handled by the register file (mem_to_reg path).
//
//  Address – 8-bit (byte address), supporting 256 bytes of storage.
//    The ALU computes the effective byte address and drives both wr_addr / rd_addr.

module data_memory (
    input         clk,
    input         rst,

    // Store port (from ALU result and rs2)
    input  [7:0]  wr_addr,       // byte address (from ALU result)
    input  [31:0] wr_data,       // data to store (from register file rs2 output)
    input         sb_control,    // store byte
    input         sh_control,    // store halfword
    input         sw_control,    // store word

    // Load port
    input  [7:0]  rd_addr,       // byte address (from ALU result)
    output [31:0] data_out       // raw 32-bit word; register file applies sign/zero-ext
);

    // 256 byte-wide locations
    reg [7:0] data_mem [0:255];
    integer i;
    // Synchronous write
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 256; i = i + 1)
                data_mem[i] <= 8'd0;
        end
        else begin
            if (sb_control) begin
                // Store Byte: write lowest byte only
                data_mem[wr_addr] <= wr_data[7:0];
            end
            else if (sh_control) begin
                // Store Halfword: write 2 bytes, little-endian
                data_mem[wr_addr    ] <= wr_data[7:0];
                data_mem[wr_addr + 1] <= wr_data[15:8];
            end
            else if (sw_control) begin
                // Store Word: write 4 bytes, little-endian
                data_mem[wr_addr    ] <= wr_data[7:0];
                data_mem[wr_addr + 1] <= wr_data[15:8];
                data_mem[wr_addr + 2] <= wr_data[23:16];
                data_mem[wr_addr + 3] <= wr_data[31:24];
            end
        end
    end
    // Asynchronous read – always assembles a full 32-bit word (little-endian)
    // The register file/mem_to_reg path selects the correct byte(s) and applies
    // sign or zero extension based on lb/lh/lw/lbu/lhu control signals.
    assign data_out = {
        data_mem[rd_addr + 3],
        data_mem[rd_addr + 2],
        data_mem[rd_addr + 1],
        data_mem[rd_addr    ]
    };

endmodule
