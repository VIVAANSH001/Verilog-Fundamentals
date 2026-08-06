// Module: hazard_detect.v
// Day 60: load-use hazard detection.
// Pure combinational.
module hazard_detect (input wire id_ex_mem_read,input wire [4:0] id_ex_rd,input wire [4:0] if_id_rs1,input wire [4:0] if_id_rs2,input wire if_id_uses_rs1,input wire if_id_uses_rs2,output wire stall);

    assign stall = id_ex_mem_read && (id_ex_rd != 5'b0) && ((if_id_uses_rs1 && id_ex_rd == if_id_rs1) || (if_id_uses_rs2 && id_ex_rd == if_id_rs2));

endmodule