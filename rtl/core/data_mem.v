// Module: data_mem.v
// Byte-addressed data memory (4KB) for single-cycle RV32I core.
// Supports byte, half-word, and word reads/writes via a memory interface.
// Writes are clocked and masked per-byte via byte_en so sb/sh/sw
// only touch the intended byte lanes within a word group.
// Reads are combinational and always return the full aligned word

module data_mem (input wire clk,input wire [11:0] addr,input wire [31:0] wdata,input wire [3:0] byte_en,input wire mem_write,input wire mem_read,output wire [31:0] rdata);

    // 4096 bytes can be stored here so thats 4KB
    reg [7:0] mem [0:4095];

    // word-aligned base for the current address
    wire [11:0] base = {addr[11:2], 2'b00};
    
    // sync write
    always @(posedge clk)
    begin
        if (mem_write) 
        begin
            if (byte_en[0])
            begin
                mem[base] <= wdata[7:0];
            end
            if (byte_en[1])
            begin
                mem[base+1] <= wdata[15:8];                
            end
            if (byte_en[2])
            begin
                mem[base+2] <= wdata[23:16];                
            end
            if (byte_en[3]) 
            begin
                mem[base+3] <= wdata[31:24];
            end
        end
    end

    //async read just like the regfile
    assign rdata = mem_read ? {mem[base+3], mem[base+2], mem[base+1], mem[base]} : 32'b0;

endmodule
