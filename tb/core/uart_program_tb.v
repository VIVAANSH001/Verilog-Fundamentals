`timescale 1ns/1ps
module uart_program_tb;

    reg clk, rst;
    integer i;
    wire [31:0] pc_current, instruction;
    wire [31:0] mem_addr, mem_wdata, mem_rdata;
    wire [3:0] mem_byte_en;
    wire mem_write, mem_read;

    core_pipelined uut (.clk(clk),.rst(rst),.instruction(instruction),.pc_current(pc_current),.mem_rdata(mem_rdata),.mem_addr(mem_addr),.mem_wdata(mem_wdata),.mem_byte_en(mem_byte_en),.mem_write(mem_write),.mem_read(mem_read));

    instr_mem u_instr_mem (.pc_current(pc_current),.instruction(instruction));
    mem_interface u_mem_interface (.clk(clk),.rst(rst),.addr(mem_addr),.wdata(mem_wdata),.byte_en(mem_byte_en),.mem_write(mem_write),.mem_read(mem_read),.rdata(mem_rdata));

    always #5 clk = ~clk;

    // loopback receiver watching the real tx pin, reached via hierarchical
    // path: testbench --> mem_interface --> its internal uart_mmio --> tx
    reg rx_read;
    wire [7:0] rx_data;
    wire rx_busy, rx_frame_error;

    uart_rx #(.CLK_FREQ(100_000_000)) u_rx_check (.clk(clk),.reset(rst),.rx(u_mem_interface.u_uart.tx),.rx_read(rx_read),.data(rx_data),.busy(rx_busy),.frame_error(rx_frame_error));

    // capture each byte as it arrives, clear busy immediately after so
    // the receiver is ready for the next one
    reg [7:0] captured [0:1];
    integer capture_count;

    always @(posedge clk)
    begin
        if (rst)
        begin
            rx_read <= 1'b0;
            capture_count <= 0;
        end
        else if (rx_busy && !rx_read)
        begin
            captured[capture_count] <= rx_data;
            capture_count <= capture_count + 1;
            rx_read <= 1'b1;
        end
        else
        begin
            rx_read <= 1'b0;
        end
    end

    integer timeout;

    initial begin
        for (i = 0; i < 4096; i = i + 1)
        begin
            u_mem_interface.ram.mem[i] = 8'h00;
        end
        for (i = 0; i < 32; i = i + 1)
        begin
            uut.u_regfile.registers[i] = 32'h0;
        end
        capture_count = 0;

        clk = 0; rst = 1;
        @(posedge clk);
        #1;
        rst = 0;

        // wait for the program to reach its sentinel
        timeout = 0;
        while (uut.u_regfile.registers[10] != 32'd99 && timeout < 250000)
        begin
            @(posedge clk);
            timeout = timeout + 1;
        end
        $display("program reached sentinel after %0d cycles",timeout);
        $display("x10 = %0d (expect 99)",uut.u_regfile.registers[10]);

        // give the receiver a few more cycles to finish latching the
        // second byte's stop bit + our capture logic's response
        repeat (30) @(posedge clk);

        $display("bytes received via UART loopback: count=%0d (expect 2)",capture_count);
        $display("captured[0] = %h (expect 48, 'H')",captured[0]);
        $display("captured[1] = %h (expect 49, 'I')",captured[1]);

        $finish;
    end

endmodule