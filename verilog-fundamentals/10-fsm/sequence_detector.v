// A sequence detector "1101" from a serial bit stream using MEALY FSM
//When sequence is matched output goes high for one cycle

module sequence_detector(input clk , rst ,one , output reg detect);

//giving states easy names

localparam S0=2'b00; // when no detect
localparam S1=2'b01; // when we have '1'
localparam S2=2'b10; // when we have '11'
localparam S3=2'b11; // when we have '110'

reg [1:0] state , next_state;

always @ (posedge clk or posedge rst)
begin
    if(rst)
    state<=S0;
    else
    state<=next_state;
end

always @ (*)
begin
    case(state)
    S0: next_state=one?S1:S0;
    S1: next_state=one?S2:S0;
    S2: next_state=one?S2:S3;
    S3: next_state=one?S1:S0;
    default: next_state=S0;    
    endcase
end

always @ (*)
begin
    if(state==S3 && one==1)
    detect=1;
    else
    detect=0;
end


endmodule