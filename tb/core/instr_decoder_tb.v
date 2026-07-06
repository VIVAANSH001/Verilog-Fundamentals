`timescale 1ns/1ps
module instr_decoder_tb;

    reg [31:0] instr;
    wire [6:0] opcode;
    wire [4:0] rd;
    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [2:0] funct3;
    wire [6:0] funct7;

    instr_decoder uut (.instr(instr),.opcode(opcode),.rd(rd),.rs1(rs1),.rs2(rs2),.funct3(funct3),.funct7(funct7));

    initial begin
        // Test 1: addi x1,x0,5 which is 0x00500093
        instr = 32'h00500093;
        #10;
        $display("Test1 addi x1,x0,5: opcode=%b rd=%d rs1=%d rs2=%d funct3=%b funct7=%b",opcode,rd,rs1,rs2,funct3,funct7);

        // Test 2: add x3,x1,x2 which is 0x002081b3
        instr = 32'h002081b3;
        #10;
        $display("Test2 add x3,x1,x2: opcode=%b rd=%d rs1=%d rs2=%d funct3=%b funct7=%b",opcode,rd,rs1,rs2,funct3,funct7);

        // Test 3: sub x5,x1,x2 which is 0x402082b3
        instr = 32'h402082b3;
        #10;
        $display("Test3 sub x5,x1,x2: opcode=%b rd=%d rs1=%d rs2=%d funct3=%b funct7=%b",opcode,rd,rs1,rs2,funct3,funct7);

        $finish;
    end

endmodule
