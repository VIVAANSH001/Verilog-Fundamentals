// uart_mmio.v
// Day 77: register-mapped wrapper around uart_tx.v.
module uart_mmio #(parameter CLK_FREQ = 100_000_000) (input wire clk,input wire rst,input wire [2:0] reg_addr,input wire [31:0] wdata,input wire write_en,input wire read_en,output reg [31:0] rdata,output wire tx);

    localparam TX_DATA_OFFSET = 3'h0;
    localparam TX_STATUS_OFFSET = 3'h4;

    wire tx_busy;
    reg tx_start;
    reg [7:0] tx_data_latched;

    uart_tx #(.CLK_FREQ(CLK_FREQ)) u_uart_tx (.clk(clk),.reset(rst),.data(tx_data_latched),.tx_start(tx_start),.tx(tx),.busy(tx_busy));

    always @(posedge clk)
    begin
        if (rst)
        begin
            tx_start <= 1'b0;
            tx_data_latched <= 8'b0;
        end
        else
        begin
            tx_start <= (write_en && reg_addr == TX_DATA_OFFSET);
            if (write_en && reg_addr == TX_DATA_OFFSET)
            begin
                tx_data_latched <= wdata[7:0];
            end
        end
    end

    reg pending;
    always @(posedge clk)
    begin
        if (rst)
        begin
            pending <= 1'b0;
        end
        else if (write_en && reg_addr == TX_DATA_OFFSET)
        begin
            pending <= 1'b1;
        end
        else if (tx_busy)
        begin
            pending <= 1'b0;
        end
    end

    always @(*)
    begin
        if (read_en && reg_addr == TX_STATUS_OFFSET)
        begin
            rdata = {31'b0, ~(tx_busy || pending)};
        end
        else
        begin
            rdata = 32'b0;
        end
    end

endmodule