module subtractor8(input [7:0] a , input [7:0] b,output [7:0] diff , output bout);
ripplecarry8 r1(.a(a), .b(~b) , .cin(1'b1) , .sum(diff) , .cout(bout));
endmodule