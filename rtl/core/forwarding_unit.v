// Module: forwarding_unit.v
// Day 58: compares register addresses (not values) between the EX stage's
// current source regs and the two stages ahead of it (EX/MEM, MEM/WB) that
// might still be holding a pending write for those same regs. Outputs a
// select code per operand so the EX stage can mux in the right value.
// EX/MEM checked first so it wins ties against MEM/WB (more recent value).
module forwarding_unit (
    input wire [4:0] id_ex_rs1,
    input wire [4:0] id_ex_rs2,
    input wire [4:0] ex_mem_rd,
    input wire ex_mem_reg_write,
    input wire [4:0] mem_wb_rd,
    input wire mem_wb_reg_write,
    output reg [1:0] forward_a,
    output reg [1:0] forward_b);

    localparam NO_FWD = 2'b00;
    localparam FWD_EX_MEM = 2'b01;
    localparam FWD_MEM_WB = 2'b10;

    always @(*)
    begin
        // operand A (rs1)
        if (ex_mem_reg_write && (ex_mem_rd != 5'b0) && (ex_mem_rd == id_ex_rs1))
        begin
            forward_a = FWD_EX_MEM;
        end
        else if (mem_wb_reg_write && (mem_wb_rd != 5'b0) && (mem_wb_rd == id_ex_rs1))
        begin
            forward_a = FWD_MEM_WB;
        end
        else
        begin
            forward_a = NO_FWD;
        end

        // operand B (rs2)
        if (ex_mem_reg_write && (ex_mem_rd != 5'b0) && (ex_mem_rd == id_ex_rs2))
        begin
            forward_b = FWD_EX_MEM;
        end
        else if (mem_wb_reg_write && (mem_wb_rd != 5'b0) && (mem_wb_rd == id_ex_rs2))
        begin
            forward_b = FWD_MEM_WB;
        end
        else
        begin
            forward_b = NO_FWD;
        end
    end

endmodule