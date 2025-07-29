`timescale 1ns / 1ps


module uart(
    input clk,
    input rst,
    //tx
    input btn_start,
    input [7:0] tx_data_in,
    output tx,
    output tx_done,
    output tx_finish,
    
    //rx
    input rx,
    output rx_done,
    output [7:0] rx_data
    );

    wire w_tick,w_tx_done;
    assign tx_done = w_tx_done;
    assign tx_finish = w_tx_finish;
    uart_tx  U_UART_TX(
        .clk(clk),
        .rst(rst),
        .tick(w_tick),
        .start_trigger(btn_start),
        .data_in(tx_data_in), //기본값 : ascii code 숫자자
        .o_tx(tx),
        .tx_done(w_tx_done),
        .tx_finish(w_tx_finish)
    );
    uart_rx U_UART_RX(
        .clk(clk),
        .rst(rst),
        .tick(w_tick),
        .rx(rx),
        .rx_done(rx_done),
        .rx_data(rx_data)
    );
    baud_tick_gen U_BAUD_Tick_gen( 
        .clk(clk),
        .rst(rst),
        .baud_tick(w_tick)
    );



endmodule


module uart_tx (
    input clk,
    input rst,
    input tick,
    input start_trigger,
    input [7:0] data_in,
    output o_tx,
    output tx_done, //busy
    output tx_finish // 1tick done
);
    //fsm - state 10개
    parameter IDLE = 0;
    parameter SEND = 1;
    parameter START = 2;
    parameter DATA = 3;
    parameter STOP = 4;

    reg [2:0] state, next;
    reg tx_reg, tx_next;
    reg tx_done_reg, tx_done_next,tx_finish_reg, tx_finish_next;
    reg [3:0] tick_count_reg, tick_count_next;
    reg [2:0] bit_count_reg, bit_count_next;
    reg [7:0] temp_reg,temp_next;
    assign o_tx = tx_reg;
    assign tx_done = tx_done_reg;
    assign tx_finish = tx_finish_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state <= 0;
            tx_reg <= 1'b1;
            tx_done_reg <=0;
            tx_finish_reg <= 0;
            tick_count_reg <=0;
            bit_count_reg <=0;
            temp_reg <= 0;
        end else begin
            state <= next;
            tx_reg <= tx_next;
            tx_done_reg <= tx_done_next;
            tx_finish_reg <= tx_finish_next;
            tick_count_reg <= tick_count_next;
            bit_count_reg <= bit_count_next;
            temp_reg <= temp_next;
        end
    end

    //next

    always @(*) begin
        next = state;
        tx_next = tx_reg;
        tx_done_next = tx_done_reg;
        tx_finish_next = 0;
        tick_count_next = tick_count_reg;
        bit_count_next = bit_count_reg;
        temp_next = temp_reg;
        case (state)
            IDLE: begin
                tx_done_next = 1'b0;
                tx_finish_next = 1'b0;
                tx_next = 1'b1;
                tick_count_next = 0;
                if (start_trigger) begin
                    next = START;
                end
            end
            START: begin
                if (tick== 1'b1) begin
                    if(tick_count_reg == 15) begin
                        next = DATA;
                        temp_next = data_in;
                        bit_count_next = 0;
                        tick_count_next = 0;    
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                        tx_done_next = 1'b1;
                        tx_next = 1'b0;
                        next = START;
                    end
                end else begin
                    tx_done_next = 1'b1;
                    tx_next = 1'b0;
                    next = START;
                end
            end
            DATA : begin
                if(tick == 1'b1) begin
                    if(tick_count_reg == 15) begin
                        tick_count_next = 0;
                        if(bit_count_reg == 7) begin
                            next = STOP;
                            tx_finish_next = 1'b1;
                            tx_next = 1'b1;
                        end else begin
                            next = DATA;
                            bit_count_next = bit_count_reg + 1;
                        end
                    end else begin
                        tx_next = temp_reg[bit_count_reg]; //UART는 LSB First  
                        tick_count_next = tick_count_reg + 1;
                        next = DATA;
                    end
                end else begin
                    tx_next = temp_reg[bit_count_reg]; //UART는 LSB First
                    next = DATA;
                end
            end
            
            STOP : begin
                if (tick == 1'b1) begin
                    if(tick_count_reg == 15) begin
                        tx_next = 1'b1;
                        next = IDLE;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end else begin
                    tx_next = 1'b1;
                end
            end
        endcase
    end
endmodule

module uart_rx (
    input clk,
    input rst,
    input tick,
    input rx,
    output rx_done,
    output [7:0] rx_data
);
    parameter IDLE = 0, START = 1, DATA = 2, STOP = 3;
    reg [1:0] state, next;
    reg rx_done_reg, rx_done_next;
    reg [2:0] bit_count_reg, bit_count_next;
    reg [4:0] tick_count_reg, tick_count_next;
    reg [7:0] rx_data_reg, rx_data_next;
    assign rx_done = rx_done_reg;
    assign rx_data = rx_data_reg;

    always @(posedge clk ,posedge rst) begin
        if(rst) begin
            state <= 0;
            rx_data_reg <= 0;
            rx_done_reg <= 0;
            bit_count_reg <= 0;
            tick_count_reg <= 0;    
        end else begin
            state <= next;
            rx_data_reg <= rx_data_next;
            rx_done_reg <= rx_done_next;
            bit_count_reg <= bit_count_next;
            tick_count_reg <= tick_count_next;
        end
    end
    always @(*) begin
        next = state;
        tick_count_next = tick_count_reg;
        bit_count_next = bit_count_reg;
        rx_done_next = 1'b0;
        rx_data_next = rx_data_reg;
        case (state)
            IDLE: begin
                tick_count_next = 0;
                bit_count_next = 0;
                rx_done_next = 1'b0;
                if(rx == 1'b0) begin
                    next = START;
                end else begin
                    next = IDLE;
                end
            end
            START: begin
                if(tick == 1'b1)begin
                    if(tick_count_reg == 7) begin
                        next = DATA;
                        tick_count_next = 0; // init tick count
                    end else begin
                        tick_count_next  = tick_count_reg + 1;
                        next=START;
                    end
                end
            end
            DATA: begin
                if(tick == 1'b1) begin
                    if(tick_count_reg == 15)begin
                        rx_data_next [bit_count_reg] = rx;
                        if(bit_count_reg ==7)begin
                            next = STOP;
                            tick_count_next = 0;
                        end else begin
                            next = DATA;
                            bit_count_next = bit_count_reg + 1;
                            tick_count_next = 0;
                        end
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                        next = DATA;
                    end
                end
            end
            STOP: begin
                if(tick==1'b1)begin
                    
                    if( tick_count_reg == 23) begin
                        rx_done_next = 1'b1;
                        tick_count_next = 0;
                        next = IDLE;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                        next = STOP;
                    end
                end
            end
        endcase
    end

endmodule


module baud_tick_gen (
    input clk,
    input rst,
    output baud_tick
);
    parameter BAUD_RATE = 9600; // BAUD_RATE_19200 = 19200, ;
    localparam BAUD_COUNT =(100_000_000 / BAUD_RATE) /16;
    reg [$clog2(BAUD_COUNT) -1:0] count_reg, count_next;
    reg tick_reg, tick_next;
    // output
    assign baud_tick = tick_reg;
    
    always @(posedge clk, posedge rst) begin
        if(rst ==1) begin
            count_reg <= 0;
            tick_reg <= 0;
        end else begin
            count_reg <= count_next;
            tick_reg <= tick_next;
        end
    end

    //next
    always @(*) begin
        count_next = count_reg;
        tick_next = tick_reg;
        if (count_reg == BAUD_COUNT - 1) begin
            count_next = 0;
            tick_next = 1'b1;
        end else begin
            count_next = count_reg + 1;
            tick_next = 1'b0;
        end
    end
endmodule