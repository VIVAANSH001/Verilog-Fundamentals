module tff(input clk , t, rst , output reg q);

always @(posedge clk or posedge rst)
begin
    if(rst)
    begin
        q<=0;
    end
    else
    begin
        q<=t?~q:q;
    end
end

endmodule