module uart_tx #(parameter CLK_FREQ = 50_000_000) (input wire clk,input wire reset,input wire [7:0] data,input wire tx_start,output reg tx,output reg busy);
localparam IDLE = 2'b00;
localparam START = 2'b01;
localparam DATA = 2'b10;
localparam STOP = 2'b11;
localparam BAUD_RATE = 9600;
localparam BIT_PERIOD = CLK_FREQ/BAUD_RATE;

reg [1:0] state;
reg [19:0] baud_counter;
reg [2:0] bit_index;
reg [7:0] tx_data; // used to latch the data you want to send

always @(posedge clk or posedge reset)
begin
    if (reset) 
    begin
        state <= IDLE;
        tx <= 1'b1;
        busy <= 1'b0;
        baud_counter <= 13'd0;
        bit_index <= 3'd0;
    end 
    else 
    begin
        case (state)

            IDLE: 
            begin
                tx <= 1'b1;
                if (tx_start) 
                begin
                    tx_data <= data;
                    busy <= 1'b1;
                    baud_counter <= 13'd0;
                    state <= START;
                end
            end

            START: 
            begin
                tx <= 1'b0;
                if (baud_counter == BIT_PERIOD - 1)
                begin
                    baud_counter <= 13'd0;
                    bit_index <= 3'd0;
                    state <= DATA;
                end 
                else 
                begin
                    baud_counter <= baud_counter + 1;
                end
            end

            DATA: 
            begin
                tx <= tx_data[bit_index];
                if (baud_counter == BIT_PERIOD - 1)
                begin
                    baud_counter <= 13'd0;
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
                    baud_counter <= baud_counter + 1;
                end
            end

            STOP: 
            begin
                tx <= 1'b1;
                if (baud_counter == BIT_PERIOD - 1)
                begin
                    baud_counter <= 13'd0;
                    busy <= 1'b0;
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