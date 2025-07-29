`timescale 1ns / 1ps

module ISP_for_pen (
    input  logic        clk,
    input  logic        ov7670_pclk,          //ov7670_pclk
    input  logic        reset,
    input  logic        ov7670_v_sync,
    input  logic [15:0] wData,
    input  logic [ 9:0] h_counter_o,
    input  logic [ 7:0] v_counter_o,
    input  logic        sw_erase,
    input  logic        up_btn,
    input  logic        down_btn,
    input  logic        select_cursor_size,
    input  logic        select_cursor_color,
    input  logic [ 3:0] emoji_select,
    output logic [ 3:0] data_out,
    output logic [ 3:0] cursor_size,
    output logic [ 2:0] cursor_color,
    output logic [ 7:0] smoothed_col,
    output logic [ 7:0] smoothed_row,
    output logic frame_done
);
    logic cursor_detected;
    logic erosion_data;

    //cursor_size
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            cursor_size <= 1;
        end else begin
            if (select_cursor_size) begin
                if (up_btn) begin  // btn_up
                    cursor_size <= (cursor_size == 6) ? 0 : cursor_size + 1;
                end else if (down_btn) begin  // btn_down
                    cursor_size <= (cursor_size == 0) ? 6 : cursor_size - 1;
                end
            end
        end
    end

    //cursor_color
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            cursor_color <= 1;
        end else begin
            if (select_cursor_color) begin
                if (up_btn) begin  // btn_up
                    cursor_color <= (cursor_color == 7) ? 1 : cursor_color + 1;
                end else if (down_btn) begin  // btn_down
                    cursor_color <= (cursor_color == 1) ? 7 : cursor_color - 1;
                end
            end
        end
    end


    cursor_detector U_CURSOR_DETECTOR (
        .original_color (wData),
        .binary_color   (),
        .cursor_detected(cursor_detected)
    );
    erosion U_EROSION (
        .pclk        (ov7670_pclk),
        .reset       (reset),
        .binary_data (cursor_detected),
        .h_counter   (h_counter_o),
        .v_counter   (v_counter_o),
        .erosion_data(erosion_data)
    );

    dense_pixel U_DENSE_PIXEL (
        .sw_erase    (sw_erase),
        .clk         (ov7670_pclk),
        .reset       (reset),
        .v_sync      (ov7670_v_sync),
        .data_in     (erosion_data),
        .h_counter   (h_counter_o),
        .v_counter   (v_counter_o),
        .cursor_size (cursor_size),
        .cursor_color(cursor_color),
        .data_out    (data_out),
        .emoji_select(emoji_select),
        .smoothed_col(smoothed_col),
        .smoothed_row(smoothed_row),
        .frame_done(frame_done)
    );


endmodule


module cursor_detector (
    input logic [15:0] original_color,
    output logic [11:0] binary_color,
    output logic cursor_detected  //혹시 몰라서
);
    localparam margin = 1;
    logic [3:0] r, g, b;
    assign r = original_color[15:12];
    assign g = original_color[10:7];
    assign b = original_color[4:1];

    assign cursor_detected = (g > (r + margin)) && (g > (b + margin)) && (g >= 4'b0110);
    assign binary_color = (cursor_detected) ? 12'b1111_1111_1111 : 0;
endmodule

module erosion (
    input logic pclk,
    input logic reset,
    input logic binary_data,
    input logic [9:0] h_counter,
    input logic [7:0] v_counter,

    output logic erosion_data
);
    logic [0:0] line_buffer[2:0][159:0];
    logic [7:0] row, col;
    logic [8:0] p;
    logic valid;
    assign row = v_counter[7:1];
    assign col = h_counter[9:2];


    always_ff @(posedge pclk, posedge reset) begin
        if (reset) begin
            for (int i = 0; i < 3; i++) begin
                for (int j = 0; j < 160; j++) begin
                    line_buffer[i][j] <= 0;
                end
            end
        end else begin
            line_buffer[0][col] <= binary_data;
            line_buffer[1][col] <= line_buffer[0][col];
            line_buffer[2][col] <= line_buffer[1][col];
        end
    end


    always_ff @(posedge pclk) begin
        // 윈도우의 위쪽 행 (line_buffer[2])
        p[0] <= (row == 0 || col == 0) ? 0 : line_buffer[2][col-1];
        p[1] <= (row == 0) ? 0 : line_buffer[2][col];
        p[2] <= (row == 0 || col == 159) ? 0 : line_buffer[2][col+1];
        // 윈도우의 중간 행 (line_buffer[1])
        p[3] <= (col == 0) ? 0 : line_buffer[1][col-1];
        p[4] <= line_buffer[1][col];
        p[5] <= (col == 159) ? 0 : line_buffer[1][col+1];
        // 윈도우의 아래쪽 행 (line_buffer[0])
        p[6] <= (col == 0 || row == 119) ? 0 : line_buffer[0][col-1];
        p[7] <= (row == 119) ? 0 : line_buffer[0][col];
        p[8] <= (col == 159 || row == 119) ? 0 : line_buffer[0][col+1];
    end

    always_comb begin
        valid = &p;
        erosion_data = valid ? 1 : 0;
    end
endmodule


module dense_pixel (
    input  logic       sw_erase,
    input  logic       clk,
    input  logic       reset,
    input  logic       v_sync,
    input  logic       data_in,
    input  logic [9:0] h_counter,
    input  logic [7:0] v_counter,
    input  logic [3:0] cursor_size,
    input  logic [2:0] cursor_color,
    output logic [3:0] data_out,
    input  logic [3:0] emoji_select,
    output logic [7:0] smoothed_col,
    output logic [7:0] smoothed_row,
    output logic frame_done
);

    localparam [3:0] heart[0:99] = '{
        // row 0
        4'd0,
        4'd0,
        4'd10,
        4'd10,
        4'd0,
        4'd0,
        4'd10,
        4'd10,
        4'd0,
        4'd0,
        // row 1
        4'd0,
        4'd10,
        4'd1,
        4'd1,
        4'd10,
        4'd10,
        4'd1,
        4'd1,
        4'd10,
        4'd0,
        // row 2
        4'd10,
        4'd1,
        4'd9,
        4'd1,
        4'd1,
        4'd1,
        4'd1,
        4'd1,
        4'd1,
        4'd10,
        // row 3
        4'd10,
        4'd1,
        4'd9,
        4'd1,
        4'd1,
        4'd1,
        4'd1,
        4'd1,
        4'd1,
        4'd10,
        // row 4
        4'd10,
        4'd1,
        4'd1,
        4'd1,
        4'd1,
        4'd1,
        4'd1,
        4'd1,
        4'd1,
        4'd10,
        // row 5
        4'd0,
        4'd10,
        4'd1,
        4'd1,
        4'd1,
        4'd1,
        4'd1,
        4'd1,
        4'd10,
        4'd0,
        // row 6
        4'd0,
        4'd0,
        4'd10,
        4'd1,
        4'd1,
        4'd1,
        4'd1,
        4'd10,
        4'd0,
        4'd0,
        // row 7
        4'd0,
        4'd0,
        4'd0,
        4'd10,
        4'd1,
        4'd1,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        // row 8
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd10,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 9
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0
    };
    localparam [3:0] glasses[0:99] = '{
        // row 0
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 1
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 2
        4'd10,
        4'd10,
        4'd10,
        4'd10,
        4'd10,
        4'd10,
        4'd10,
        4'd10,
        4'd10,
        4'd10,
        // row 3
        4'd10,
        4'd9,
        4'd10,
        4'd10,
        4'd10,
        4'd10,
        4'd9,
        4'd10,
        4'd10,
        4'd10,
        // row 4
        4'd0,
        4'd10,
        4'd9,
        4'd10,
        4'd0,
        4'd0,
        4'd10,
        4'd9,
        4'd10,
        4'd10,
        // row 5
        4'd0,
        4'd0,
        4'd10,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        4'd10,
        4'd10,
        4'd0,
        // row 6
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 7
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 8
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 9
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0
    };
    localparam [3:0] glitter[0:99] = '{
        // row 0
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 1
        4'd0,
        4'd0,
        4'd0,
        4'd10,
        4'd3,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 2
        4'd0,
        4'd0,
        4'd0,
        4'd10,
        4'd3,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 3
        4'd0,
        4'd10,
        4'd10,
        4'd3,
        4'd3,
        4'd9,
        4'd10,
        4'd10,
        4'd0,
        4'd0,
        // row 4
        4'd10,
        4'd3,
        4'd3,
        4'd3,
        4'd3,
        4'd3,
        4'd9,
        4'd3,
        4'd10,
        4'd0,
        // row 5
        4'd0,
        4'd10,
        4'd10,
        4'd3,
        4'd3,
        4'd3,
        4'd10,
        4'd10,
        4'd0,
        4'd0,
        // row 6
        4'd0,
        4'd0,
        4'd10,
        4'd3,
        4'd3,
        4'd3,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        // row 7
        4'd0,
        4'd0,
        4'd0,
        4'd10,
        4'd3,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 8
        4'd0,
        4'd0,
        4'd0,
        4'd10,
        4'd3,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 9
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0
    };
    localparam [3:0] smile[0:99] = '{
        // row 0
        4'd0,
        4'd0,
        4'd10,
        4'd10,
        4'd10,
        4'd10,
        4'd10,
        4'd10,
        4'd0,
        4'd0,
        // row 1
        4'd0,
        4'd10,
        4'd3,
        4'd3,
        4'd3,
        4'd3,
        4'd3,
        4'd3,
        4'd10,
        4'd0,
        // row 2
        4'd10,
        4'd3,
        4'd3,
        4'd3,
        4'd3,
        4'd3,
        4'd3,
        4'd3,
        4'd3,
        4'd10,
        // row 3
        4'd10,
        4'd3,
        4'd3,
        4'd10,
        4'd3,
        4'd3,
        4'd10,
        4'd3,
        4'd3,
        4'd10,
        // row 4
        4'd10,
        4'd3,
        4'd3,
        4'd3,
        4'd3,
        4'd3,
        4'd3,
        4'd3,
        4'd3,
        4'd10,
        // row 5
        4'd10,
        4'd3,
        4'd10,
        4'd3,
        4'd3,
        4'd3,
        4'd3,
        4'd10,
        4'd3,
        4'd10,
        // row 6
        4'd10,
        4'd3,
        4'd3,
        4'd10,
        4'd10,
        4'd10,
        4'd10,
        4'd3,
        4'd3,
        4'd10,
        // row 7
        4'd10,
        4'd3,
        4'd3,
        4'd3,
        4'd3,
        4'd3,
        4'd3,
        4'd3,
        4'd3,
        4'd10,
        // row 8
        4'd0,
        4'd10,
        4'd3,
        4'd3,
        4'd3,
        4'd3,
        4'd3,
        4'd3,
        4'd10,
        4'd0,
        // row 9
        4'd0,
        4'd0,
        4'd10,
        4'd10,
        4'd10,
        4'd10,
        4'd10,
        4'd10,
        4'd0,
        4'd0
    };
    localparam [3:0] h[0:99] = '{
        // row 0
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 1
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 2
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        // row 3
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        // row 4
        4'd0,
        4'd0,
        4'd10,
        4'd10,
        4'd10,
        4'd10,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        // row 5
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        // row 6
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        // row 7
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        // row 8
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 9
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0
    };
    localparam [3:0] a[0:99] = '{
        // row 0
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 1
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 2
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 3
        4'd0,
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 4
        4'd0,
        4'd0,
        4'd10,
        4'd10,
        4'd10,
        4'd10,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        // row 5
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        // row 6
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        // row 7
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        // row 8
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 9
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0
    };
    localparam [3:0] r[0:99] = '{
        // row 0
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 1
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 2
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd10,
        4'd10,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        // row 3
        4'd0,
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        // row 4
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd10,
        4'd10,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        // row 5
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        // row 6
        4'd0,
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        // row 7
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        // row 8
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 9
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0
    };
    localparam [3:0] m[0:99] = '{
        // row 0
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 1
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 2
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        // row 3
        4'd0,
        4'd0,
        4'd10,
        4'd10,
        4'd0,
        4'd10,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        // row 4
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd10,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        // row 5
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        // row 6
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        // row 7
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        // row 8
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 9
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0
    };
    localparam [3:0] n[0:99] = '{
        // row 0
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 1
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 2
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        // row 3
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd10,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        // row 4
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd10,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        // row 5
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd10,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        // row 6
        4'd0,
        4'd0,
        4'd10,
        4'd10,
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        // row 7
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        // row 8
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 9
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0
    };
    localparam [3:0] draw_red[0:99] = '{
        // row 0
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 1
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 2
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 3
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 4
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd1,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 5
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 6
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 7
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 8
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 9
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0
    };
    localparam [3:0] draw_orange[0:99] = '{
        // row 0
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 1
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 2
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 3
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 4
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd2,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 5
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 6
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 7
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 8
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 9
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0
    };
    localparam [3:0] draw_yellow[0:99] = '{
        // row 0
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 1
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 2
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 3
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 4
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd3,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 5
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 6
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 7
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 8
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 9
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0
    };
    localparam [3:0] draw_green[0:99] = '{
        // row 0
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 1
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 2
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 3
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 4
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd4,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 5
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 6
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 7
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 8
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 9
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0
    };
    localparam [3:0] draw_blue[0:99] = '{
        // row 0
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 1
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 2
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 3
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 4
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd5,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 5
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 6
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 7
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 8
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 9
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0
    };
    localparam [3:0] draw_purple[0:99] = '{
        // row 0
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 1
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 2
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 3
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 4
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd7,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 5
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 6
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 7
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 8
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 9
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0
    };
    localparam [3:0] eraser[0:99] = '{
        // row 0
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 1
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd10,
        4'd10,
        4'd0,
        4'd0,
        // row 2
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd10,
        4'd9,
        4'd9,
        4'd10,
        4'd0,
        // row 3
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd10,
        4'd6,
        4'd10,
        4'd9,
        4'd9,
        4'd10,
        // row 4
        4'd0,
        4'd0,
        4'd0,
        4'd10,
        4'd6,
        4'd6,
        4'd6,
        4'd10,
        4'd9,
        4'd10,
        // row 5
        4'd0,
        4'd0,
        4'd10,
        4'd6,
        4'd6,
        4'd6,
        4'd6,
        4'd6,
        4'd10,
        4'd0,
        // row 6
        4'd0,
        4'd0,
        4'd10,
        4'd6,
        4'd6,
        4'd6,
        4'd6,
        4'd10,
        4'd0,
        4'd0,
        // row 7
        4'd0,
        4'd0,
        4'd0,
        4'd10,
        4'd6,
        4'd6,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        // row 8
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd10,
        4'd10,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 9
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0
    };
    localparam [3:0] no_color[0:99] = '{
        // row 0
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 1
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 2
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 3
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 4
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 5
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 6
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 7
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 8
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        // row 9
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0,
        4'd0
    };



    logic [0:0] line_buffer[4:0][159:0];
    logic [7:0] row, col;
    logic [24:0] p;
    assign row = v_counter[7:1];
    assign col = h_counter[9:2];

    logic v_sync_prev;
    always_ff @(posedge clk or posedge reset) begin
        if (reset) v_sync_prev <= 0;
        else v_sync_prev <= v_sync;
    end
    assign frame_done = (v_sync_prev && !v_sync);

    always_ff @(posedge clk) begin
        if (reset) begin
            for (int i = 0; i < 5; i++) begin
                for (int j = 0; j < 160; j++) begin
                    line_buffer[i][j] <= 0;
                end
            end
        end else begin
            line_buffer[0][col] <= data_in;
            line_buffer[1][col] <= line_buffer[0][col];
            line_buffer[2][col] <= line_buffer[1][col];
            line_buffer[3][col] <= line_buffer[2][col];
            line_buffer[4][col] <= line_buffer[3][col];
        end
    end

    always_ff @(posedge clk) begin
        p[0]  <= (row == 0 || col == 0) ? 0 : line_buffer[4][col-2];
        p[1]  <= (row == 0) ? 0 : line_buffer[4][col-1];
        p[2]  <= (row == 0) ? 0 : line_buffer[4][col];
        p[3]  <= (row == 0) ? 0 : line_buffer[4][col+1];
        p[4]  <= (row == 0 || col == 159) ? 0 : line_buffer[4][col+2];

        p[5]  <= (col == 0) ? 0 : line_buffer[3][col-2];
        p[6]  <= line_buffer[3][col-1];
        p[7]  <= line_buffer[3][col];
        p[8]  <= line_buffer[3][col+1];
        p[9]  <= (col == 159) ? 0 : line_buffer[3][col+2];

        p[10] <= (col == 0) ? 0 : line_buffer[2][col-2];
        p[11] <= line_buffer[2][col-1];
        p[12] <= line_buffer[2][col];
        p[13] <= line_buffer[2][col+1];
        p[14] <= (col == 159) ? 0 : line_buffer[2][col+2];

        p[15] <= (col == 0) ? 0 : line_buffer[1][col-2];
        p[16] <= line_buffer[1][col-1];
        p[17] <= line_buffer[1][col];
        p[18] <= line_buffer[1][col+1];
        p[19] <= (col == 159) ? 0 : line_buffer[1][col+2];

        p[20] <= (col == 0 || row == 119) ? 0 : line_buffer[0][col-2];
        p[21] <= (row == 119) ? 0 : line_buffer[0][col-1];
        p[22] <= (row == 119) ? 0 : line_buffer[0][col];
        p[23] <= (row == 119) ? 0 : line_buffer[0][col+1];
        p[24] <= (col == 159 || row == 119) ? 0 : line_buffer[0][col+2];
    end

    logic window_sum;
    logic flag;
    always_comb begin
        window_sum = &p;  // erosion window 전부 1일 때만 검출
    end

    logic [7:0] max_col, max_row;

    parameter logic [3:0] alpha = 4;  // 1/4 정도만 반영

    always_ff @(posedge clk) begin
        if (reset) begin
            max_col <= 0;
            max_row <= 0;
            flag    <= 0;
        end else if (frame_done) begin
            flag    <= 1'b0;
            max_col <= max_col;
            max_row <= max_row;
        end else if (window_sum && !flag) begin
            flag    <= 1'b1;
            max_col <= col;
            max_row <= row;
        end
    end


    always_ff @(posedge clk) begin
        if (reset) begin
            smoothed_col <= 0;
            smoothed_row <= 0;
        end else if (frame_done) begin
            smoothed_col <= (smoothed_col * (16 - alpha) + max_col * alpha) >> 4;
            smoothed_row <= (smoothed_row * (16 - alpha) + max_row * alpha) >> 4;
        end
    end

    logic [7:0] col_now, row_now;
    assign col_now = h_counter[9:2];  // QVGA 기준
    assign row_now = v_counter[7:1];


    logic is_close_col, is_close_row;
    //1 -> 3x3, 2-> 5x5, 3-> 7x7

    assign is_close_col = (col_now > smoothed_col) ? (col_now -smoothed_col <= cursor_size) : (smoothed_col - col_now == 0);
    assign is_close_row = (row_now > smoothed_row) ? (row_now -smoothed_row <= cursor_size) : (smoothed_row - row_now == 0);

    always_comb begin
        if (is_close_col && is_close_row) begin
            // data_out = cursor_color;
        end else begin
            // data_out = 0;
        end
    end


    logic [3:0] scale;
    logic [7:0] rel_col, rel_row;
    logic [7:0] heart_x, heart_y;
    assign scale = (cursor_size < 1) ? 1 : (cursor_size > 5) ? 5 : cursor_size;

    assign rel_col = (col_now >= smoothed_col) ? (col_now - smoothed_col) : (smoothed_col - col_now);
    assign rel_row = (row_now >= smoothed_row) ? (row_now - smoothed_row) : (smoothed_row - row_now);

    // 커서 크기 스케일에 따라 하트 좌표 계산

    assign heart_x = (col_now >= smoothed_col) ?
          (5 + (col_now - smoothed_col) / scale) :
          (5 - (smoothed_col - col_now) / scale);

    assign heart_y = (row_now >= smoothed_row) ?
          (5 + (row_now - smoothed_row) / scale) :
          (5 - (smoothed_row - row_now) / scale);
    logic is_inside_heart;
    assign is_inside_heart = (heart_x >= 0 && heart_x < 10 && heart_y >= 0 && heart_y < 10);

    always_comb begin
        if (is_inside_heart) begin
            if (sw_erase) begin
                data_out = eraser[heart_y*10+heart_x];
            end else begin
                case (emoji_select)
                    0: data_out = draw_green[heart_y*10+heart_x];
                    1: data_out = draw_green[heart_y*10+heart_x];
                    2: data_out = glitter[heart_y*10+heart_x];
                    3: data_out = smile[heart_y*10+heart_x];
                    4: data_out = h[heart_y*10+heart_x];
                    5: data_out = a[heart_y*10+heart_x];
                    6: data_out = r[heart_y*10+heart_x];
                    7: data_out = m[heart_y*10+heart_x];
                    8: data_out = n[heart_y*10+heart_x];
                    9: data_out = draw_red[heart_y*10+heart_x];
                    10: data_out = draw_orange[heart_y*10+heart_x];
                    11: data_out = draw_yellow[heart_y*10+heart_x];
                    12: data_out = draw_green[heart_y*10+heart_x];
                    13: data_out = draw_blue[heart_y*10+heart_x];
                    14: data_out = draw_purple[heart_y*10+heart_x];
                    15: data_out = no_color[heart_y*10+heart_x];
                    default: data_out = draw_green[heart_y*10+heart_x];
                endcase
            end
        end else begin
            data_out = 4'd0;
        end
    end

    /*
    always_comb begin
        if (is_close_col && is_close_row) begin
            data_out = heart[(smoothed_col - col_now) + 10*(smoothed_row - row_now)];
        end else begin
            data_out = 1'b0;
        end
    end    
*/
endmodule
