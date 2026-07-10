`timescale 1ns/1ps
module branch_comp_tb;

    reg [31:0] rs1_data, rs2_data;
    reg [2:0] funct3;
    wire branch_taken;

    branch_comp uut (.rs1_data(rs1_data),.rs2_data(rs2_data),.funct3(funct3),.branch_taken(branch_taken));

    initial begin
        $dumpfile("branch_comp.vcd");
        $dumpvars(0,branch_comp_tb);

        // BEQ: equal (expect 1)
        rs1_data = 32'd10; rs2_data = 32'd10; funct3 = 3'b000; 
        #10;
        $display("BEQ equal: taken=%b (expect 1)",branch_taken);

        // BEQ: not equal (expect 0)
        rs1_data = 32'd10; rs2_data = 32'd11; funct3 = 3'b000; 
        #10;
        $display("BEQ not equal: taken=%b (expect 0)",branch_taken);

        // BNE: not equal (expect 1)
        rs1_data = 32'd5; rs2_data = 32'd7; funct3 = 3'b001;
        #10;
        $display("BNE not equal: taken=%b (expect 1)",branch_taken);

        // BNE: equal (expect 0)
        rs1_data = 32'd7; rs2_data = 32'd7; funct3 = 3'b001; 
        #10;
        $display("BNE equal: taken=%b (expect 0)",branch_taken);

        // BLT: signed, rs1 < rs2 (expect 1), use negative rs1
        rs1_data = -32'sd5; rs2_data = 32'd3; funct3 = 3'b100; 
        #10;
        $display("BLT (-5 < 3): taken=%b (expect 1)",branch_taken);

        // BLT: signed, rs1 > rs2 (expect 0)
        rs1_data = 32'd10; rs2_data = -32'sd5; funct3 = 3'b100; 
        #10;
        $display("BLT (10 < -5): taken=%b (expect 0)",branch_taken);

        // BGE: signed, rs1 >= rs2 (expect 1)
        rs1_data = 32'd10; rs2_data = -32'sd5; funct3 = 3'b101; 
        #10;
        $display("BGE (10 >= -5): taken=%b (expect 1)",branch_taken);

        // BGE: signed, rs1 < rs2 (expect 0)
        rs1_data = -32'sd5; rs2_data = 32'd10; funct3 = 3'b101; 
        #10;
        $display("BGE (-5 >= 10): taken=%b (expect 0)",branch_taken);

        // BLTU: unsigned, big unsigned value on rs1 (would look negative signed, expect 0 here since it's larger unsigned)
        rs1_data = 32'hFFFFFFFF; rs2_data = 32'd3; funct3 = 3'b110; 
        #10;
        $display("BLTU (0xFFFFFFFF < 3): taken=%b (expect 0)",branch_taken);

        // BLTU: unsigned, rs1 < rs2 (expect 1)
        rs1_data = 32'd2; rs2_data = 32'd3; funct3 = 3'b110; 
        #10;
        $display("BLTU (2 < 3): taken=%b (expect 1)",branch_taken);

        // BGEU: unsigned, rs1 >= rs2 (expect 1), same 0xFFFFFFFF case flipped
        rs1_data = 32'hFFFFFFFF; rs2_data = 32'd3; funct3 = 3'b111; 
        #10;
        $display("BGEU (0xFFFFFFFF >= 3): taken=%b (expect 1)",branch_taken);

        // BGEU: unsigned, rs1 < rs2 (expect 0)
        rs1_data = 32'd2; rs2_data = 32'd3; funct3 = 3'b111; 
        #10;
        $display("BGEU (2 >= 3): taken=%b (expect 0)",branch_taken);

        //default funct3 (not a branch op): expect 0, safety check
        rs1_data = 32'd1; rs2_data = 32'd1; funct3 = 3'b010; 
        #10;
        $display("invalid funct3: taken=%b (expect 0)",branch_taken);

        $display("branch_comp_tb done");
        $finish;
    end

endmodule
