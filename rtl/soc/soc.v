// soc.v
// Top-level system: core + instruction memory + memory interface (RAM/MMIO
// decoder) + data RAM.

module soc (input wire clk,input wire rst); // top level so doesnt need any other inputs/outputs

    wire [31:0] pc_current, instruction;
    wire [31:0] mem_addr, mem_wdata, mem_rdata;
    wire [3:0] mem_byte_en;
    wire mem_write, mem_read;

    core u_core (.clk(clk),.rst(rst),.instruction(instruction),.mem_rdata(mem_rdata),.pc_current(pc_current),.mem_addr(mem_addr),.mem_wdata(mem_wdata),.mem_byte_en(mem_byte_en),.mem_write(mem_write),.mem_read(mem_read));

    instr_mem u_instr_mem (.pc_current(pc_current),.instruction(instruction));

    mem_interface u_mem_interface (.clk(clk),.addr(mem_addr),.wdata(mem_wdata),.byte_en(mem_byte_en),.mem_write(mem_write),.mem_read(mem_read),.rdata(mem_rdata));

endmodule