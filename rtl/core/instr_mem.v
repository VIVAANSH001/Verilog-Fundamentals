// Module: instr_mem.v
// Read-only instruction memory for single-cycle RV32I core.
// Loaded at time 0 from a hex file via $readmemh.
// Word-addressed internally. byte address from PC is converted
// to a word index by dropping the bottom 2 bits.

module instr_mem (input [31:0] pc_current,output [31:0] instruction);

    // 1024x32-bit word memory thus a 4KB instruction space
    reg [31:0] mem [0:1023];

    initial begin
        $readmemh("programs/test6.hex", mem);
    end

    // gets the instruction by slicing the last 2 bits.
    assign instruction = mem[pc_current[11:2]];
endmodule
