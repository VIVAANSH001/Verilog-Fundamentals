// single_cycle_cycles_tb.v, Day 69
// single-cycle core has no pipeline registers so id_ex_valid style
// retirement detection (cpi_tb.v's approach) doesn't apply. every
// cycle retires exactly one instruction by construction (CPI=1,
// architecturally). completion is instead detected by pc_current
// reaching a known address, the loop-exit landing instruction at
// the end of fib_pipeline.hex (addr right after the final nop, idx14).
`timescale 1ns/1ps
module single_cycle_cycles_tb;

    parameter RUN_CYCLES = 150;
    parameter COMPLETION_PC = 32'd60;

    reg clk, rst;
    integer i, cyc;
    integer completion_cycle;
    reg done;

    wire [31:0] pc_current, instruction;
    wire [31:0] mem_addr, mem_wdata, mem_rdata;
    wire [3:0] mem_byte_en;
    wire mem_write, mem_read;

    core uut (.clk(clk),.rst(rst),.instruction(instruction),.mem_rdata(mem_rdata),.pc_current(pc_current),.mem_addr(mem_addr),.mem_wdata(mem_wdata),.mem_byte_en(mem_byte_en),.mem_write(mem_write),.mem_read(mem_read));

    instr_mem u_instr_mem (.pc_current(pc_current),.instruction(instruction));
    mem_interface u_mem_interface (.clk(clk),.addr(mem_addr),.wdata(mem_wdata),.byte_en(mem_byte_en),.mem_write(mem_write),.mem_read(mem_read),.rdata(mem_rdata));

    always #5 clk = ~clk;

    always @(posedge clk)
    begin
        if (!rst)
        begin
            #1;
            cyc = cyc + 1;
            if (!done && pc_current == COMPLETION_PC)
            begin
                completion_cycle = cyc;
                done = 1'b1;
            end
        end
    end

    initial begin
        cyc = 0;
        completion_cycle = -1;
        done = 1'b0;

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

        for (i = 0; i < RUN_CYCLES; i = i + 1)
        begin
            @(posedge clk);
        end

        $display("---------------------------------------------");
        $display("SINGLE-CYCLE, fib_pipeline.hex");
        if (completion_cycle != -1)
        begin
            $display("cycles=%0d instructions=%0d CPI=1.000000",completion_cycle,completion_cycle);
        end
        else
        begin
            $display("did not reach completion pc=%0d within RUN_CYCLES=%0d, raise RUN_CYCLES or check COMPLETION_PC",COMPLETION_PC,RUN_CYCLES);
        end
        $display("x1 (a, fib result) = %0d (expect 55)",uut.u_regfile.registers[1]);
        $display("x2 (b, fib next term) = %0d (expect 89)",uut.u_regfile.registers[2]);

        $finish;
    end

endmodule