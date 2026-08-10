module mux4_tb;

reg d0,d1,d2,d3;
reg [1:0] sel;
wire y;

mux4 uut(.d0(d0), .d1(d1),.d2(d2),.d3(d3),.sel(sel) ,.y(y));

initial begin

    d0=0;d1=1;d2=0;d3=1;

    sel=2'b00; #10;
    $display(" sel=%b and y=%b (expect 0)",sel,y);
    sel=2'b01; #10;
    $display(" sel=%b and y=%b (expect 1)",sel,y);
    sel=2'b10; #10;
    $display(" sel=%b and y=%b (expect 0)",sel,y);
    sel=2'b11; #10;
    $display(" sel=%b and y=%b (expect 1)",sel,y);

    $finish;

end

endmodule