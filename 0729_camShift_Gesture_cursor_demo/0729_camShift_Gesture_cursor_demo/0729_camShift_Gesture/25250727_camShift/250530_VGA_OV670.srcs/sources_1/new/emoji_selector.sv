`timescale 1ns / 1ps


module emoji_selector(
    input logic clk,
    input logic sw_emoji,
    input logic reset,
    input logic up_btn,
    input logic down_btn,
    output logic [3:0] emoji_select
    );
    always_ff @( posedge clk, posedge reset ) begin : blockName
        if(reset) begin
            emoji_select <= 0;
        end else if(sw_emoji&&up_btn) begin
            emoji_select <= emoji_select + 1;
        end else if(sw_emoji&&down_btn) begin
            emoji_select <= emoji_select - 1;
        end
        
    end
endmodule
