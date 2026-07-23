// Module: id_ex_reg.v
// Pipeline register between ID and EX stages.
// Carries decoded operands, immediate, register addresses, every control signal control_unit.v produces,
// since downstream stages (EX/MEM/WB) each still need a subset of them.
module id_ex_reg (
    input wire clk,
    input wire rst,
    input wire [31:0] pc_in,
    input wire [31:0] rs1_data_in,
    input wire [31:0] rs2_data_in,
    input wire [31:0] imm_in,
    input wire [4:0] rd_in,
    input wire [4:0] rs1_in,
    input wire [4:0] rs2_in,
    input wire [2:0] funct3_in,
    input wire [6:0] funct7_in,
    input wire reg_write_in,
    input wire mem_read_in,
    input wire mem_write_in,
    input wire branch_in,
    input wire jump_in,
    input wire alu_src_in,
    input wire [1:0] result_src_in,
    input wire [1:0] alu_op_in,
    input wire [1:0] mem_size_in,
    input wire mem_unsigned_in,
    input wire alu_a_pc_in,
    output reg [31:0] pc_out,
    output reg [31:0] rs1_data_out,
    output reg [31:0] rs2_data_out,
    output reg [31:0] imm_out,
    output reg [4:0] rd_out,
    output reg [4:0] rs1_out,
    output reg [4:0] rs2_out,
    output reg [2:0] funct3_out,
    output reg [6:0] funct7_out,
    output reg reg_write_out,
    output reg mem_read_out,
    output reg mem_write_out,
    output reg branch_out,
    output reg jump_out,
    output reg alu_src_out,
    output reg [1:0] result_src_out,
    output reg [1:0] alu_op_out,
    output reg [1:0] mem_size_out,
    output reg mem_unsigned_out,
    output reg alu_a_pc_out);

    always @(posedge clk) 
    begin
        if (rst) 
        begin
            pc_out <= 32'b0;
            rs1_data_out <= 32'b0;
            rs2_data_out <= 32'b0;
            imm_out <= 32'b0;
            rd_out <= 5'b0;
            rs1_out <= 5'b0;
            rs2_out <= 5'b0;
            funct3_out <= 3'b0;
            funct7_out <= 7'b0;
            reg_write_out <= 1'b0;
            mem_read_out <= 1'b0;
            mem_write_out <= 1'b0;
            branch_out <= 1'b0;
            jump_out <= 1'b0;
            alu_src_out <= 1'b0;
            result_src_out <= 2'b0;
            alu_op_out <= 2'b0;
            mem_size_out <= 2'b0;
            mem_unsigned_out <= 1'b0;
            alu_a_pc_out <= 1'b0;
        end 
        else 
        begin
            pc_out <= pc_in;
            rs1_data_out <= rs1_data_in;
            rs2_data_out <= rs2_data_in;
            imm_out <= imm_in;
            rd_out <= rd_in;
            rs1_out <= rs1_in;
            rs2_out <= rs2_in;
            funct3_out <= funct3_in;
            funct7_out <= funct7_in;
            reg_write_out <= reg_write_in;
            mem_read_out <= mem_read_in;
            mem_write_out <= mem_write_in;
            branch_out <= branch_in;
            jump_out <= jump_in;
            alu_src_out <= alu_src_in;
            result_src_out <= result_src_in;
            alu_op_out <= alu_op_in;
            mem_size_out <= mem_size_in;
            mem_unsigned_out <= mem_unsigned_in;
            alu_a_pc_out <= alu_a_pc_in;
        end
    end

endmodule