// Module: immgen.v
// Immediate generator for single-cycle RV32I core.
// Pure combinational immediate extraction and sign extension.
// Reads the raw instruction independently of the decoder 
// and determines format via opcode, then slices and
// reassembles the scrambled immediate bit fields especially for B and J types
// or contiguous fields for I , S , U types into one sign-extended 32-bit value.

module immgen (input [31:0] instr,output reg [31:0] imm);

    // imm gen reads the raw instruction directly and thus makes use of the opcode bits[6:0]
    localparam OP_IMM = 7'b0010011;// I type
    localparam LOAD = 7'b0000011;// I type
    localparam JALR = 7'b1100111; // I type
    localparam STORE = 7'b0100011; // S type
    localparam BRANCH = 7'b1100011; // B type
    localparam LUI = 7'b0110111; // U type
    localparam AUIPC = 7'b0010111; // U type
    localparam JAL = 7'b1101111; // J type

    always @(*) 
    begin
        case (instr[6:0])

            // I type: imm[11:0] = instr[31:20]
            OP_IMM, LOAD, JALR: 
            begin
                imm = {{20{instr[31]}}, instr[31:20]};
            end

            // S type: split across two fields, imm[11:5] and imm[4:0]
            STORE: 
            begin
                imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            end

            // B type: scrambled also imm[0] is always 0 (branch targets are 2 byte aligned)
            // bit order when reassembling: imm[12] imm[11] imm[10:5] imm[4:1] 0
            BRANCH:
            begin
                imm = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            end

            // U type: imm sits in the top 20 bits, bottom 12 are 0
            LUI, AUIPC: 
            begin
                imm = {instr[31:12], 12'b0};
            end

            // J type: scrambled AND imm[0] is always 0 (jump targets are 2 byte aligned)
            // bit order when reassembling: imm[20] imm[19:12] imm[11] imm[10:1] 0
            JAL: 
            begin
                imm = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
            end

            // R type and anything else: no immediate thus ignored
            default: 
            begin
                imm = 32'b0;
            end

        endcase
    end

endmodule
