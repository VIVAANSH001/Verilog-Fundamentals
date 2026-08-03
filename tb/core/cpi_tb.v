`timescale 1ns/1ps
// cpi_tb.v, Day 66
// CPI = cycles / instructions retired.
// read performance-notes for more and detailed info.
module cpi_tb;

    parameter RUN_CYCLES = 150; // generous headroom, safe for all 4 programs
    parameter WINDOW_START = 0;
    parameter WINDOW_END = 0;

    reg clk, rst;
    integer i, cyc;
    integer retired_count, last_valid_cyc;
    integer window_retired, window_first_valid, window_last_valid;

    wire [31:0] pc_current, instruction;
    wire [31:0] if_id_instr_out, if_id_pc_out;
    wire id_ex_reg_write_out, id_ex_mem_write_out, id_ex_branch_out, id_ex_jump_out;
    wire [31:0] mem_addr, mem_wdata, mem_rdata;
    wire [3:0] mem_byte_en;
    wire mem_write, mem_read;

    wire id_ex_valid = id_ex_reg_write_out | id_ex_mem_write_out | id_ex_branch_out | id_ex_jump_out;

    core_pipelined uut (
        .clk(clk),
        .rst(rst),
        .instruction(instruction),
        .pc_current(pc_current),
        .if_id_instr_out(if_id_instr_out),
        .if_id_pc_out(if_id_pc_out),
        .id_ex_reg_write_out(id_ex_reg_write_out),
        .id_ex_mem_write_out(id_ex_mem_write_out),
        .id_ex_branch_out(id_ex_branch_out),
        .id_ex_jump_out(id_ex_jump_out),
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
            if (id_ex_valid)
            begin
                retired_count = retired_count + 1;
                last_valid_cyc = cyc;
                if (WINDOW_END != 0 && cyc >= WINDOW_START && cyc <= WINDOW_END)
                begin
                    if (window_first_valid == -1) 
                    begin
                        window_first_valid = cyc;
                    end
                    window_last_valid = cyc;
                    window_retired = window_retired + 1;
                end
            end
            $display("cyc=%0d pc=%0d instr=%h id_ex_valid=%b",cyc,pc_current,if_id_instr_out,id_ex_valid);
            cyc = cyc + 1;
        end
    end

    initial begin
        cyc = 0;
        retired_count = 0;
        last_valid_cyc = 0;
        window_retired = 0;
        window_first_valid = -1;
        window_last_valid = 0;

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
        $display("FULL PROGRAM");
        $display("cycles=%0d instructions=%0d CPI=%f",last_valid_cyc+1,retired_count,(last_valid_cyc+1)*1.0/retired_count);

        if (WINDOW_END != 0)
        begin
            $display("WINDOW [%0d:%0d]",WINDOW_START,WINDOW_END);
            $display("cycles=%0d instructions=%0d CPI=%f",window_last_valid - window_first_valid + 1,window_retired,(window_last_valid - window_first_valid + 1)*1.0/window_retired);
        end

        $finish;
    end

endmodule