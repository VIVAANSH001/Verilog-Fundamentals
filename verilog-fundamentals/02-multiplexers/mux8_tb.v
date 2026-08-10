module mux8_tb;
reg d0,d1,d2,d3,d4,d5,d6,d7;
reg [2:0] sel;
wire y;

mux8 uut(.d0(d0), .d1(d1),.d2(d2),.d3(d3),.d4(d4),.d5(d5),.d6(d6),.d7(d7),.sel(sel),.y(y));
initial begin
    d0=0;d1=1;d2=0;d3=1;d4=0;d5=1;d6=0;d7=1;

    sel=3'b000; #10; $display("sel=%b and y=%b (expected 0)",sel,y);
    sel=3'b001; #10; $display("sel=%b and y=%b (expected 1)",sel,y);
    sel=3'b010; #10; $display("sel=%b and y=%b (expected 0)",sel,y);
    sel=3'b011; #10; $display("sel=%b and y=%b (expected 1)",sel,y);
    sel=3'b100; #10; $display("sel=%b and y=%b (expected 0)",sel,y);
    sel=3'b101; #10; $display("sel=%b and y=%b (expected 1)",sel,y);
    sel=3'b110; #10; $display("sel=%b and y=%b (expeccted 0)",sel,y);
    sel=3'b111; #10; $display("sel=%b and y=%b (expected 1)",sel,y);

    $finish;
end
endmodule