`timescale 1ns/1ps
module mem_interface_tb;

reg clk;
reg [31:0] addr;
reg [31:0] wdata;
reg [3:0] byte_en;
reg mem_write;
reg mem_read;
wire [31:0] rdata;
integer i;

mem_interface uut(.clk(clk),.addr(addr),.wdata(wdata),.byte_en(byte_en),.mem_write(mem_write),.mem_read(mem_read),.rdata(rdata));

initial clk = 0;
always #5 clk = ~clk;

initial begin
    $dumpfile("mem_interface.vcd");
    $dumpvars(0,mem_interface_tb);

    // RAM inside the decoder powers up uninitialized, same as data_mem/regfile
    for (i = 0; i < 4096; i = i + 1)
        uut.ram.mem[i] = 8'h00;

    // TESTING RAM range write/read (addr 0 well within the range)

    addr = 32'h00000000; wdata = 32'hFFFFFFFF; byte_en = 4'b1111;
    mem_write = 1; mem_read = 0;
    #10;
    mem_write = 0; mem_read = 1;
    #10;
    $display("RAM at 0x0: rdata=%h (expect ffffffff)",rdata);

    // TESTING RAM range write/read (addr 100, still inside RAM range)

    addr = 32'h00000064; wdata = 32'h11223344; byte_en = 4'b1111;
    mem_write = 1; mem_read = 0;
    #10;
    mem_write = 0; mem_read = 1;
    #10;
    $display("RAM at 0x64: rdata=%h (expect 11223344)",rdata);

    // TESTING RAM range upper boundary (addr 0x0000_0FFC, last word in range)

    addr = 32'h00000FFC; wdata = 32'hFFFFFFFF; byte_en = 4'b1111;
    mem_write = 1; mem_read = 0;
    #10;
    mem_write = 0; mem_read = 1;
    #10;
    $display("RAM at 0xFFC (boundary): rdata=%h (expect ffffffff)",rdata);

    // TESTING first address just outside RAM range (0x0000_1000) does NOT reach RAM
    // attempt a write here, then read back address 0 to confirm RAM untouched

    addr = 32'h00001000; wdata = 32'hFFFFFFFF; byte_en = 4'b1111;
    mem_write = 1; mem_read = 0;
    #10;
    mem_write = 0; mem_read = 1;
    #10;
    $display("just outside RAM at 0x1000: rdata=%h (expect 00000000, stub)",rdata);

    addr = 32'h00000000; mem_read = 1;
    #10;
    $display("RAM at 0x0 after stray write attempt: rdata=%h (expect ffffffff, untouched)",rdata);

    // TESTING reserved MMIO range write attempt (addr 0x1000_0000)
    // should be silently ignored, read back as stub 0

    addr = 32'h10000000; wdata = 32'hAAAAAAAA; byte_en = 4'b1111;
    mem_write = 1; mem_read = 0;
    #10;
    mem_write = 0; mem_read = 1;
    #10;
    $display("MMIO at 0x10000000: rdata=%h (expect 00000000, stub)",rdata);

    // TESTING unmapped address far outside both ranges

    addr = 32'h20000000; mem_read = 1; mem_write = 0;
    #10;
    $display("unmapped at 0x20000000: rdata=%h (expect 00000000, stub)",rdata);

    $finish;
end

endmodule
