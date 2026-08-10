module ripple_carry_adder_tb;

reg [3:0] a, b;
wire [3:0] sum;
wire cout;

ripple_carry_adder uut(.a(a), .b(b), .sum(sum) , .cout(cout));

initial begin
    a=4'b0000; b=4'b0000; #10; $display("a=%b b=%b sum=%b cout=%b", a, b, sum, cout);
    a=4'b0001; b=4'b0001; #10; $display("a=%b b=%b sum=%b cout=%b", a, b, sum, cout);
    a=4'b0101; b=4'b0011; #10; $display("a=%b b=%b sum=%b cout=%b", a, b, sum, cout);
    a=4'b1111; b=4'b0001; #10; $display("a=%b b=%b sum=%b cout=%b", a, b, sum, cout);
    a=4'b1111; b=4'b1111; #10; $display("a=%b b=%b sum=%b cout=%b", a, b, sum, cout);
    a=4'b1010; b=4'b0101; #10; $display("a=%b b=%b sum=%b cout=%b", a, b, sum, cout);

    $finish;
end

endmodule