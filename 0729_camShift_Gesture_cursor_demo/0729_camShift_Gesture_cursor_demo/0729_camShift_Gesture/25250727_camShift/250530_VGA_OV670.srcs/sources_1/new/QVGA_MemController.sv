`timescale 1ns / 1ps

module QVGA_MemController (
    input  logic        clk,
    input  logic        reset,
    //VGA Controller
    input  logic [9:0]  x_pixel,
    input  logic [9:0]  y_pixel,
    input  logic        DE,

    //frame buffer side
    output logic        rclk,
    output logic        d_en,
    output logic [16:0] rAddr_320x240,
    output logic [16:0] rAddr_160x120,
    input  logic [11:0] rData,

    //export side
    output logic [3:0]  red_port,
    output logic [3:0]  green_port,
    output logic [3:0]  blue_port,


    input logic [9:0] x_min,
    input logic [9:0] y_min,
    input logic [9:0] x_max,
    input logic [9:0] y_max,
    input logic frame_done,

    // cusor data
    input logic [7:0] smoothed_col,
    input logic [7:0] smoothed_row,


    // uart
    output logic start_trigger,
    output logic [7:0] dirData
);

    // logic [9:0] smoothed_col_f,smoothed_row_f;
    // assign smoothed_col_f = smoothed_col <<2;

    logic [1:0] state, state_next;
    logic is_cusor_area;
    localparam IDLE = 0, START_RIGHT = 1, START_LEFT = 2;
    logic [7:0] dirData_next, dirData_reg;
    logic [10:0] x_center,y_center;
    assign dirData = dirData_reg;


    logic display_en;
    assign rclk = clk;
    assign display_en = (x_pixel < 640 && y_pixel < 480);
    assign d_en = display_en;
    assign x_center = (x_min+x_max) >> 1;
    assign y_center = (y_min+y_max) >> 1;

    // Frame address 계산
    // always_ff @(posedge clk) begin
    //     rAddr_320x240 <= (319 - x_pixel[9:1]) + ((y_pixel[9:1] << 8) + (y_pixel[9:1] << 6));
    //     rAddr_160x120 <= (159 - x_pixel[9:2]) + ((y_pixel[9:2] << 7) + (y_pixel[9:2] << 5));
    // end

        // 좌우 반전 제거 상태의 Frame address 계산
    always_ff @(posedge clk) begin
        // rAddr_320x240 <= x_pixel[9:0] + ((y_pixel[9:0] << 8) + (y_pixel[9:0] << 6));
        rAddr_320x240 <= x_pixel[9:1] + ((y_pixel[9:1] << 8) + (y_pixel[9:1] << 6));
        rAddr_160x120 <= x_pixel[9:2] + ((y_pixel[9:2] << 7) + (y_pixel[9:2] << 5));
    end

    // Checkerboard 관련 제거, 프레임 색도 고정
    localparam [11:0] default_rgb = 12'hfff;

    // // 테두리 영역 여부 판단
    // logic is_frame_area;
    // always_ff @(posedge clk) begin
    //     is_frame_area <= (
    //         (x_pixel <= 80) || (y_pixel <= 60) ||
    //         // (x_pixel >= 80 && x_pixel <= 160) ||
    //         // (y_pixel >= 60 && y_pixel <= 120)  ||
    //          (x_pixel >= 160) || (y_pixel >= 120)
    //     );


    // end



    logic is_frame_area;

    logic is_motor_area;


    always_ff @( posedge clk ) begin 

        is_frame_area <= (
        // 상단 테두리
        (y_pixel == y_min && x_pixel >= x_min && x_pixel <= x_max) ||

        // 하단 테두리
        (y_pixel == y_max && x_pixel >= x_min && x_pixel <= x_max) ||

        // 좌측 테두리
        (x_pixel == x_min && y_pixel >= y_min && y_pixel <= y_max) ||

        // 우측 테두리
        (x_pixel == x_max && y_pixel >= y_min && y_pixel <= y_max) ||
        
        // 중심 좌표
        (x_pixel == x_center && y_pixel == y_center )
    );

        is_motor_area <= (
            (x_pixel == 100 || x_pixel == 101) || (x_pixel == 540 || x_pixel == 541)
        );
        // is_cusor_area <= (
        //     (x_pixel == smoothed_col && y_pixel == smoothed_row )
        // );

        if (reset) begin
            state <= 0;
            dirData_reg <= 8'd0;
        end else begin
            state <= state_next;
            dirData_reg <= dirData_next;
        end

    end

    
    always_comb begin
        state_next = state;
        start_trigger = 1'b0; 
        dirData_next = 0;
        if(frame_done) begin
            case (state)
                IDLE: begin
                    if (x_center < 100) begin
                        state_next = START_RIGHT;
                        dirData_next = "C";
                    end else if (x_center > 540) begin
                        state_next = START_LEFT;
                        dirData_next = "D";
                    end
                end 
                START_RIGHT: begin
                    start_trigger = 1'b1;
                    state_next = IDLE;
                end 
                START_LEFT: begin
                    start_trigger = 1'b1;
                    state_next = IDLE;
                end
            endcase    
        end
        
    end

    // // VGA 출력
    // assign {red_port, green_port, blue_port} = 
    //     (display_en) ? (is_frame_area ? default_rgb : rData) : 12'b0;

    assign {red_port, green_port, blue_port} = 
    (display_en) ? (
        // is_cusor_area    ? 12'h0f0 :
        is_motor_area    ? 12'hf00 :  // 빨간색
        is_frame_area    ? default_rgb :
                          rData
    ) : 12'h000;

endmodule
