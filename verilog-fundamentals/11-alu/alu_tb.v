module alu_tb;

reg [7:0] a;
reg [7:0] b;
reg [3:0] alu_ctrl;
wire [7:0] result;
wire zero;

alu uut(.a(a) , .b(b) , .alu_ctrl(alu_ctrl) , .result(result) , .zero(zero));

initial begin
    $dumpfile("alu.vcd");
    $dumpvars(0,alu_tb);

    //TESTING ADD

    a=8'd7; b=8'd2; alu_ctrl=4'd0;
    #10;
    $display("ADD: a=%d b=%d result=%d (expect 9)",a,b,result);

    //TESTING SUB AND ZERO FLAG

    a=8'd7; b=8'd7; alu_ctrl=4'd1;
    #10;
    $display("SUB: a=%d b=%d result=%d zero flag=%b (expect 0 , with zero flag being high)",a,b,result,zero);

    //TESTING AND OR XOR

    a=8'hAA; b=8'hF0; alu_ctrl=4'd2;
    #10;
    $display("AND: a=%h b=%h result=%h (expect 0xA0)",a,b,result);
    alu_ctrl=4'd3;
    #10;
    $display("OR: a=%h b=%h result=%h (expect 0xFA)",a,b,result);
    alu_ctrl=4'd4;
    #10;
    $display("XOR: a=%h b=%h result=%h (expect 0x5A)",a,b,result);

    //TESTING SLL

    a=8'd3; b=8'd2; alu_ctrl=4'd5;
    #10;
    $display("SLL: a=%d b=%d result=%d (expect 12)",a,b,result);

    //TESTING SRL

    a=8'd8; b=8'd2; alu_ctrl=4'd6;
    #10;
    $display("SRL: a=%d b=%d result=%d (expect 2)",a,b,result);

    //TESTING SLT

    a=8'hFF; b=8'h01; alu_ctrl=4'd7;
    #10;
    $display("SLT: a=%d b=%d result=%d (expect 1)",a,b,result);

    //TESTING SLTU

    a=8'hFF; b=8'h01; alu_ctrl=4'd8;
    #10;
    $display("SLTU: a=%d b=%d result=%d (expect 0)",a,b,result);

    //TESTING SUB WITH NON ZERO

    a=8'd7; b=8'd2; alu_ctrl=4'd1;
    #10;
    $display("SUB: a=%d b=%d result=%d zero flag=%b (expect 5 , with zero flag being low)",a,b,result,zero);

    $finish;
end

endmodule