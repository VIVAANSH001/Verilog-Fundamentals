// control_unit_tb.v
`timescale 1ns/1ps
module control_unit_tb;

    reg [6:0] opcode;
    reg [2:0] funct3;

    wire reg_write, mem_read, mem_write, branch, jump, alu_src, mem_unsigned;
    wire [1:0] result_src, alu_op, mem_size;

    control_unit uut (.opcode(opcode),.funct3(funct3),.reg_write(reg_write),.mem_read(mem_read),.mem_write(mem_write),.branch(branch),.jump(jump),.alu_src(alu_src),.result_src(result_src),.alu_op(alu_op),.mem_size(mem_size),.mem_unsigned(mem_unsigned));

    initial begin
        $dumpfile("control_unit.vcd");
        $dumpvars(0,control_unit_tb);

        // R type: expect reg_write=1, alu_src=0, alu_op=10, everything else 0
        opcode = 7'b0110011; funct3 = 3'b000; #10;
        $display("R-type: rw=%b mr=%b mw=%b br=%b jp=%b as=%b rs=%b op=%b (expect 1 0 0 0 0 0 00 10)",reg_write, mem_read, mem_write, branch, jump, alu_src, result_src, alu_op);

        // I type ALU: expect reg_write=1, alu_src=1, alu_op=10
        opcode = 7'b0010011; funct3 = 3'b000; #10;
        $display("I-type: rw=%b as=%b op=%b (expect 1 1 10)", reg_write, alu_src, alu_op);

        // Load word: expect reg_write=1, mem_read=1, alu_src=1, alu_op=00, result_src=01, mem_size=10, mem_unsigned=0
        opcode = 7'b0000011; funct3 = 3'b010; #10;
        $display("LW: rw=%b mr=%b as=%b op=%b rs=%b size=%b uns=%b (expect 1 1 1 00 01 10 0)",reg_write, mem_read, alu_src, alu_op, result_src, mem_size, mem_unsigned);

        // Load byte unsigned (LBU): expect mem_size=00, mem_unsigned=1
        opcode = 7'b0000011; funct3 = 3'b100; #10;
        $display("LBU: size=%b uns=%b (expect 00 1)", mem_size, mem_unsigned);

        // Store word: expect mem_write=1, alu_src=1, alu_op=00, reg_write=0
        opcode = 7'b0100011; funct3 = 3'b010; #10;
        $display("SW: rw=%b mw=%b as=%b op=%b (expect 0 1 1 00)", reg_write, mem_write, alu_src, alu_op);

        // Branch: expect branch=1, alu_src=0, reg_write=0
        opcode = 7'b1100011; funct3 = 3'b000; #10;
        $display("BEQ: rw=%b br=%b as=%b (expect 0 1 0)",reg_write, branch, alu_src);

        // JAL: expect reg_write=1, jump=1, result_src=10
        opcode = 7'b1101111; funct3 = 3'b000; #10;
        $display("JAL: rw=%b jp=%b rs=%b (expect 1 1 10)", reg_write, jump, result_src);

        // JALR: expect reg_write=1, jump=1, alu_src=1, result_src=10
        opcode = 7'b1100111; funct3 = 3'b000; #10;
        $display("JALR: rw=%b jp=%b as=%b rs=%b (expect 1 1 1 10)", reg_write, jump, alu_src, result_src);

        // LUI: bypasses the ALU (alu_32 has no pass-through op), expect
        // reg_write=1, result_src=11 (immediate passthrough), alu_src=dont care
        opcode = 7'b0110111; funct3 = 3'b000; #10;
        $display("LUI: rw=%b rs=%b (expect 1 11)", reg_write, result_src);

        // AUIPC: expect reg_write=1, alu_src=1, alu_op=00
        opcode = 7'b0010111; funct3 = 3'b000; #10;
        $display("AUIPC: rw=%b as=%b op=%b (expect 1 1 00)",reg_write,alu_src,alu_op);

        // unmapped opcode: everything should sit at safe defaults
        opcode = 7'b1111111; funct3 = 3'b000; #10;
        $display("unmapped: rw=%b mr=%b mw=%b br=%b jp=%b (expect 0 0 0 0 0)",reg_write,mem_read,mem_write,branch,jump);

        $display("control_unit_tb done");
        $finish;
    end

endmodule
