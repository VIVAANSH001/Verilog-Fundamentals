module alu (input [7:0] a , input [7:0] b , input [3:0] alu_ctrl , output reg [7:0] result , output zero);

    // encoding the operations
    localparam ADD=4'd0;
    localparam SUB=4'd1;
    localparam AND=4'd2;
    localparam OR=4'd3;
    localparam XOR=4'd4;
    localparam SLL=4'd5;
    localparam SRL=4'd6;
    localparam SLT=4'd7;
    localparam SLTU=4'd8;

    assign zero=(result==8'b0)?1'b1:1'b0;
    always @ (*)
    begin
        case (alu_ctrl)
            ADD: result=a+b;
            SUB: result=a-b;
            AND: result=a&b;
            OR: result=a|b;
            XOR: result=a^b;
            SLL: result=a<<b[2:0];
            SRL: result=a>>b[2:0];
            SLT: result=($signed(a)<$signed(b))?8'd1:8'd0;
            SLTU: result=(a<b)?8'd1:8'd0;
            default: result=8'd0;
        endcase
    end
endmodule