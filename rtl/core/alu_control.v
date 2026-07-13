// Module: alu_control.v
// Converts control_unit.v's coarse alu_op[1:0] + instr_decoder.v's
// funct3/funct7 into the 4-bit alu_ctrl that alu_32.v expects.
// Pure combinational.
//
// funct7[5] is only trustworthy when it's legitimately encoding
// something: R-type always, I-type only for the shift ops (SLLI/
// SRLI/SRAI), since I-type SLLI's funct7 field is spec-fixed but
// I-type ADDI/ANDI/etc's "funct7" bits are just leftover immediate
// bits and mean nothing.

module alu_control(input [1:0] alu_op,input [2:0] funct3,input [6:0] funct7,input alu_src,output reg [3:0] alu_ctrl);

    localparam ADD = 4'd0;
    localparam SUB = 4'd1;
    localparam AND = 4'd2;
    localparam OR = 4'd3;
    localparam XOR = 4'd4;
    localparam SLL = 4'd5;
    localparam SRL = 4'd6;
    localparam SLT = 4'd7;
    localparam SLTU = 4'd8;
    localparam SRA = 4'd9;

    always @(*)
    begin
        case (alu_op)
            2'b00: 
            begin
                alu_ctrl = ADD;
            end

            2'b10:
            begin
                case (funct3)
                    3'b000: // ADD/SUB (R-type) or ADDI (I-type)
                    begin
                        if (!alu_src && funct7[5])
                        begin
                            alu_ctrl = SUB; 
                        end 
                        else
                        begin
                            alu_ctrl = ADD; 
                        end
                    end

                    3'b001:
                    begin
                         alu_ctrl = SLL; 
                    end

                    3'b010: 
                    begin
                        alu_ctrl = SLT;
                    end

                    3'b011: 
                    begin
                        alu_ctrl = SLTU;
                    end

                    3'b100: 
                    begin 
                        alu_ctrl = XOR;
                    end

                    3'b101: 
                    begin
                        if (funct7[5])
                        begin
                            alu_ctrl = SRA;
                        end
                        else
                        begin
                            alu_ctrl = SRL;
                        end
                    end

                    3'b110: 
                    begin
                        alu_ctrl = OR;
                    end

                    3'b111: 
                    begin
                        alu_ctrl = AND;
                    end

                    default: 
                    begin
                        alu_ctrl = ADD;
                    end
                endcase
            end

            default: 
            begin
                alu_ctrl = ADD;  // alu_op == 01 (branch) or 11 (unused, LUI bypasses ALU)
            end
        endcase
    end

endmodule