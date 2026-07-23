`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: instruction_memory
// Description: RISC-V Instruction Memory (ROM)
//   - Byte-addressable, little-endian
//   - 152 bytes (covers all test instructions up to address 147 + 3-byte margin)
//   - Synchronous load on reset; asynchronous read
//   - PC indexes the byte address; 4 bytes assembled into a 32-bit word
//////////////////////////////////////////////////////////////////////////////////

module instruction_memory (
    input         clk,
    input         reset,
    input  [31:0] pc,
    output [31:0] instruction_out
);

    // 152 bytes: instructions go up to memory[147], need [147+3]=150 → 152 safe
    reg [7:0] memory [0:151];

    // Asynchronous read – little-endian word assembly
    assign instruction_out = {memory[pc+3], memory[pc+2], memory[pc+1], memory[pc]};

    integer i;

    always @(posedge clk) begin
        if (reset) begin

            // Zero-initialise all locations first to avoid X on unused addresses
            for (i = 0; i < 152; i = i + 1)
                memory[i] <= 8'h00;

            // ----------------------------------------------------------------
            // R-TYPE INSTRUCTIONS
            // ----------------------------------------------------------------
            // ADD  x5, x6, x7  → 0x007302b3
            memory[3]  <= 8'h00; memory[2]  <= 8'h73; memory[1]  <= 8'h02; memory[0]  <= 8'hb3;
            // SUB  x8, x9, x8  → 0x40848433
            memory[7]  <= 8'h40; memory[6]  <= 8'h84; memory[5]  <= 8'h84; memory[4]  <= 8'h33;
            // SLL  x11,x12,x13 → 0x00d615b3
            memory[11] <= 8'h00; memory[10] <= 8'hd6; memory[9]  <= 8'h15; memory[8]  <= 8'hb3;
            // SLT  x14,x15,x16 → 0x0107a733
            memory[15] <= 8'h01; memory[14] <= 8'h07; memory[13] <= 8'ha7; memory[12] <= 8'h33;
            // SLTU x17,x18,x19 → 0x013938b3
            memory[19] <= 8'h01; memory[18] <= 8'h39; memory[17] <= 8'h38; memory[16] <= 8'hb3;
            // XOR  x20,x21,x22 → 0x016aca33
            memory[23] <= 8'h01; memory[22] <= 8'h6a; memory[21] <= 8'hca; memory[20] <= 8'h33;
            // SRL  x23,x24,x25 → 0x019c5bb3
            memory[27] <= 8'h01; memory[26] <= 8'h9c; memory[25] <= 8'h5b; memory[24] <= 8'hb3;
            // SRA  x26,x27,x28 → 0x41cddd33
            memory[31] <= 8'h41; memory[30] <= 8'hcd; memory[29] <= 8'hdd; memory[28] <= 8'h33;
            // OR   x29,x31,x31 → 0x01ff6eb3
            memory[35] <= 8'h01; memory[34] <= 8'hff; memory[33] <= 8'h6e; memory[32] <= 8'hb3;
            // AND  x1, x2, x3  → 0x003170b3
            memory[39] <= 8'h00; memory[38] <= 8'h31; memory[37] <= 8'h70; memory[36] <= 8'hb3;

            // ----------------------------------------------------------------
            // I-TYPE: ALU IMMEDIATE
            // ----------------------------------------------------------------
            // ADDI  x5, x6, 15  → 0x00f30293
            memory[43] <= 8'h00; memory[42] <= 8'hf3; memory[41] <= 8'h02; memory[40] <= 8'h93;
            // SLTI  x7, x8, 20  → 0x01442393
            memory[47] <= 8'h01; memory[46] <= 8'h44; memory[45] <= 8'h23; memory[44] <= 8'h93;
            // SLTIU x9, x10,25  → 0x01953493
            memory[51] <= 8'h01; memory[50] <= 8'h95; memory[49] <= 8'h34; memory[48] <= 8'h93;
            // XORI  x11,x12,30  → 0x01e64593
            memory[55] <= 8'h01; memory[54] <= 8'he6; memory[53] <= 8'h45; memory[52] <= 8'h93;
            // ORI   x13,x14,35  → 0x02376693
            memory[59] <= 8'h02; memory[58] <= 8'h37; memory[57] <= 8'h66; memory[56] <= 8'h93;
            // ANDI  x15,x16,40  → 0x02887793
            memory[63] <= 8'h02; memory[62] <= 8'h88; memory[61] <= 8'h77; memory[60] <= 8'h93;

            // ----------------------------------------------------------------
            // I-TYPE: SHIFT IMMEDIATE
            // ----------------------------------------------------------------
            // SLLI  x5, x6, 2   → 0x00231293
            memory[67] <= 8'h00; memory[66] <= 8'h23; memory[65] <= 8'h12; memory[64] <= 8'h93;
            // SRLI  x7, x8, 3   → 0x00345393
            memory[71] <= 8'h00; memory[70] <= 8'h34; memory[69] <= 8'h53; memory[68] <= 8'h93;
            // SRAI  x9, x10,1   → 0x40155493
            memory[75] <= 8'h40; memory[74] <= 8'h15; memory[73] <= 8'h54; memory[72] <= 8'h93;

            // ----------------------------------------------------------------
            // I-TYPE: LOAD
            // ----------------------------------------------------------------
            // LB    x5, 0(x6)   → 0x00030283
            memory[79] <= 8'h00; memory[78] <= 8'h03; memory[77] <= 8'h02; memory[76] <= 8'h83;
            // LH    x7, 4(x8)   → 0x00441383
            memory[83] <= 8'h00; memory[82] <= 8'h44; memory[81] <= 8'h13; memory[80] <= 8'h83;
            // LW    x5, 0(x6)   → 0x00030283
            memory[87] <= 8'h00; memory[86] <= 8'h03; memory[85] <= 8'h02; memory[84] <= 8'h83;
            // LBU   x11,12(x12) → 0x00c64583
            memory[91] <= 8'h00; memory[90] <= 8'hc6; memory[89] <= 8'h45; memory[88] <= 8'h83;
            // LHU   x13,16(x14) → 0x01075683
            memory[95] <= 8'h01; memory[94] <= 8'h07; memory[93] <= 8'h56; memory[92] <= 8'h83;

            // ----------------------------------------------------------------
            // I-TYPE: JALR
            // ----------------------------------------------------------------
            // JALR  x1, 0(x5)   → 0x000280e7
            memory[99]  <= 8'h00; memory[98]  <= 8'h02; memory[97]  <= 8'h80; memory[96]  <= 8'he7;

            // ----------------------------------------------------------------
            // S-TYPE: STORE
            // ----------------------------------------------------------------
            // SB    x5, 0(x6)   → 0x00530023
            memory[103] <= 8'h00; memory[102] <= 8'h53; memory[101] <= 8'h00; memory[100] <= 8'h23;
            // SH    x7, 4(x8)   → 0x00741223
            memory[107] <= 8'h00; memory[106] <= 8'h74; memory[105] <= 8'h12; memory[104] <= 8'h23;
            // SW    x9, 8(x10)  → 0x00952423
            memory[111] <= 8'h00; memory[110] <= 8'h95; memory[109] <= 8'h24; memory[108] <= 8'h23;

            // ----------------------------------------------------------------
            // B-TYPE: BRANCH
            // ----------------------------------------------------------------
            // BEQ   x5, x6, 8   → 0x00629463
            memory[115] <= 8'h00; memory[114] <= 8'h62; memory[113] <= 8'h94; memory[112] <= 8'h63;
            // BNE   x7, x8, 8   → 0x00838463  (was labelled bneq)
            memory[119] <= 8'h00; memory[118] <= 8'h83; memory[117] <= 8'h84; memory[116] <= 8'h63;
            // BLT   x9, x10,8   → 0x00a4c463
            memory[123] <= 8'h00; memory[122] <= 8'ha4; memory[121] <= 8'hc4; memory[120] <= 8'h63;
            // BGE   x11,x12,8   → 0x00c5d463
            memory[127] <= 8'h00; memory[126] <= 8'hc5; memory[125] <= 8'hd4; memory[124] <= 8'h63;
            // BLTU  x13,x14,8   → 0x00e6e463
            memory[131] <= 8'h00; memory[130] <= 8'he6; memory[129] <= 8'he4; memory[128] <= 8'h63;
            // BGEU  x15,x16,8   → 0x0107f463
            memory[135] <= 8'h01; memory[134] <= 8'h07; memory[133] <= 8'hf4; memory[132] <= 8'h63;

            // ----------------------------------------------------------------
            // U-TYPE
            // ----------------------------------------------------------------
            // LUI   x5, 0x12345 → 0x123452b7
            memory[139] <= 8'h12; memory[138] <= 8'h34; memory[137] <= 8'h52; memory[136] <= 8'hb7;
            // AUIPC x6, 0x54321 → 0x54321317
            memory[143] <= 8'h54; memory[142] <= 8'h32; memory[141] <= 8'h13; memory[140] <= 8'h17;

            // ----------------------------------------------------------------
            // J-TYPE
            // ----------------------------------------------------------------
            // JAL   x1, 64      → 0x040000ef
            memory[147] <= 8'h04; memory[146] <= 8'h00; memory[145] <= 8'h00; memory[144] <= 8'hef;

        end // reset
    end // always

endmodule
