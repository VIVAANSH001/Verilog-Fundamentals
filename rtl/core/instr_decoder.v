// Module: instr_decoder.v
// Fixed-slice instruction decoder for single-cycle RV32I core.
// Pure combinational field extraction as there is no logic and format
// awareness, no decisions about what the instruction means.
// Always slices all 6 fields unconditionally; each format just
// uses the subset that's relevant to it.
module instr_decoder(input [31:0] instr,output [6:0] opcode,output [4:0] rd,output [4:0] rs1,output [4:0] rs2,output [2:0] funct3,output [6:0] funct7);

    assign opcode = instr[6:0];
    assign rd = instr[11:7];
    assign rs1 = instr[19:15];
    assign rs2 = instr[24:20];
    assign funct3 = instr[14:12];
    assign funct7 = instr[31:25];

endmodule
