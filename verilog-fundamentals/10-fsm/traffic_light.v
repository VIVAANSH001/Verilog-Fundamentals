// Building a Moore FSM traffic light
// RED:10 CYCLES , GREEN:8 CYCLES , YELLOW:3 CYCLES

module traffic_light(input clk , rst , output reg red , green ,yellow);

// making readable states

localparam RED=2'b00;
localparam GREEN=2'b01;
localparam YELLOW=2'b10;

reg [3:0] count , next_count;
reg [1:0] state, next_state;

always @ (posedge clk or posedge rst)
begin
    if(rst)
    begin
        state<=RED;
        count<=9; 
    end
    else
    begin
        if(count==0)
        begin
            state<=next_state;
            count<=next_count;
        end
        else
        count<=count-1;
    end
end

always @ (*)
begin
    case(state)
    RED:
    begin
        next_state=GREEN;
        next_count=7;
    end
    GREEN:
    begin 
        next_state=YELLOW;
        next_count=2;
    end
    YELLOW:
    begin
        next_state=RED;
        next_count=9;
    end
    default:  // for safety reasons the default should always be red
    begin
        next_state=RED;
        next_count=9;
    end
    endcase
end

always @ (*)
begin
    red=0; green=0; yellow=0; //default value
    case(state)
    RED: red=1;
    YELLOW: yellow=1;
    GREEN: green=1;
    endcase
end

endmodule