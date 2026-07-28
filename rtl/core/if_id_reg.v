// Module: if_id_reg.v
// Pipeline register between IF and ID stages.
// Latches the fetched instruction and its PC so ID can decode
// while IF moves on to the next fetch.
//
// Day 60 addition: 'stall' input. When high (load-use hazard detected),
// holds instr_out/pc_out at their current values instead of latching new
// ones in, so the consumer instruction sits still and gets re-decoded
// next cycle once the load has reached MEM.
module if_id_reg (
    input wire clk,
    input wire rst,
    input wire stall,
    input wire [31:0] instr_in,
    input wire [31:0] pc_in,
    output reg [31:0] instr_out,
    output reg [31:0] pc_out);

    always @(posedge clk) 
    begin
        if (rst) 
        begin
            instr_out <= 32'b0;
            pc_out <= 32'b0;
        end 
        else if (stall)
        begin
            instr_out <= instr_out;
            pc_out <=pc_out;
        end
        else 
        begin
            instr_out <= instr_in;
            pc_out <= pc_in;
        end
    end

endmodule