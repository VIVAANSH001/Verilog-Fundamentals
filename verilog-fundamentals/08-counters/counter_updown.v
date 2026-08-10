module counter_updown(input clk , rst , up , en ,output reg [3:0] cnt);
always @ (posedge clk or posedge rst)
begin
    if(rst)
    cnt<=4'b0000;
    else
    begin
        if(en==0)
        cnt<=cnt;
        else if(en==1 && up==0)
        cnt<=cnt-1'b1;
        else if(en==1 && up==1)
        cnt<=cnt+1'b1;
        else
        cnt<=cnt;
    end
end
endmodule