// Module: ex_mem_reg.v
// Pipeline register between EX and MEM stages.
// Carries the ALU result, rs2_data, plus pc/imm/rd/control bits that WB still needs downstream.
module ex_mem_reg (
    input wire clk,
    input wire rst,
    input wire [31:0] alu_result_in,
    input wire [31:0] rs2_data_in,
    input wire [31:0] pc_in,
    input wire [31:0] imm_in,
    input wire [4:0] rd_in,
    input wire reg_write_in,
    input wire mem_read_in,
    input wire mem_write_in,
    input wire [1:0] result_src_in,
    input wire [1:0] mem_size_in,
    input wire mem_unsigned_in,
    output reg [31:0] alu_result_out,
    output reg [31:0] rs2_data_out,
    output reg [31:0] pc_out,
    output reg [31:0] imm_out,
    output reg [4:0] rd_out,
    output reg reg_write_out,
    output reg mem_read_out,
    output reg mem_write_out,
    output reg [1:0] result_src_out,
    output reg [1:0] mem_size_out,
    output reg mem_unsigned_out
);

    always @(posedge clk) 
    begin
        if (rst) 
        begin
            alu_result_out <= 32'b0;
            rs2_data_out <= 32'b0;
            pc_out <= 32'b0;
            imm_out <= 32'b0;
            rd_out <= 5'b0;
            reg_write_out <= 1'b0;
            mem_read_out <= 1'b0;
            mem_write_out <= 1'b0;
            result_src_out <= 2'b0;
            mem_size_out <= 2'b0;
            mem_unsigned_out <= 1'b0;
        end 
        else 
        begin
            alu_result_out <= alu_result_in;
            rs2_data_out <= rs2_data_in;
            pc_out <= pc_in;
            imm_out <= imm_in;
            rd_out <= rd_in;
            reg_write_out <= reg_write_in;
            mem_read_out <= mem_read_in;
            mem_write_out <= mem_write_in;
            result_src_out <= result_src_in;
            mem_size_out <= mem_size_in;
            mem_unsigned_out <= mem_unsigned_in;
        end
    end

endmodule