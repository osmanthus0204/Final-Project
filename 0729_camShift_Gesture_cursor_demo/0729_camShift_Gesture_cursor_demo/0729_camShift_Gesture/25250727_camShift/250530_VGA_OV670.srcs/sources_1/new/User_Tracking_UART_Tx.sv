`timescale 1ns / 1ps

module User_Tracking_UART_Tx (
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] smoothed_col,
    input  logic [7:0] smoothed_row,
    output             tx,
    output             tx_done
);

    logic [7:0] tracking_char;
    logic [7:0] prev_char;
    logic       start_trigger;
    logic       tick;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            prev_char <= 0;
            start_trigger <= 0;
        end else begin
            if (tracking_char != prev_char) begin
                start_trigger <= 1;
                prev_char <= tracking_char;
            end else begin
                start_trigger <= 0;
            end
        end
    end

    User_Tracking User_Tracking (
        .smoothed_col (smoothed_col),
        .smoothed_row (smoothed_row),
        .tracking_char(tracking_char)
    );

    UART_TX UART_Tx (
        .clk          (clk),
        .rst          (rst),
        .tick         (tick),
        .start_trigger(start_trigger),
        .data_in      (prev_char),
        .o_tx         (tx),
        .o_tx_done    (tx_done)
    );

    baud_tick_genp Baud_Tick_Gen (
        .clk      (clk),
        .rst      (rst),
        .baud_tick(tick)
    );

endmodule
