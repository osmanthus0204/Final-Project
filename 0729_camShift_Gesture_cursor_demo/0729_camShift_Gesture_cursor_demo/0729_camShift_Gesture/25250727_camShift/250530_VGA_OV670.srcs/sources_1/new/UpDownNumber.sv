`timescale 1ns / 1ps

module updown_number #(parameter NUMBER_BITS = 4)(
    input logic clk,
    input logic reset,
    input logic up_btn,
    input logic down_btn,
    input logic select,
    output logic [NUMBER_BITS-1:0] number
    );

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            number <= 0;
        end else begin
            if(select) begin
                if (up_btn) begin  // btn_up
                    number <= (number == (1 << NUMBER_BITS)) ? 0 : number + 1;
                end else if (down_btn) begin  // btn_down
                    number <= (number == 0) ? (1 << NUMBER_BITS) : number - 1;
                end
            end
        end
    end 
endmodule
