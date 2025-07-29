`timescale 1ns / 1ps

module Histogram (
    input logic clk,
    input logic reset,
    input logic btn_start,
    input logic frame_done,
    input logic [9:0] h_counter,
    input logic [7:0] v_counter,
    input logic [7:0] hue,
    output logic [12:0] rData,
    output logic [12:0] hueFreqMax,
    output logic [5:0] led_state,
    output logic hue_max_done
);

    logic wr_en;
    logic [7:0] wAddr;
    logic [12:0] wData;

    Histogram_Control_Unit U_Histogram_Control_Unit (.*);
    Histrogram_ram U_Histrogram_ram (
        .*,
        .rAddr(hue)
    );

endmodule


module Histogram_Control_Unit (
    input logic clk,
    input logic reset,
    input logic btn_start,
    input logic frame_done,
    input logic [9:0] h_counter,
    input logic [7:0] v_counter,
    input logic [7:0] hue,
    output logic [12:0] hueFreqMax,
    output logic wr_en,
    output logic [7:0] wAddr,
    output logic [12:0] wData,
    output logic [5:0] led_state,
    output logic hue_max_done
);

    logic [1:0] state, state_next;
    logic ROI;
    logic [13:0] count_max_reg, count_max_next;
    logic [7:0] hue_index_reg, hue_index_next;
    logic [12:0] hue_count_reg [0:255];
    logic [12:0] hue_count_next[0:255];
    logic hue_max_done_next, hue_max_done_reg;
    localparam IDLE = 0, START = 1, SAVE = 2, FIND_MAX = 3;
    localparam X_max = 120;
    localparam X_min = 80;
    localparam Y_max = 90;
    localparam Y_min = 60;
    assign ROI = (h_counter >= X_min) && (h_counter <= X_max) && (v_counter >= Y_min) && (v_counter <= Y_max);
    assign hueFreqMax = count_max_reg;
    assign wAddr = hue;
    assign wData = hue_count_reg[wAddr];
    assign hue_max_done = hue_max_done_reg;
    always_ff @(posedge clk) begin
        if (reset) begin
            state <= 0;
            hue_index_reg <= 0;
            count_max_reg <= 0;
            hue_max_done_reg <= 0;
            for (int i = 0; i < 256; i++) begin
                hue_count_reg[i] <= 0;
            end
        end else begin
            state <= state_next;
            hue_index_reg <= hue_index_next;
            count_max_reg <= count_max_next;
            hue_max_done_reg <= hue_max_done_next;
            for (int i = 0; i < 256; i++) begin
                hue_count_reg[i] <= hue_count_next[i];
            end
        end
    end

    always_comb begin
        state_next = state;
        hue_index_next = hue_index_reg;
        count_max_next = count_max_reg;
        hue_max_done_next = hue_max_done_reg;
        for (int i = 0; i < 256; i++) begin
            hue_count_next[i] = hue_count_reg[i];
        end
        wr_en = 1'b0;
        led_state = 0;
        case (state)
            IDLE: begin
                led_state = 1;
                hue_index_next = 0;
                for (int i = 0; i < 256; i++) begin
                    hue_count_next[i] = 0;
                end
                if (btn_start) begin
                    state_next = START;
                    hue_max_done_next = 0;
                end
            end
            START: begin
                led_state = 2;
                if (frame_done) state_next = SAVE;
            end
            SAVE: begin
                led_state = 4;
                if (ROI) begin
                    wr_en = 1;  // roi 영역에 있을때만
                    hue_count_next[hue] = hue_count_reg[hue] + 1;
                    if((h_counter == X_max - 1) && (v_counter == Y_max - 1)) begin
                        state_next = FIND_MAX;
                        count_max_next = 0;
                    end
                end
            end
            FIND_MAX: begin
                led_state = 8;
                if (hue_count_reg[hue_index_reg] > count_max_reg) begin
                    count_max_next = hue_count_reg[hue_index_reg];
                end
                hue_index_next = hue_index_reg + 1;
                if(hue_index_reg == 255) begin
                    state_next = IDLE;
                    hue_max_done_next = 1;
                end
            end

        endcase
    end


endmodule

module Histrogram_ram (
    input logic clk,
    input logic wr_en,
    input logic [7:0] wAddr,
    input logic [12:0] wData,
    input logic [7:0] rAddr,
    output logic [12:0] rData
);
    logic [12:0] mem[0:255];
    always_ff @(posedge clk) begin
        if (wr_en) begin
            mem[wAddr] <= wData;
        end
    end

    always_comb begin
        rData = mem[rAddr];
    end
endmodule
