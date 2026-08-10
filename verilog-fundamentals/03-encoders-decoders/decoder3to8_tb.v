module decoder3to8_tb;
reg [2:0] in;
wire [7:0] out;

decoder3to8 uut(.in(in) , .out(out));

initial begin


    in=3'b000; #10; $display("in=%b and out=%b" , in , out);
    in=3'b001; #10; $display("in=%b and out=%b" , in , out);
    in=3'b010; #10; $display("in=%b and out=%b" , in , out);
    in=3'b011; #10; $display("in=%b and out=%b" , in , out);
    in=3'b100; #10; $display("in=%b and out=%b" , in , out);
    in=3'b101; #10; $display("in=%b and out=%b" , in , out);
    in=3'b110; #10; $display("in=%b and out=%b" , in , out);
    in=3'b111; #10; $display("in=%b and out=%b" , in , out);

    $finish;
end

endmodule