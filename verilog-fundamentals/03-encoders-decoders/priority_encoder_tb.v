module priority_encoder_tb;

reg [7:0] in;
wire valid;
wire [2:0] out;

priority_encoder uut(.in(in), .out(out),.valid(valid));

initial begin

    in=8'b10101011; #10 ; $display("in=%b and out=%b and valid=%b", in, out, valid);
    in=8'b00101011; #10 ; $display("in=%b and out=%b and valid=%b", in, out, valid);
    in=8'b00001011; #10 ; $display("in=%b and out=%b and valid=%b", in, out, valid);
    in=8'b00000011; #10 ; $display("in=%b and out=%b and valid=%b", in, out, valid);
    in=8'b00000001; #10 ; $display("in=%b and out=%b and valid=%b", in, out, valid);
    in=8'b00000000; #10 ; $display("in=%b and out=%b and valid=%b", in, out, valid);
    $finish;
end
endmodule