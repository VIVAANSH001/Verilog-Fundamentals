// Module: regfile.v
// 32x32-bit register file for single-cycle RV32I core.
// 2 async read ports, 1 sync write port, x0 hardwired to zero
module regfile (input clk,input we,input [4:0] write_addr,input [31:0] write_data,input [4:0] read_addr1,input [4:0] read_addr2,output [31:0] read_data1,output [31:0] read_data2);

    reg [31:0] registers [0:31];
    
    // sync write always
    always @(posedge clk) 
    begin
        if (we == 1'b1)
        begin
            registers[write_addr] <= write_data;
        end
    end
    // read is async to allow single cycle
    assign read_data1 = (read_addr1 == 5'b00000) ? 32'b0 : registers[read_addr1];
    assign read_data2 = (read_addr2 == 5'b00000) ? 32'b0 : registers[read_addr2];

endmodule
