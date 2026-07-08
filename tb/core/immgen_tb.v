`timescale 1ns/1ps
module immgen_tb;

reg [31:0] instr;
wire [31:0] imm;

immgen uut(.instr(instr),.imm(imm));

initial begin
    $dumpfile("immgen.vcd");
    $dumpvars(0,immgen_tb);

    // TESTING I TYPE (ADDI x1, x0, 5) with positive imm

    instr = 32'b000000000101_00000_000_00001_0010011;
    #10;
    $display("I type ADDI: imm=%d (expect 5)",$signed(imm));

    // TESTING I TYPE (ADDI x1, x0, -5) with negative imm, sign extension check

    instr = 32'b111111111011_00000_000_00001_0010011;
    #10;
    $display("I type ADDI: imm=%d (expect -5)",$signed(imm));

    // TESTING I TYPE (JALR) meaning different opcode, same slicing

    instr = 32'b111111111100_00001_000_00010_1100111;
    #10;
    $display("I type JALR: imm=%d (expect -4)",$signed(imm));

    // TESTING S TYPE (SW x2, 8(x3)) with positive imm

    instr = 32'b0000000_00010_00011_010_01000_0100011;
    #10;
    $display("S type SW: imm=%d (expect 8)",$signed(imm));

    // TESTING S TYPE (SW x2, -8(x3)) with negative imm

    instr = 32'b1111111_00010_00011_010_11000_0100011;
    #10;
    $display("S type SW: imm=%d (expect -8)",$signed(imm));

    // TESTING B TYPE (BEQ x1, x2, +16) meaning positive, bit-scrambled

    instr = 32'b0_000000_00010_00001_000_1000_0_1100011;
    #10;
    $display("B type BEQ: imm=%d (expect 16)",$signed(imm));

    // TESTING B TYPE (BEQ x1, x2, -16) meaning negative, bit-scrambled

    instr = 32'b1_111111_00010_00001_000_1000_1_1100011;
    #10;
    $display("B type BEQ: imm=%d (expect -16)",$signed(imm));

    // TESTING U TYPE (LUI x5, 0x12345)

    instr = 32'b00010010001101000101_00101_0110111;
    #10;
    $display("U type LUI: imm=%h (expect 12345000)",imm);

    // TESTING U TYPE (AUIPC x5, 0xFFFFF) so all 1s upper bits

    instr = 32'b11111111111111111111_00101_0010111;
    #10;
    $display("U type AUIPC: imm=%h (expect fffff000)",imm);

    // TESTING J TYPE (JAL x1, +2048) meaning positive, bit-scrambled

    instr = 32'b0_0000000000_1_00000000_00001_1101111;
    #10;
    $display("J type JAL: imm=%d (expect 2048)",$signed(imm));

    // TESTING J TYPE (JAL x1, -2048) meaning negative, bit-scrambled

    instr = 32'b1_0000000000_1_11111111_00001_1101111;
    #10;
    $display("J type JAL: imm=%d (expect -2048)",$signed(imm));

    // TESTING R TYPE (ADD x1, x2, x3) this is the default case, no immediate

    instr = 32'b0000000_00011_00010_000_00001_0110011;
    #10;
    $display("R type ADD: imm=%d (expect 0)",$signed(imm));

    $finish;
end

endmodule