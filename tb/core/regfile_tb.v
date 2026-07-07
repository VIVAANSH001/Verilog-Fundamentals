`timescale 1ns/1ps
module regfile_tb;

    reg clk;
    reg we;
    reg [4:0] write_addr;
    reg [31:0] write_data;
    reg [4:0] read_addr1;
    reg [4:0] read_addr2;
    wire [31:0] read_data1;
    wire [31:0] read_data2;

    regfile uut (.clk(clk),.we(we),.write_addr(write_addr),.write_data(write_data),.read_addr1(read_addr1),.read_addr2(read_addr2),.read_data1(read_data1),.read_data2(read_data2));

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        we = 0;
        write_addr = 0;
        write_data = 0;
        read_addr1 = 0;
        read_addr2 = 0;

        // Test 1: x0 will always read 0 even with no writes
        read_addr1 = 5'd0;
        #1;
        $display("test 1 --> x0 read: read_data1=%0d (expect 0)",read_data1);

        // Test 2: basic write then read back
        @(negedge clk);
        we = 1;
        write_addr = 5'd5;
        write_data = 32'd42;
        @(posedge clk);
        #1;
        we = 0;
        read_addr1 = 5'd5;
        #1;
        $display("test 2 --> write x5=42 then read: read_data1=%0d (expect 42)",read_data1);

        // Test 3: attempt write to x0, confirm it still reads 0
        @(negedge clk);
        we = 1;
        write_addr = 5'd0;
        write_data = 32'hFFFFFFFF;
        @(posedge clk);
        #1;
        we = 0;
        read_addr1 = 5'd0;
        #1;
        $display("test 3 --> write to x0 then read: read_data1=%0d (expect 0)", read_data1);

        // Test 4: same-cycle read before writing ordering
        // x5 currently holds 42 from test 2. write 100 to x5 on this
        // edge while read_addr1 is already pointed at x5 thus read should
        // still show the OLD value (42) until after the edge lands.
        @(negedge clk);
        we = 1;
        write_addr = 5'd5;
        write_data = 32'd100;
        read_addr1 = 5'd5;
        #1; // sample read combinationally, before the posedge write commits
        $display("test 4: read x5 just before write commits: read_data1=%0d (expect 42, old value)", read_data1);
        @(posedge clk); // write commits now
        #1;
        we = 0;
        $display("test 4b --> read x5 after write commits: read_data1=%0d (expect 100)", read_data1);

        // test 5: two independent registers via both read ports
        @(negedge clk);
        we = 1;
        write_addr = 5'd10;
        write_data = 32'd7;
        @(posedge clk);
        #1;
        we = 0;
        read_addr1 = 5'd5;
        read_addr2 = 5'd10;
        #1;
        $display("test 5 --> dual port read: read_data1=%0d (expect 100), read_data2=%0d (expect 7)", read_data1, read_data2);

        $finish;
    end

endmodule
