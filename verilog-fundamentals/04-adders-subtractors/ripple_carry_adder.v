module ripple_carry_adder(input [3:0] a , input [3:0] b , output [3:0] sum , output cout);
wire c1 , c2 , c3;

full_adder f0(.a(a[0]),.b(b[0]) , .cin(1'b0) , .sum(sum[0]) , .cout(c1));
full_adder f1(.a(a[1]),.b(b[1]) , .cin(c1) , .sum(sum[1]) , .cout(c2));
full_adder f2(.a(a[2]),.b(b[2]) , .cin(c2) , .sum(sum[2]) , .cout(c3));
full_adder f3(.a(a[3]),.b(b[3]) , .cin(c3) , .sum(sum[3]) , .cout(cout));

endmodule