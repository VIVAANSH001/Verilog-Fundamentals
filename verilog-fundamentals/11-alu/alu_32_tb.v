`timescale 1ns/1ps // new practice I am starting to let Icarus know the time units are in nano seconds
module alu_32_tb;

reg [31:0] a;
reg [31:0] b;
reg [3:0] alu_ctrl;
wire [31:0] result;
wire zero;

alu_32 uut(.a(a) , .b(b) , .alu_ctrl(alu_ctrl) , .result(result) , .zero(zero));

initial begin
    $dumpfile("alu_32.vcd");
    $dumpvars(0,alu_32_tb);

    //TESTING ADD

    a=32'd7; b=32'd2; alu_ctrl=4'd0;
    #10;
    $display("ADD: a=%d b=%d result=%d (expect 9)",a,b,result);

    //TESTING SUB AND ZERO FLAG

    a=32'd7; b=32'd7; alu_ctrl=4'd1;
    #10;
    $display("SUB: a=%d b=%d result=%d zero flag=%b (expect 0 , with zero flag being high)",a,b,result,zero);

    //TESTING AND OR XOR

    a=32'hAA; b=32'hF0; alu_ctrl=4'd2;
    #10;
    $display("AND: a=%h b=%h result=%h (expect 0xA0)",a,b,result);
    alu_ctrl=4'd3;
    #10;
    $display("OR: a=%h b=%h result=%h (expect 0xFA)",a,b,result);
    alu_ctrl=4'd4;
    #10;
    $display("XOR: a=%h b=%h result=%h (expect 0x5A)",a,b,result);

    //TESTING SLL

    a=32'd3; b=32'd2; alu_ctrl=4'd5;
    #10;
    $display("SLL: a=%d b=%d result=%d (expect 12)",a,b,result);

    //TESTING SRL

    a=32'd8; b=32'd2; alu_ctrl=4'd6;
    #10;
    $display("SRL: a=%d b=%d result=%d (expect 2)",a,b,result);

    //TESTING SLT

    a=32'hFFFFFFFF; b=32'h01; alu_ctrl=4'd7;
    #10;
    $display("SLT: a=%d b=%d result=%d (expect 1)",a,b,result);

    //TESTING SLTU

    a=32'hFFFFFFFF; b=32'h00000001; alu_ctrl=4'd8;
    #10;
    $display("SLTU: a=%d b=%d result=%d (expect 0)",a,b,result);

    //TESTING SUB WITH NON ZERO

    a=32'd7; b=32'd2; alu_ctrl=4'd1;
    #10;
    $display("SUB: a=%d b=%d result=%d zero flag=%b (expect 5 , with zero flag being low)",a,b,result,zero);

    // SRL VS SRA ON NEGATIVE NUMBER

    a=32'hFFFFFFFF; b=32'd1 ; alu_ctrl=4'd6;
    #10;
    $display("SRL: %h >> 1 = %h (expect 7fffffff)",a,result);
    alu_ctrl=4'd9;
    #10;
    $display("SRA: %h >>> 1 = %h (expect ffffffff)",a,result);

    $finish;
end

endmodule
