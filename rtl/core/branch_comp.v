// branch_comp.v
// standalone branch comparator: takes rs1/rs2 values + funct3 (branch type
// encoding), outputs whether the branch is taken. lives outside the ALU on
// purpose (Day 37 plan calls for dedicated hardware, not reusing the ALU).
module branch_comp (input [31:0] rs1_data,input [31:0] rs2_data,input [2:0] funct3,output reg branch_taken);

    always @(*) 
    begin
        case (funct3)
            3'b000: 
            begin
                branch_taken = (rs1_data == rs2_data); // BEQ
            end
            3'b001:
            begin
                branch_taken = (rs1_data != rs2_data);// BNE                
            end
            3'b100:
            begin
                branch_taken = ($signed(rs1_data) <  $signed(rs2_data)); // BLT                
            end 
            3'b101:
            begin
                branch_taken = ($signed(rs1_data) >= $signed(rs2_data));// BGE                
            end 
            3'b110: 
            begin
                branch_taken = (rs1_data <  rs2_data); // BLTU
            end
            3'b111:
            begin
                branch_taken = (rs1_data >= rs2_data); // BGEU
            end
            default:
            begin
                branch_taken = 1'b0; // not a branch funct3
            end
        endcase
    end

endmodule
