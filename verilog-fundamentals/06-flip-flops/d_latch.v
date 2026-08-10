module d_latch(input en, input d,output reg q);

    always @(*) 
    begin
        if(en)
            q=d;
    end

endmodule