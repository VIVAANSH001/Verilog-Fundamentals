// Module: mem_interface.v
// Memory interface or address decoder for single-cycle RV32I core.
// Sits between the core's memory port and the data RAM, routing
// accesses based on address range instead of letting the core touch
// RAM directly. This is the seam peripherals plug into later.

module mem_interface (input wire clk,input wire rst,input wire [31:0] addr,input wire [31:0] wdata,input wire [3:0] byte_en,input wire mem_write,input wire mem_read,output wire [31:0] rdata);

    wire is_ram = (addr < 32'h0000_1000);
    wire is_mmio = (addr >= 32'h1000_0000);

    // Day 77: UART TX peripheral, lives at 0x1000_0000 to 0x1000_0007
    wire is_uart = (addr >= 32'h1000_0000) && (addr < 32'h1000_0008);
    wire [31:0] uart_rdata;
    wire uart_tx_pin;

    uart_mmio u_uart (.clk(clk),.rst(rst),.reg_addr(addr[2:0]),.wdata(wdata),.write_en(mem_write && is_uart),.read_en(mem_read && is_uart),.rdata(uart_rdata),.tx(uart_tx_pin));

    wire [31:0] ram_rdata;

    data_mem ram (.clk(clk),.addr(addr[11:0]),.wdata(wdata),.byte_en(byte_en),.mem_write(mem_write && is_ram),.mem_read(mem_read && is_ram),.rdata(ram_rdata));

    // route read data based on decoded region. unmapped stub to 0
    assign rdata = is_ram ? ram_rdata : is_uart ? uart_rdata : 32'b0;

endmodule