// Module: pc (Program Counter)
// Purpose:
//   Holds the current instruction address. Pure register, thus does
//   NOT decide whether the next PC is +4, a branch target, or a
//   jump target. That mux logic lives outside this module
//   (built during top-level wiring), per the strict datapath/
//   control separation rule for this project.
//
// Ports:
//   clk: system clock
//   rst: synchronous, active-high reset
//   pc_next: next PC value, driven externally by a mux
//   pc_current: current PC value, output to instruction memory
//
// Design notes:
// -->Synchronous reset (checked inside always @(posedge clk),
//    not in the sensitivity list), chosen because the
//    testbench/simulation clock is always running; no power-on
//    clock-stability problem to solve here.
// -->Resets to 32'b0 (first instruction lives at address 0).
//
// Day 60 addition: 'stall' input. When high (load-use hazard detected),
// pc_current holds its value instead of advancing to pc_next, freezing
// fetch for one cycle so the pipeline behind the load can catch up.


module pc (input wire clk,input wire rst,input wire stall,input wire [31:0] pc_next,output reg [31:0] pc_current);

    always @(posedge clk) 
    begin
        if (rst)
        begin
            pc_current <= 32'b0;
        end
        else if (stall)
        begin
            pc_current <= pc_current;
        end
        else
        begin
            pc_current <= pc_next;
        end
    end

endmodule
