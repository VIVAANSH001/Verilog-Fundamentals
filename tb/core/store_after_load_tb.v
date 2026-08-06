`timescale 1ns/1ps
module store_after_load_tb;

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

    always @(posedge clk)
    begin
        if (!rst)
        begin
            #1;
            if (mem_write)
            begin
                $display("cyc: MEM stage WRITE addr=%0d wdata=%0d", mem_addr, mem_wdata);
            end
            if (mem_read)
            begin
                $display("cyc: MEM stage READ  addr=%0d rdata=%0d", mem_addr, mem_rdata);
            end
        end
    end

    initial begin
        for (i = 0; i < 4096; i = i + 1)
        begin
            u_mem_interface.ram.mem[i] = 8'h00;
        end
        for (i = 0; i < 32; i = i + 1)
        begin
            uut.u_regfile.registers[i] = 32'h0;
        end

        clk = 0; rst = 1;
        @(posedge clk);
        #1;
        rst = 0;

        for (i = 0; i < 20; i = i + 1)
        begin
            @(posedge clk);
            #1;
        end

        $display("---------------------------------------------");
        $display("x3 (lw result) = %0d (expect 77, the value the sw one instruction earlier just wrote)",uut.u_regfile.registers[3]);
        $display("x4 (add x3+x0) = %0d (expect 77, confirms x3 wasn't stale)",uut.u_regfile.registers[4]);

        $finish;
    end

endmodule