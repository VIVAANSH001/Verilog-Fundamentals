module subtractor8_tb;
    reg [7:0] a, b;
    wire [7:0] diff;
    wire bout;

    subtractor8 uut(.a(a) , .b(b), .diff(diff), .bout(bout));

    initial begin
        a=8'd20;  b=8'd10;  #10; $display("a=%0d b=%0d diff=%0d bout=%b",a, b, diff, bout);
        a=8'd100; b=8'd50;  #10; $display("a=%0d b=%0d diff=%0d bout=%b",a, b, diff, bout);
        a=8'd10;  b=8'd10;  #10; $display("a=%0d b=%0d diff=%0d bout=%b",a, b, diff, bout);
        a=8'd5;   b=8'd20;  #10; $display("a=%0d b=%0d diff=%0d bout=%b",a, b, diff, bout);
        a=8'd255; b=8'd1;   #10; $display("a=%0d b=%0d diff=%0d bout=%b",a, b, diff, bout);

        $finish;
    end
endmodule