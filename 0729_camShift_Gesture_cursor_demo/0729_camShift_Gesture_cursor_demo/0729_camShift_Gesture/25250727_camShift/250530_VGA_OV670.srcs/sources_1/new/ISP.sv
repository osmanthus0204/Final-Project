`timescale 1ns / 1ps

module ISP (
    input  logic        clk,
    input  logic        xclk,
    input  logic        reset,
    input logic up_btn,
    input logic down_btn,
    input logic select,
    input logic [ 9:0] h_counter,
    input logic [ 7:0] v_counter,
    input  logic [16:0] rAddr,
    input  logic [15:0] rData,
    output logic [11:0] filtered_data,
    output logic [4:0] filter_number
);





    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            filter_number <= 0;
        end else begin
            if(select) begin
                if (up_btn) begin  // btn_up
                    filter_number <= (filter_number == 5'd12) ? 0 : filter_number + 1;
                end else if (down_btn) begin  // btn_down
                    filter_number <= (filter_number == 0) ? 5'd12 : filter_number - 1;
                end
            end
        end
    end 

    // localparam 
    //     RED_FILTER       = 8'b00000_001,
    //     GREEN_FILTER     = 8'b00000_010,
    //     BLUE_FILTER      = 8'b00000_100,
    //     GRAY_FILTER      = 8'b00001_000,
    //     REVERSE_FILTER   = 8'b00010_000,
    //     CHROMA_FILTER    = 8'b00100_000,
    //     GAUSSIAN_FILTER  = 8'b01000_000,
    //     SOBEL_FILTER     = 8'b10000_000;
    logic [11:0] gray_value;
    logic [11:0]
        original_color, filtered_color, chroma_key_color, gaussian_color;
    logic [15:0] background_pixel;
    logic [16:0] bg_rAddr;
    logic [11:0] edge_val;
    logic [11:0] checkerboard_color;
    logic [11:0] cartoon_color; 
    assign rclk = clk;
    assign original_color = {
        rData[15:12], rData[10:7], rData[4:1]
    };  // RGB 12-bit color
    


    always_comb begin
        filtered_color = original_color;
        case (filter_number)
            5'd0: filtered_color = original_color ;
            5'd1: filtered_color = original_color & 12'b1111_0000_0000;   //RED_FILTER
            5'd2: filtered_color = original_color & 12'b0000_1111_0000;   //GREEN_FILTER
            5'd3: filtered_color = original_color & 12'b0000_0000_1111;  //BLUE_FILTER
            5'd4: begin                                                  //GRAY_FILTER
                gray_value = (77*original_color[11:8] + 155*original_color[7:4] + 29*original_color[3:0]);
                filtered_color = {
                    gray_value[11:8], gray_value[11:8], gray_value[11:8]
                };
            end
            5'd5: filtered_color = ~original_color;     //REVERSE_FILTER
            5'd6: filtered_color = chroma_key_color;    //CHROMA_FILTER
            5'd7: filtered_color = gaussian_color;      //GAUSSIAN_FILTER
            5'd8: filtered_color = edge_val;            //SOBEL_FILTER
            5'd9: begin                                 // SEPIA_FILTER
                logic [7:0] sepia_r, sepia_g, sepia_b;
                sepia_r = ( 9*original_color[11:8] + 7*original_color[7:4] + 3*original_color[3:0]) >> 4;
                sepia_g = ( 8*original_color[11:8] + 7*original_color[7:4] + 3*original_color[3:0]) >> 4;
                sepia_b = ( 7*original_color[11:8] + 5*original_color[7:4] + 2*original_color[3:0]) >> 4;

                // 범위 클리핑 (최대 15로 제한)
                if (sepia_r > 15) sepia_r = 15;
                if (sepia_g > 15) sepia_g = 15;
                if (sepia_b > 15) sepia_b = 15;

                filtered_color = {sepia_r[3:0], sepia_g[3:0], sepia_b[3:0]};
            end
            5'd10: filtered_color = checkerboard_color;            //CHECKERBOARD_FILTER
            5'd11: filtered_color = cartoon_color;            //CARTOON_FILTER
            5'd12: begin                                        // POSTERIZE_FILTER
                filtered_color = {
                    {original_color[11:10], 2'b00},  // R: 상위 2비트 유지
                    {original_color[7:6],   2'b00},  // G
                    {original_color[3:2],   2'b00}   // B
                };
            end
            default: filtered_color = original_color;
        endcase
    end


    chromakey U_Chromakey (
        .pixel_in(original_color),
        .background_pixel({
            background_pixel[15:12],
            background_pixel[10:7],
            background_pixel[4:1]
        }),
        .pixel_out(chroma_key_color)
    );

    background_rom U_BACK_ROM (
        .rAddr(rAddr),
        .rData(background_pixel)
    );
    gaussian U_GAUSSIAN (
        .clk(xclk),
        .reset(reset),
        .h_counter(h_counter),
        .v_counter(v_counter),
        .p_red_port(original_color[11:8]),
        .p_green_port(original_color[7:4]),
        .p_blue_port(original_color[3:0]),
        .red_port(gaussian_color[11:8]),
        .green_port(gaussian_color[7:4]),
        .blue_port(gaussian_color[3:0])
    );
    sobel_filter U_SOBEL_FILTER (
        .clk(xclk),
        .reset(reset),
        .h_counter(h_counter),
        .v_counter(v_counter),
        .original_color(original_color),
        .edge_out(edge_val)
    );

    checkerboard_mask U_CHECKERBOARD (
        .clk(clk),
        .reset(reset),
        .h_counter(h_counter),
        .v_counter(v_counter),
        .original_color(original_color),
        .checkerboard_color(checkerboard_color)
    );

    cartoon_filter U_CARTOON (
        .clk(clk),
        .reset(reset),
        .h_counter(h_counter),
        .v_counter(v_counter),
        .original_color(original_color), 
        .gaussian_color(gaussian_color), 
        .edge_val(edge_val),             
        .cartoon_out(cartoon_color)       
    );

    assign filtered_data = filtered_color;


endmodule




module chromakey (
    input  logic [11:0] pixel_in,
    input  logic [11:0] background_pixel,
    output logic [11:0] pixel_out
);
    localparam margin = 2;
    logic [3:0] r, g, b;
    assign r = pixel_in[11:8];
    assign g = pixel_in[7:4];
    assign b = pixel_in[3:0];

    logic is_green;
    assign is_green  = (g > (r+margin)) && (g > (b+margin)) && (g >= 4'b0110);



    assign pixel_out = (is_green) ? background_pixel : pixel_in;
endmodule

module background_rom (
    input  [16:0] rAddr,
    output [15:0] rData
);
    logic [15:0] mem [0:160*120 - 1]; // Define memory size based on your requirements
    initial begin
        $readmemh("background.mem", mem);
    end

    assign rData = mem[rAddr];
endmodule

module gaussian (
    input  logic        clk,
    input  logic        reset,
    // input  logic [16:0] addr,
    input  logic [ 9:0] h_counter,
    input  logic [ 7:0] v_counter,
    input  logic [ 3:0] p_red_port,
    input  logic [ 3:0] p_green_port,
    input  logic [ 3:0] p_blue_port,
    output logic [ 3:0] red_port,
    output logic [ 3:0] green_port,
    output logic [ 3:0] blue_port
);
    logic [11:0] line_buffer[2:0][159:0];

    logic [7:0] row, col;
    // assign row = addr / 160;
    // assign col = addr % 160;
    assign row = v_counter[7:1];
    assign col = h_counter[9:2];

    logic [11:0] pixel;
    logic [11:0] pixel_cal[2:0][2:0];

    always_ff @(posedge clk) begin
        if (reset) begin
            for (int i = 0; i < 3; i++) begin
                for (int j = 0; j < 160; j++) begin
                    line_buffer[i][j] <= 0;
                end
            end
        end else begin
            line_buffer[0][col] <= pixel;
            line_buffer[1][col] <= line_buffer[0][col];
            line_buffer[2][col] <= line_buffer[1][col];
        end
    end

    always_ff @(posedge clk) begin
            pixel_cal[0][0] <= (row == 0 || col == 0)? 0 : line_buffer[2][col-1];
            pixel_cal[0][1] <= (row == 0)? 0 : line_buffer[2][col];
            pixel_cal[0][2] <= (row == 0)? 0 :line_buffer[2][col+1];

            pixel_cal[1][0] <= (col == 0)? 0 : line_buffer[1][col-1];
            pixel_cal[1][1] <= line_buffer[1][col];
            pixel_cal[1][2] <= (col == 159)? 0 :line_buffer[1][col+1];

            pixel_cal[2][0] <= (row == 119 || col == 0)? 0 : line_buffer[0][col-1];
            pixel_cal[2][1] <= (row == 119) ? 0 : line_buffer[0][col];
            pixel_cal[2][2] <= (row == 119 || col == 159)? 0 : line_buffer[0][col+1];
        // end
    end

    always_comb begin
        pixel = {p_red_port, p_green_port, p_blue_port};
        red_port = ( (pixel_cal[0][0][11:8] + pixel_cal[0][2][11:8] + pixel_cal[2][0][11:8] + pixel_cal[2][2][11:8]) +
                         ((pixel_cal[0][1][11:8] + pixel_cal[1][0][11:8] + pixel_cal[1][2][11:8] + pixel_cal[2][1][11:8]) *2) +
                         ((pixel_cal[1][1][11:8]) * 4) ) >>4;

        green_port = ( (pixel_cal[0][0][7:4] + pixel_cal[0][2][7:4] + pixel_cal[2][0][7:4] + pixel_cal[2][2][7:4]) +
                         ((pixel_cal[0][1][7:4] + pixel_cal[1][0][7:4] + pixel_cal[1][2][7:4] + pixel_cal[2][1][7:4]) *2) +
                         ((pixel_cal[1][1][7:4]) * 4) ) >>4;

        blue_port = ( (pixel_cal[0][0][3:0] + pixel_cal[0][2][3:0] + pixel_cal[2][0][3:0] + pixel_cal[2][2][3:0]) +
                         ((pixel_cal[0][1][3:0] + pixel_cal[1][0][3:0] + pixel_cal[1][2][3:0] + pixel_cal[2][1][3:0]) *2) +
                         ((pixel_cal[1][1][3:0]) * 4) ) >>4;
    end

endmodule

module sobel_filter (
    input logic        clk,
    input logic        reset,
    input  logic [ 9:0] h_counter,
    input  logic [ 7:0] v_counter,
    // input logic [16:0] rAddr,

    input  logic [11:0] original_color,
    output logic [11:0] edge_out
);
    logic [3:0] line_buffer[2:0][159:0];
    logic [3:0] p[0:8];
    logic [7:0] row, col;
    logic [11:0] gray;
    assign row = v_counter[7:1];
    assign col = h_counter[9:2];
    // assign row = rAddr / 160;
    // assign col = rAddr % 160;


    // 라인버퍼
    always_ff @(posedge clk) begin
        if (reset) begin
            for (int i = 0; i < 3; i++) begin
                for (int j = 0; j < 160; j++) begin
                    line_buffer[i][j] <= 0;
                end
            end
        end else begin  //end else if (DE && (col<320) && (row<240)) begin
            line_buffer[2][col] <= line_buffer[1][col];
            line_buffer[1][col] <= line_buffer[0][col];
            line_buffer[0][col] <= gray[11:8];
        end
    end

    // 3x3 윈도우
    always_ff @(posedge clk) begin
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

    // gx, gy 연산
    logic signed [6:0] gx, gy;
    logic [6:0] abs_gx, abs_gy;
    logic [7:0] sum;

    always_comb begin
        gray =(77*original_color[11:8] + 155*original_color[7:4] + 29*original_color[3:0]);

        gx = (p[2] + 2 * p[5] + p[8]) - (p[0] + 2 * p[3] + p[6]);
        gy = (p[6] + 2 * p[7] + p[8]) - (p[0] + 2 * p[1] + p[2]);

        abs_gx = (gx < 0) ? -gx : gx;
        abs_gy = (gy < 0) ? -gy : gy;

        sum = {abs_gx + abs_gy};

        if (sum > 7) edge_out = 12'hFFF;
        else edge_out = 12'h000;
    end
endmodule

module checkerboard_mask (
    input  logic        clk,
    input  logic        reset,
    input  logic [ 9:0] h_counter,
    input  logic [ 7:0] v_counter,
    input  logic [11:0] original_color,
    output logic [11:0] checkerboard_color
);
    logic [11:0] gray;

    // Grayscale 변환 (고정 계수: 0.3R + 0.59G + 0.11B 근사)
    always_comb begin
        gray = (77*original_color[11:8] + 155*original_color[7:4] + 29*original_color[3:0]);
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            checkerboard_color <= 12'h000;
        end else begin
            if (h_counter[3] ^ v_counter[3])
                checkerboard_color <= original_color;  // 흰칸 부분은 원본
            else
                checkerboard_color <= {gray[11:8], gray[11:8], gray[11:8]};  // 검정칸 부분은 그레이
        end
    end
endmodule

module cartoon_filter (
    input  logic        clk,
    input  logic        reset,
    input  logic [9:0]  h_counter,
    input  logic [7:0]  v_counter,
    input  logic [11:0] original_color,   // 원본 색상
    input  logic [11:0] gaussian_color,   // 안 써도 됨 (옵션용)
    input  logic [11:0] edge_val,             // Sobel edge map (흰색 또는 검정)
    output logic [11:0] cartoon_out       // 만화 스타일 출력
);

    // 원본 색상에서 R, G, B 추출
    logic [3:0] r, g, b;
    logic [3:0] r_smooth, g_smooth, b_smooth;
    logic [3:0] r_q, g_q, b_q;

    // assign r = original_color[11:8];
    // assign g = original_color[7:4];
    // assign b = original_color[3:0];

    assign r_smooth = gaussian_color[11:8];
    assign g_smooth = gaussian_color[7:4];
    assign b_smooth = gaussian_color[3:0];

    // 색상 Quantization (상위 2비트만 유지, 하위는 0으로 채움)
    // assign r_q = {r[3:2], 2'b00};  // 예: 1100 → 1100
    // assign g_q = {g[3:2], 2'b00};
    // assign b_q = {b[3:2], 2'b00};

    assign r_q = {r_smooth[3:2], 2'b00};  // 상위 2bit만 살림
    assign g_q = {g_smooth[3:2], 2'b00};
    assign b_q = {b_smooth[3:2], 2'b00};

    // Edge를 기준으로 검정색 윤곽선을 덮어씌움
    always_comb begin
        if (edge_val == 12'hFFF)  // Sobel edge가 흰색이면
            cartoon_out = 12'h000;  // 검정색 선
        else
            cartoon_out = {r_q, g_q, b_q};  // quantized original color
    end

endmodule