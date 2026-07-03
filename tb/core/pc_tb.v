`timescale 1ns/1ps
module pc_tb;

    reg clk;
    reg rst;
    reg [31:0] pc_next;
    wire [31:0] pc_current;

    pc uut (.clk(clk),.rst(rst),.pc_next(pc_next),.pc_current(pc_current));

    always #5 clk = ~clk;
    initial begin
        $dumpfile("pc_tb.vcd");
        $dumpvars(0, pc_tb);

        // Case 1: Testing reset behavior
        clk = 0;
        rst = 1;
        pc_next = 32'hAAAA_AAAA;   //garbage to be ignored during reset

        @(posedge clk);   //sync reset happens here
        #1;               // small delay to let the update settle before checking
        if (pc_current !== 32'b0)
            $display("FAIL: reset did not drive pc_current to 0, got %h", pc_current);
        else
            $display("PASS: reset drives pc_current to 0");

        // Case 2: Normal Operation
        rst = 0;
        pc_next = 32'h0000_0004;

        //check to see PC has not changed yet
        #1;
        if (pc_current !== 32'b0)
            $display("FAIL: pc_current changed before clock edge, combinational leak, got %h", pc_current);
        else
            $display("PASS: pc_current unchanged before clock edge");

        @(posedge clk);
        #1;
        if (pc_current !== 32'h0000_0004)
            $display("FAIL: pc_current did not latch pc_next, got %h", pc_current);
        else
            $display("PASS: pc_current latched pc_next correctly");

        // Case 3: new value mid cycle
        pc_next = 32'h0000_0008;
        #1;
        if (pc_current !== 32'h0000_0004)
            $display("FAIL: pc_current updated mid-cycle without a clock edge, got %h", pc_current);
        else
            $display("PASS: pc_current holds steady mid-cycle");

        @(posedge clk);
        #1;
        if (pc_current !== 32'h0000_0008)
            $display("FAIL: pc_current did not update on this edge, got %h", pc_current);
        else
            $display("PASS: pc_current updated correctly on clock edge");

        // Case 4: Checking large border value
        pc_next = 32'hFFFF_FFFC; //last word aligned adress in a 32 bit space
        @(posedge clk);
        #1;
        if (pc_current !== 32'hFFFF_FFFC)
            $display("FAIL: pc_current did not handle max boundary value, got %h", pc_current);
        else
            $display("PASS: pc_current handles boundary value correctly");

        // Case 5: Reset mid operation
        rst = 1;
        @(posedge clk);
        #1;
        if (pc_current !== 32'b0)
            $display("FAIL: mid-operation reset did not drive pc_current to 0, got %h", pc_current);
        else
            $display("PASS: mid-operation reset works correctly");

        $display("All tests complete.");
        $finish;
    end

endmodule
