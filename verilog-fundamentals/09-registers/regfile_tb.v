module regfile_tb;
    reg clk,we;
    reg [2:0] write_addr,read_addr1,read_addr2;
    reg [7:0] write_data;
    wire [7:0] read_data1,read_data2;

    regfile uut(.clk(clk),.we(we),.write_addr(write_addr),.write_data(write_data),.read_addr1(read_addr1),.read_addr2(read_addr2),.read_data1(read_data1),.read_data2(read_data2));

    initial clk=0;

    always #5 clk=~clk;

    initial begin
        $dumpfile("regfile.vcd");
        $dumpvars(0,regfile_tb);

        //write disabled thus nothing should change
        we=0; write_addr=3'd1; write_data=8'hAA;
        read_addr1=3'd1; read_addr2=3'd2;
        #10;
        $display("we=0 write r1=AA : r1=%h r2=%h (expect xx xx, uninitialised)",read_data1,read_data2);

        //write 0xAB to the first register
        we=1; write_addr=3'd1; write_data=8'hAB;
        #10;
        $display("we=1 write r1=AB : r1=%h (expect ab)",read_data1);

        //write 0x37 to the second register
        write_addr=3'd2; write_data=8'h37;
        #10;
        $display("we=1 write r2=37 : r2=%h (expect 37)",read_data2);

        //read both together
        we=0;
        read_addr1=3'd1; read_addr2=3'd2;
        #10;
        $display("read r1 and r2 : r1=%h r2=%h (expect ab 37)",read_data1,read_data2);

        //checking if read is truely asynchronous
        read_addr1=3'd2;
        #2;
        $display("async read r2 mid-cycle : r1=%h (expect 37, no clock needed)",read_data1);

        //writing to register 0 should not change the value
        we=1; write_addr=3'd0; write_data=8'hFF;
        #10;
        read_addr1=3'd0;
        #2;
        $display("write FF to r0 : r0=%h (expect 00, hardwired)",read_data1);

        //write to register 7
        write_addr=3'd7; write_data=8'hCC;
        #10;
        read_addr1=3'd7;
        #2;
        $display("write r7=CC : r7=%h (expect cc)",read_data1);

        $finish;
    end
endmodule