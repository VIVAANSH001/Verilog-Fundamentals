module instr_mem_tb;

    reg [31:0] pc_current;
    wire [31:0] instruction;

    instr_mem uut (.pc_current(pc_current),.instruction(instruction));

    initial begin
        $display("--- instr_mem testbench start ---");

        // Test 1:pc=0 thus it should fetch mem[0] = addi x1,x0,5
        pc_current = 32'h00000000;
        #10;
        $display("pc=%0d instruction=%h",pc_current,instruction);
        if (instruction !== 32'h00500093)
            $display("FAIL: expected 00500093, got %h",instruction);
        else
            $display("PASS");

        // Test 2: pc=4 thus is should fetch mem[1] = addi x2,x0,10
        pc_current = 32'h00000004;
        #10;
        $display("pc=%0d instruction=%h",pc_current,instruction);
        if (instruction !== 32'h00a00113)
            $display("FAIL: expected 00a00113, got %h",instruction);
        else
            $display("PASS");

        // Test 3: pc=8 thus it should fetch mem[2]= addi x3,x0,15
        pc_current = 32'h00000008;
        #10;
        $display("pc=%0d instruction=%h",pc_current,instruction);
        if (instruction !== 32'h00f00193)
            $display("FAIL: expected 00f00193, got %h",instruction);
        else
            $display("PASS");

        $display("--- instr_mem testbench end ---");
        $finish;
    end

endmodule
