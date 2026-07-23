// core_pipelined.v
// Day 52: first structural piece of the pipelined core. IF stage only,
// pc.v feeding if_id_reg.v. core.v (Phase 3, single-cycle) is untouched
// and stays runnable as the reference to differentiate against once hazards show
// up in week 9.
module core_pipelined (
    input wire clk,
    input wire rst,
    input wire [31:0] instruction,
    output wire [31:0] pc_current,
    output wire [31:0] if_id_instr_out,
    output wire [31:0] if_id_pc_out);

    // IF stage
    reg [31:0] pc_next;
    pc u_pc (.clk(clk), .rst(rst), .pc_next(pc_next), .pc_current(pc_current));

    always @(*)
    begin
        pc_next = pc_current + 32'd4;
    end

    // IF/ID pipeline register
    if_id_reg u_if_id (
        .clk(clk),
        .rst(rst),
        .instr_in(instruction),
        .pc_in(pc_current),
        .instr_out(if_id_instr_out),
        .pc_out(if_id_pc_out));

endmodule