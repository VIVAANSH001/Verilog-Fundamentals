`timescale 1ns/1ps
module core_pipelined_forwarding_tb;

    reg clk, rst;
    integer i;
    wire [31:0] pc_current, instruction;
    wire [31:0] mem_addr, mem_wdata, mem_rdata;
    wire [3:0] mem_byte_en;
    wire mem_write, mem_read;

    core_pipelined uut (
        .clk(clk),
        .rst(rst),
        .instruction(instruction),
        .pc_current(pc_current),
        .mem_rdata(mem_rdata),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_byte_en(mem_byte_en),
        .mem_write(mem_write),
        .mem_read(mem_read));

    instr_mem u_instr_mem (.pc_current(pc_current),.instruction(instruction));
    mem_interface u_mem_interface (.clk(clk),.addr(mem_addr),.wdata(mem_wdata),.byte_en(mem_byte_en),.mem_write(mem_write),.mem_read(mem_read),.rdata(mem_rdata));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("core_pipelined_forwarding.vcd");
        $dumpvars(0,core_pipelined_forwarding_tb);

        // RAM powers up uninitialized, zero it first
        for (i = 0; i < 4096; i = i + 1)
        begin
            u_mem_interface.ram.mem[i] = 8'h00;
        end

        // preload mem[0] = 50 (distinct, nonzero, non-uniform value for Section D)
        u_mem_interface.ram.mem[0] = 8'h32; // 50
        u_mem_interface.ram.mem[1] = 8'h00;
        u_mem_interface.ram.mem[2] = 8'h00;
        u_mem_interface.ram.mem[3] = 8'h00;

        clk = 0; rst = 1;
        @(posedge clk);
        #1;
        rst = 0;

        // 18 instructions + pipeline fill/drain, giving generous headroom
        for (i = 0; i < 30; i = i + 1)
        begin
            @(posedge clk);
            #1;
        end

        $display("Section A: continuous forward_a chain");
        $display("x1 = %0d (expect 5)",uut.u_regfile.registers[1]);
        $display("x2 = %0d (expect 3)",uut.u_regfile.registers[2]);
        $display("x3 producer add x1+x2 = %0d (expect 8)",uut.u_regfile.registers[3]);
        $display("x4 gap=1 add x3+x2 = %0d (expect 11)",uut.u_regfile.registers[4]);
        $display("x5 gap=1 add x4+x2 = %0d (expect 14)",uut.u_regfile.registers[5]);
        $display("x6 gap=1 add x5+x2 = %0d (expect 17)",uut.u_regfile.registers[6]);

        $display("Section B: forward_a and forward_b simultaneously");
        $display("x10 = %0d (expect 100)",uut.u_regfile.registers[10]);
        $display("x11 = %0d (expect 200)",uut.u_regfile.registers[11]);
        $display("x12 add x10+x11 = %0d (expect 300, forward_a=MEM/WB forward_b=EX/MEM)",uut.u_regfile.registers[12]);

        $display("Section C: EX/MEM vs MEM/WB tie-break");
        $display("x13 (final write, E) = %0d (expect 999)",uut.u_regfile.registers[13]);
        $display("x14 add x13+x2 = %0d (expect 1002 if EX/MEM wins correctly, 53 if MEM/WB wrongly wins)",uut.u_regfile.registers[14]);

        $display("Section D: deliberate load-use failure (Day 60 territory)");
        $display("x16 (base addr) = %0d (expect 0)",uut.u_regfile.registers[16]);
        $display("x17 (lw result) = %0d (expect 50)",uut.u_regfile.registers[17]);
        $display("x18 add x17+x2 = %0d (expect 53 now that stall logic is in, was 3 on Day 59)",uut.u_regfile.registers[18]);

        $finish;
    end

endmodule