// 8-register file, 2 async read ports, 1 sync write port
// register 0 hardwired to 0

module regfile(input clk , we , input [2:0] write_addr , input [7:0] write_data , input [2:0] read_addr1 ,input [2:0] read_addr2, output [7:0] read_data1 , output [7:0] read_data2 );
// we is write enable

reg [7:0] registers [0:7]; // 8 registers who are 8 bits wide (is kinda a 2d array)

//sync write
always @ (posedge clk)
begin
    if(we==1'b1 && write_addr!=3'b000)
    registers[write_addr]<=write_data;
end

//async read : purely combinational for efficiency

assign read_data1=(read_addr1==3'b000)?8'b0:registers[read_addr1];
assign read_data2=(read_addr2==3'b000)?8'b0:registers[read_addr2];


endmodule
