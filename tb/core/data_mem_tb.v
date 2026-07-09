`timescale 1ns/1ps
module data_mem_tb;

reg clk;
reg [11:0] addr;
reg [31:0] wdata;
reg [3:0] byte_en;
reg mem_write;
reg mem_read;
wire [31:0] rdata;
integer i;

data_mem uut(.clk(clk),.addr(addr),.wdata(wdata),.byte_en(byte_en),.mem_write(mem_write),.mem_read(mem_read),.rdata(rdata));

initial clk = 0;
always #5 clk = ~clk;

initial begin
    $dumpfile("data_mem.vcd");
    $dumpvars(0,data_mem_tb);

    // memory powers up uninitialized so you have to zero it first
    for (i = 0; i < 4096; i = i + 1)
    begin
        uut.mem[i] = 8'h00;
    end

    // TESTING SW at address 0, full byte_en

    addr = 0; wdata = 32'hAABBCCDD; byte_en = 4'b1111;
    mem_write = 1; mem_read = 0;
    #10;
    mem_write = 0; mem_read = 1;
    #10;
    $display("SW at 0: rdata=%h (expect aabbccdd)",rdata);

    // TESTING SB at address 9, lane 1 of word group 8 to 11

    addr = 9; wdata = 32'hFFFFFFFF; byte_en = 4'b0010;
    mem_write = 1; mem_read = 0;
    #10;
    mem_write = 0; mem_read = 1;
    #10;
    $display("SB at 9 so lane 1 : rdata=%h (expect 0000ff00)",rdata);

    // TESTING SH at address 10, lanes 2 to 3 of same word group
    // byte at lane 1 (from previous test) must survive untouched

    addr = 10; wdata = 32'hFFFF0000; byte_en = 4'b1100;
    mem_write = 1; mem_read = 0;
    #10;
    mem_write = 0; mem_read = 1;
    #10;
    $display("SH at 10 so lanes 2 and 3 : rdata=%h (expect ffffff00, lane 1 preserved)",rdata);

    // TESTING mem_read=0 gates rdata to 0

    addr = 0; mem_read = 0;
    #10;
    $display("mem_read=0: rdata=%h (expect 00000000)",rdata);

    // TESTING unwritten address reads back 0

    addr = 200; mem_read = 1;
    #10;
    $display("unwritten at 200 : rdata=%h (expect 00000000)",rdata);

    $finish;
end

endmodule
