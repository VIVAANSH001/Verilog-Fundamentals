// Module: mem_wb_reg.v
// Pipeline register between MEM and WB stages.
// Carries alu_result, load_data, pc, imm, rd, reg_write, and result_src.
module mem_wb_reg (
    input wire clk,
    input wire rst,
    input wire [31:0] alu_result_in,
    input wire [31:0] load_data_in,
    input wire [31:0] pc_in,
    input wire [31:0] imm_in,
    input wire [4:0] rd_in,
    input wire reg_write_in,
    input wire [1:0] result_src_in,
    output reg [31:0] alu_result_out,
    output reg [31:0] load_data_out,
    output reg [31:0] pc_out,
    output reg [31:0] imm_out,
    output reg [4:0] rd_out,
    output reg reg_write_out,
    output reg [1:0] result_src_out);

    always @(posedge clk) 
    begin
        if (rst) 
        begin
            alu_result_out <= 32'b0;
            load_data_out <= 32'b0;
            pc_out <= 32'b0;
            imm_out <= 32'b0;
            rd_out <= 5'b0;
            reg_write_out <= 1'b0;
            result_src_out <= 2'b0;
        end 
        else 
        begin
            alu_result_out <= alu_result_in;
            load_data_out <= load_data_in;
            pc_out <= pc_in;
            imm_out <= imm_in;
            rd_out <= rd_in;
            reg_write_out <= reg_write_in;
            result_src_out <= result_src_in;
        end
    end

endmodule