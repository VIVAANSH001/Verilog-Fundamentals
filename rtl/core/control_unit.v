// control_unit.v
// main decoder. pure combinational, opcode(+funct3 for mem size) in,
// control signals out. no RAM/MMIO awareness: mem_read/mem_write/mem_size
// are generic signals that flow into the memory interface (mem_interface.v),
// which is the only thing that knows about the address map. this module
// doesn't know or care what's on the other side of the memory port.
module control_unit (input [6:0] opcode,input [2:0] funct3,output reg reg_write,output reg mem_read,output reg mem_write,output reg branch,output reg jump,output reg alu_src,output reg [1:0] result_src,output reg [1:0] alu_op,output reg [1:0] mem_size,output reg mem_unsigned);

    localparam OP_RTYPE = 7'b0110011;
    localparam OP_ITYPE = 7'b0010011;
    localparam OP_LOAD = 7'b0000011;
    localparam OP_STORE = 7'b0100011;
    localparam OP_BRANCH = 7'b1100011;
    localparam OP_JAL = 7'b1101111;
    localparam OP_JALR = 7'b1100111;
    localparam OP_LUI = 7'b0110111;
    localparam OP_AUIPC = 7'b0010111;

    always @(*) 
    begin
        // safe defaults, unmapped opcode does nothing
        reg_write = 1'b0;
        mem_read = 1'b0;
        mem_write = 1'b0;
        branch = 1'b0;
        jump = 1'b0;
        alu_src = 1'b0;
        result_src = 2'b00;
        alu_op = 2'b00;
        mem_size = funct3[1:0];  // only meaningful for load/store opcodes
        mem_unsigned = funct3[2];    // only meaningful for load opcode

        case (opcode)
            OP_RTYPE: 
            begin
                reg_write = 1'b1;
                alu_op = 2'b10; 
            end

            OP_ITYPE: 
            begin
                reg_write = 1'b1;
                alu_src= 1'b1;
                alu_op = 2'b10;
            end

            OP_LOAD: 
            begin
                reg_write = 1'b1;
                mem_read = 1'b1;
                alu_src = 1'b1;
                alu_op = 2'b00;
                result_src = 2'b01;
            end

            OP_STORE:
            begin
                mem_write = 1'b1;
                alu_src = 1'b1;
                alu_op = 2'b00; 
            end

            OP_BRANCH: 
            begin
                branch = 1'b1;
                alu_op = 2'b01;
            end

            OP_JAL: 
            begin
                reg_write = 1'b1;
                jump = 1'b1;
                result_src = 2'b10;
            end

            OP_JALR: 
            begin
                reg_write = 1'b1;
                jump = 1'b1;
                alu_src = 1'b1;
                alu_op = 2'b00; 
                result_src = 2'b10; 
            end

            OP_LUI: 
            begin
                reg_write = 1'b1;
                result_src = 2'b11; // immediate passthrough, bypasses ALU
            end

            OP_AUIPC: 
            begin
                reg_write = 1'b1;
                alu_src = 1'b1;
                alu_op = 2'b00;
            end

            default: 
            begin
                // unmapped opcode, everything stays at the safe defaults above
            end
        endcase
    end

endmodule
