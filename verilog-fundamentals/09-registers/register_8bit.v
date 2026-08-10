module register_8bit(input clk , rst , load ,input [7:0] d , output reg [7:0] q);

always @ ( posedge clk or posedge rst)
begin
    if(rst)
    q<=8'b00000000;
    else
    begin
        if(load)
        q<=d;
    end 
end

endmodule