`timescale 1ns/1ps
module uart_mmio_tb;

    localparam CLK_FREQ = 100_000_000; // matches this project's sim clock which is #5 half period = 100MHz

    reg clk, rst;
    reg [2:0] reg_addr;
    reg [31:0] wdata;
    reg write_en, read_en;
    wire [31:0] rdata;
    wire tx;

    uart_mmio #(.CLK_FREQ(CLK_FREQ)) uut (.clk(clk),.rst(rst),.reg_addr(reg_addr),.wdata(wdata),.write_en(write_en),.read_en(read_en),.rdata(rdata),.tx(tx));

    // independent receiver
    wire [7:0] rx_data;
    wire rx_busy;
    wire rx_frame_error;
    reg rx_read;

    uart_rx #(.CLK_FREQ(CLK_FREQ)) u_rx_check (.clk(clk),.reset(rst),.rx(tx),.rx_read(rx_read),.data(rx_data),.busy(rx_busy),.frame_error(rx_frame_error));

    always #5 clk = ~clk; //100MHz

    integer timeout;

    initial begin
        $dumpfile("uart_mmio.vcd");
        $dumpvars(0,uart_mmio_tb);

        clk = 0; 
        rst = 1;
        reg_addr = 3'h0; 
        wdata = 32'h0; 
        write_en = 0; 
        read_en = 0; 
        rx_read = 0;
        @(posedge clk); 
        #1;
        rst = 0;

        // TX_STATUS before anything is sent
        reg_addr = 3'h4;
        read_en = 1;
        #1;
        $display("TX_STATUS before send: rdata=%0d (expect 1, ready)",rdata);
        read_en = 0;

        // write 0x41 or 'A' to TX_DATA
        @(posedge clk); 
        #1;
        reg_addr = 3'h0; 
        wdata = 32'h00000041; 
        write_en = 1;
        @(posedge clk); 
        #1;
        write_en = 0;

        // wait for busy to actually assert, ready read immediately
        // after the write would still (wrongly) show ready=1
        timeout = 0;
        reg_addr = 3'h4; 
        read_en = 1;
        while (rdata != 32'd0 && timeout < 50)
        begin
            @(posedge clk); 
            #1;
            timeout = timeout + 1;
        end
        $display("TX_STATUS dropped to busy after %0d cycles (expect small, around 2)",timeout);

        // now wait for ready again, transmission actually complete
        timeout = 0;
        while (rdata != 32'd1 && timeout < 200000)
        begin
            @(posedge clk); 
            #1;
            timeout = timeout + 1;
        end
        read_en = 0;
        $display("TX_STATUS ready again after further %0d cycles (expect around 104160, 10 bit periods at 9600 baud/100MHz)",timeout);

        // give the loopback receiver a few cycles to latch its result
        repeat (20) @(posedge clk);
        #1;
        $display("rx_data = %h (expect 41)",rx_data);
        $display("rx_busy = %b (expect 1, byte received and waiting to be read)",rx_busy);
        $display("rx_frame_error = %b (expect 0, valid stop bit)",rx_frame_error);

        rx_read = 1;
        @(posedge clk); 
        #1;
        rx_read = 0;
        $display("rx_busy after rx_read pulse = %b (expect 0, cleared)",rx_busy);

        $finish;
    end

endmodule