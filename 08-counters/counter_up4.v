module counter_up4(input clk , rst , output reg [3:0] cnt);
always @ (posedge clk or posedge rst)
begin
    if(rst)
    cnt<=4'b0000;
    else
    cnt<=cnt+1'b1;
end
endmodule
