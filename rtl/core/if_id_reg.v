// Module: if_id_reg.v
// Pipeline register between IF and ID stages.
// Latches the fetched instruction and its PC so ID can decode
// while IF moves on to the next fetch.
module if_id_reg (
    input wire clk,
    input wire rst,
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
        else 
        begin
            instr_out <= instr_in;
            pc_out <= pc_in;
        end
    end

endmodule