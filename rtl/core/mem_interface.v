// Module: mem_interface.v
// Memory interface or address decoder for single-cycle RV32I core.
// Sits between the core's memory port and the data RAM, routing
// accesses based on address range instead of letting the core touch
// RAM directly. This is the seam peripherals plug into later.

module mem_interface (input wire clk,input wire [31:0] addr,input wire [31:0] wdata,input wire [3:0] byte_en,input wire mem_write,input wire mem_read,output wire [31:0] rdata);

    wire is_ram = (addr < 32'h0000_1000);
    wire is_mmio = (addr >= 32'h1000_0000); // placeholder for future MMIO peripherals (e.g. day 77 UART stretch goal), unused for now

    wire [31:0] ram_rdata;

    data_mem ram (.clk(clk),.addr(addr[11:0]),.wdata(wdata),.byte_en(byte_en),.mem_write(mem_write && is_ram),.mem_read(mem_read && is_ram),.rdata(ram_rdata));

    // route read data based on decoded region. MMIO/unmapped stub to 0
    assign rdata = is_ram ? ram_rdata : 32'b0;

endmodule
