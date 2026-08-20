// Day 77: Used my own UART module from internship peripherals with a few modifications.
module uart_rx #(parameter CLK_FREQ = 50_000_000) (input wire clk,input wire reset,input wire rx,input wire rx_read,output reg [7:0] data,output reg busy,output reg frame_error);
localparam IDLE = 2'b00;
localparam START = 2'b01;
localparam DATA = 2'b10;
localparam STOP= 2'b11;
localparam BAUD_RATE = 9600;
localparam BIT_PERIOD = CLK_FREQ/BAUD_RATE;
localparam HALF_PERIOD = BIT_PERIOD/2;

reg [1:0] state;
reg [19:0] baud_counter;
reg [2:0] bit_index;
reg [7:0] rx_data;

// we use 2 flip flops for synchronization as this is a asynchronous system.
reg rx_sync1, rx_sync2;
always @(posedge clk or posedge reset)
begin
    if (reset)
    begin
        rx_sync1 <= 1'b1;
        rx_sync2 <= 1'b1;
    end 
    else
    begin
        rx_sync1 <= rx;
        rx_sync2 <= rx_sync1;
    end
end
//By the end of this the rx_sync2 is 2 clock cycles behind.

always @(posedge clk or posedge reset) 
begin
    if (reset) 
    begin
        state <= IDLE;
        baud_counter <= 13'd0;
        bit_index <= 3'd0;
        rx_data <= 8'd0;
        data <= 8'd0;
        busy <= 1'b0;
        frame_error <= 1'b0;
    end 
    else 
    begin
        if (rx_read) // rx_read is the way cpu tells rx its done reading current data so any flags it raises can close
        begin
            busy <= 1'b0;
            frame_error <= 1'b0;
        end

        case (state)

            IDLE: 
            begin
                if (!rx_sync2) // is rx_sync2 is 0
                begin
                    baud_counter <= 13'd0;
                    state <= START;
                end
            end

            START: 
            begin
                if (baud_counter == HALF_PERIOD - 1) // checking if we at 0.5x offset
                begin
                    if (!rx_sync2) 
                    begin
                        baud_counter <= 13'd0;
                        bit_index <= 3'd0;
                        state <= DATA;
                    end 
                    else
                    begin
                        state <= IDLE;
                    end
                end 
                else 
                begin
                    baud_counter <= baud_counter + 1;
                end
            end

            DATA: 
            begin
                if (baud_counter == BIT_PERIOD - 1) 
                begin
                    baud_counter <= 13'd0;
                    rx_data[bit_index] <= rx_sync2;
                    if (bit_index == 3'd7) 
                    begin
                        state <= STOP;
                    end 
                    else 
                    begin
                        bit_index <= bit_index + 1;
                    end
                end 
                else 
                begin
                    baud_counter<= baud_counter + 1;
                end
            end

            STOP:
            begin
                if (baud_counter == BIT_PERIOD - 1) 
                begin
                    baud_counter <= 13'd0;

                    if (rx_sync2) // checking if its 1 meaning its a valid stop bit
                    begin
                        data <= rx_data;
                        busy <= 1'b1;
                    end 
                    else 
                    begin
                        // if the stop bit is invalid we raise a framing error
                        data <= rx_data;
                        busy <= 1'b1;
                        frame_error <= 1'b1;
                    end
                    state <= IDLE;
                end 
                else
                begin
                    baud_counter <= baud_counter + 1;
                end
            end

        endcase
    end
end

endmodule