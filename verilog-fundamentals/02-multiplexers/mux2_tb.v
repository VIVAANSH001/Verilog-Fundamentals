module mux2_tb;
    reg a, b, sel;
    wire y;

    mux2 uut( .(a),.b(b),.sel(sel), .y(y)
    );

    initial begin
        sel=0; a=0; b=1; #10;
        $display("sel=%b a=%b b=%b y=%b", sel, a, b, y);
        
        sel=0; a=1; b=0; #10;
        $display("sel=%b a=%b b=%b y=%b",sel, a, b, y);
        
        sel=1; a=0; b=1; #10;
        $display("sel=%b a=%b b=%b y=%b", sel, a, b, y);
        
        sel=1; a=1; b=0; #10;
        $display("sel=%b a=%b b=%b y=%b", sel,a, b, y);
        
        $finish;
    end
endmodule