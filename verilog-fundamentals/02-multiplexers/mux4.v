module mux4( input d0,d1,d2,d3, input [1:0] sel , output y);
wire w1, w0;
mux2 m0(.a(d0),.b(d1),.sel(sel[0]),.y(w1));
mux2 m1(.a(d2),.b(d3),.sel(sel[0]),.y(w2));
mux2 m2(.a(w1),.b(w2),.sel(sel[1]),.y(y));
endmodule