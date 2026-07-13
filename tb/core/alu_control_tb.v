module alu_control_tb;

    reg [1:0] alu_op;
    reg [2:0] funct3;
    reg [6:0] funct7;
    reg alu_src;
    wire [3:0] alu_ctrl;

    alu_control uut (.alu_op(alu_op),.funct3(funct3),.funct7(funct7),.alu_src(alu_src),.alu_ctrl(alu_ctrl));

    initial begin
        $dumpfile("alu_control_tb.vcd");
        $dumpvars(0,alu_control_tb);

        // alu_op = 00, address calc, funct3/funct7 should be ignored
        alu_op = 2'b00; funct3 = 3'b111; funct7 = 7'b1111111; alu_src = 1'b1;
        #10 $display("LW addr calc: alu_ctrl=%d (expect 0 ADD)",alu_ctrl);

        // R-type ADD: funct3=000, funct7=0000000, alu_src=0
        alu_op = 2'b10; funct3 = 3'b000; funct7 = 7'b0000000; alu_src = 1'b0;
        #10 $display("ADD: alu_ctrl=%d (expect 0 ADD)",alu_ctrl);

        // R-type SUB: funct3=000, funct7[5]=1, alu_src=0
        alu_op = 2'b10; funct3 = 3'b000; funct7 = 7'b0100000; alu_src = 1'b0;
        #10 $display("SUB: alu_ctrl=%d (expect 1 SUB)",alu_ctrl);

        // ADDI with garbage funct7 (imm = -1, all 1s incl bit 5): alu_src=1
        // this is the exact bug case, must not become SUB
        alu_op = 2'b10; funct3 = 3'b000; funct7 = 7'b1111111; alu_src = 1'b1;
        #10 $display("ADDI (imm=-1, fake funct7): alu_ctrl=%d (expect 0 ADD)",alu_ctrl);

        // ADDI with funct7=0 (imm=0, no ambiguity anyway): alu_src=1
        alu_op = 2'b10; funct3 = 3'b000; funct7 = 7'b0000000; alu_src = 1'b1;
        #10 $display("ADDI (imm=0): alu_ctrl=%d (expect 0 ADD)",alu_ctrl);

        // R-type SRL: funct3=101, funct7=0000000, alu_src=0
        alu_op = 2'b10; funct3 = 3'b101; funct7 = 7'b0000000; alu_src = 1'b0;
        #10 $display("SRL: alu_ctrl=%d (expect 6 SRL)",alu_ctrl);

        // R-type SRA: funct3=101, funct7[5]=1, alu_src=0
        alu_op = 2'b10; funct3 = 3'b101; funct7 = 7'b0100000; alu_src = 1'b0;
        #10 $display("SRA: alu_ctrl=%d (expect 9 SRA)",alu_ctrl);

        // I-type SRLI: funct3=101, funct7=0000000 (real, spec-fixed), alu_src=1
        alu_op = 2'b10; funct3 = 3'b101; funct7 = 7'b0000000; alu_src = 1'b1;
        #10 $display("SRLI: alu_ctrl=%d (expect 6 SRL)",alu_ctrl);

        // I-type SRAI: funct3=101, funct7[5]=1 (real, spec-fixed), alu_src=1
        alu_op = 2'b10; funct3 = 3'b101; funct7 = 7'b0100000; alu_src = 1'b1;
        #10 $display("SRAI: alu_ctrl=%d (expect 9 SRA)",alu_ctrl);

        // remaining no ambiguity ops, spot check
        alu_op = 2'b10; funct3 = 3'b001; funct7 = 7'b0000000; alu_src = 1'b0;
        #10 $display("SLL: alu_ctrl=%d (expect 5 SLL)",alu_ctrl);

        alu_op = 2'b10; funct3 = 3'b111; funct7 = 7'b0000000; alu_src = 1'b1;
        #10 $display("ANDI: alu_ctrl=%d (expect 2 AND)",alu_ctrl);

        // alu_op = 01, branch, result shouldn't matter, just don't crash
        alu_op = 2'b01; funct3 = 3'b000; funct7 = 7'b0000000; alu_src = 1'b0;
        #10 $display("BRANCH (unused): alu_ctrl=%d (don't care)", alu_ctrl);

        $finish;
    end

endmodule