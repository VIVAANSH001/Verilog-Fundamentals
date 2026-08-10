module vectors_practice;

    reg [7:0] a;    
    reg [7:0] b;      
    wire [7:0] y_and; 
    
    assign y_and=a&b;
    
    initial begin
        a=8'b11001010;
        b=8'b10110011;
        #10;
        $display("a = %b", a);
        $display("b = %b", b);
        $display("a & b = %b", y_and);

        $display("top 4 bits of a = %b", a[7:4]); 
        $display("bottom 4 bits of a = %b", a[3:0]);

        $display("bit 3 of a =%b", a[3]);
        $display("b and a joined = %b", {b, a});
        $finish;
    end

endmodule