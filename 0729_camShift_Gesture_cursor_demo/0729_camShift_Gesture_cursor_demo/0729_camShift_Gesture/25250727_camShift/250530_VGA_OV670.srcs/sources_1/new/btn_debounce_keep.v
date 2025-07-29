`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/22 10:10:03
// Design Name: 
// Module Name: btn_debounce_keep
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


module btn_debounce_keep(

    input clk,
    input reset,
    input i_btn,
    output o_btn
);                           
    localparam DEBOUNCE_COUNT = 1_000;
    //        state, next;
    reg [7:0] q_reg, q_next;
    reg edge_detect;
    wire btn_debounce;

    //시뮬레이션시 1kh를 /*로 막은 뒤 밑의 always구문의의 r_1khz를 100mhz 기본 clk으로 해버리면 시뮬레이션 빨리가능
    // 1khz clk
    reg [$clog2(DEBOUNCE_COUNT)-1:0] counter_reg, counter_next;
    reg r_1khz;
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            counter_reg <= 0;
        end else begin
            counter_reg <= counter_next;
        end
    end
    
    //next
    always @(*) begin   //100_000_000
        counter_next = counter_reg;
        r_1khz = 0;
        if(counter_reg == DEBOUNCE_COUNT - 1) begin
            counter_next = 0;
            r_1khz = 1'b1;
        end else begin
            counter_next = counter_reg +1;
            r_1khz = 1'b0;
        end
        
    end

    // state logic
    always @(posedge r_1khz, posedge reset) begin
        if (reset) begin
            q_reg <= 0;
        end else begin
            q_reg <= q_next;
        end
    end

    always @(i_btn, r_1khz, q_reg) begin // event i_btn, r_1khz
        // q_reg의 상위 7비트를 다음 하위 7비트에 넣고 최상에는 i_btn을 넣어라라
        q_next = {i_btn,q_reg[7:1]}; //shift의 동작을 설명
    end
        
    // 8 input And gate
    assign btn_debounce = &q_reg;

        
    // 최종 출력
    assign o_btn = btn_debounce;
    
endmodule