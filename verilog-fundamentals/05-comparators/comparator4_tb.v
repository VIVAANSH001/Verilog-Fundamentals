module comparator4_tb;
reg [3:0] a;
reg [3:0] b;
wire eq,gt,lt;

comparator4 uut(.a(a), .b(b), .eq(eq) , .lt(lt), .gt(gt));

initial begin

    a=4'd5; b=4'd5 ; #10 ; $display("a=%d and b=%d --> eq=%b , gt=%b , lt=%b" , a , b, eq , gt ,lt);
    a=4'd3; b=4'd7 ; #10 ; $display("a=%d and b=%d --> eq=%b , gt=%b , lt=%b" , a , b, eq , gt ,lt);
    a=4'd9; b=4'd4 ; #10 ; $display("a=%d and b=%d --> eq=%b , gt=%b , lt=%b" , a , b, eq , gt ,lt);

    
    $finish;
end

endmodule