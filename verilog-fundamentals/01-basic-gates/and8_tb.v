module and8_tb;
    reg [7:0] a, b;
    wire [7:0] y;

    and8 uut(.a(a) ,.b(b), .y(y));

    initial begin
        a=8'b11001010; b=8'b10110011; #10;
        $display("a=%b b=%b y=%b",a,b,y);

        a=8'b11111111; b=8'b00000000; #10;
        $display("a=%b b=%b y=%b",a,b,y);

        a=8'b11111111; b=8'b11111111; #10;
        $display("a=%b b=%b y=%b",a,b,y);

        a=8'b10101010; b=8'b01010101; #10;
        $display("a=%b b=%b y=%b",a,b,y);

        $finish;
    end
endmodule