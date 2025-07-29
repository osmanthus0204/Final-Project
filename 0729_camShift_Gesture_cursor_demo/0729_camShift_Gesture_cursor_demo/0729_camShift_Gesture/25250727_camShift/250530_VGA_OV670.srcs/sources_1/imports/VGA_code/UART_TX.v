`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/21 10:43:53
// Design Name: 
// Module Name: UART_TX
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module UART_TX(
    input clk,
    input rst,
    input tick,
    input start_trigger,
    input [7:0] data_in,
    output o_tx, o_tx_done
);

    parameter IDLE = 0, SEND = 1, START = 2, D = 3,
              STOP = 4;


    reg tx_reg, tx_next, tx_done_reg, tx_done_next;
    reg [2:0] bit_cnt_reg, bit_cnt_next;
    reg [3:0] state, next;  
    reg [3:0] tick_cnt_reg, tick_cnt_next ;


    // tx data in buffer
    reg[7:0] temp_data_reg, temp_data_next;

    assign o_tx = tx_reg;
    assign o_tx_done = tx_done_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state <= 0;
            tx_reg <= 1'b1; // 초기값
            tx_done_reg <= 0;
            bit_cnt_reg <= 0;
            tick_cnt_reg <= 0;
            temp_data_reg <=0;
        end
        else begin
            state <= next;
            tx_reg <= tx_next;
            tx_done_reg <= tx_done_next;
//            cnt_reg <= cnt_next;
            bit_cnt_reg <= bit_cnt_next;
            tick_cnt_reg <= tick_cnt_next;
            temp_data_reg <= temp_data_next;
        end
    end

    //next

    always @(*) begin
        next = state;
        tx_next = tx_reg;
        tx_done_next = tx_done_reg;
        bit_cnt_next = bit_cnt_reg;
        tick_cnt_next = tick_cnt_reg;
        temp_data_next = temp_data_reg;
 //       cnt_next = cnt_reg;
        case (state)
            IDLE : begin
                tx_next = 1'b1; // high
                tx_done_next = 1'b0; // 초기값
                tick_cnt_next = 4'h0; // 초기값
                if(start_trigger) begin 
                    next = START; // SEND;
                    // start trigger 순간 data를 buffring하기 위함.
                    temp_data_next = data_in;
                end
            end
            SEND : begin
                if(tick == 1'b1) begin
                    next = START;
                end
            end
            START : begin
                tx_done_next = 1'b1;
                tx_next = 1'b0; // 출력을 0으로 유지.
                if(tick == 1'b1) begin
                    if(tick_cnt_reg == 15) begin
                        next = D;
                        tick_cnt_next = 1'b0;
                        bit_cnt_next = 1'b0; // bit_cnt 초기화
                    end
                    else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end
            D : begin 
                 tx_next = temp_data_reg[bit_cnt_reg];
   //             tx_next = data_in[bit_cnt_reg]; //UART LSB first
                if(tick) begin
                    if(tick_cnt_reg == 15) begin
                        tick_cnt_next = 0;
                        if(bit_cnt_reg == 7) begin
                            next = STOP;
                        end
                        else begin 
                            next = D;
                            bit_cnt_next = bit_cnt_reg + 1; // bit count 증가
                        end
                    end 
                    else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
                /*
                if(tick == 1'b1) begin
                    tx_next = data_in[cnt_reg];
                    cnt_next = cnt_next + 1;
                    if(bit_cnt_next == 7) begin
                         next = STOP;
                         cnt_next = 0;
                    end
                end
                */
            end
            STOP : begin
                tx_next = 1'b1;
                if(tick == 1'b1) begin
                    if(tick_cnt_reg == 15) begin
                        next = IDLE;
                        tick_cnt_next = 1'b0;
                    end
                    else begin 
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end
        endcase
    end


endmodule


module baud_tick_genp (
    input clk,
    input rst,
    output baud_tick
);

    parameter BAUD_RATE = 9600; //BAUD_RATE_19200 = 19200, ;
    localparam BAUD_COUNT = (100_000_000/BAUD_RATE)/16;
    reg [$clog2(BAUD_COUNT)-1:0] cnt_reg, cnt_next;
    reg tick_reg, tick_next;

    assign baud_tick = tick_reg;


    always @(posedge clk, posedge rst) begin

        if(rst) begin
            tick_reg <= 0;
            cnt_reg <= 0;
        end
        else begin
            cnt_reg <= cnt_next;
            tick_reg <= tick_next;
        end 
    end

    always @(*) begin
        cnt_next = cnt_reg;
        tick_next = tick_reg;
        if(cnt_reg == BAUD_COUNT-1) begin
            cnt_next = 0;
            tick_next = 1'b1; 
        end
        else begin
            cnt_next = cnt_reg + 1;
            tick_next = 1'b0;
        end
    end



endmodule