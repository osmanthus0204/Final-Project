`timescale 1ns / 1ps

module MeanShiftCore (
    input  logic        clk,
    input  logic        reset,
    input  logic        hue_max_done,
    input  logic        framedone,
    input  logic        scale_done,
    input  logic        start,
    input  logic [ 9:0] x_min,
    input  logic [ 9:0] y_min,
    input  logic [ 9:0] x_max,
    input  logic [ 9:0] y_max,
    output logic        en_rd,
    output logic [16:0] ROIAddr,
    input  logic [11:0] ROIrData,
    output logic [40:0] M00,
    output logic [40:0] M10,
    output logic [40:0] M01,
    output logic [40:0] M20,
    output logic [40:0] M02,
    output logic [9:0] x_center,
    output logic [9:0] y_center,

    output logic        center_valid
);

    logic [9:0] x;
    logic [9:0] y;
    logic en_sum, en_center, clr_sum;

    logic [9:0] x_diff, y_diff;

    MeanShift_ControlUnit U_MeanShift_ControlUnit (.*);
    MeanShift_Datapath U_MeanShift_Datapath (.*);

    //roiTest U_roiTest(.*);

endmodule

module MeanShift_ControlUnit (
    input  logic        clk,
    input  logic        reset,
    // framedone 신호
    input  logic        hue_max_done,
    input  logic        framedone,
    input  logic        scale_done,
    // ROI 영역 정보
    input  logic [ 9:0] x_min,
    input  logic [ 9:0] y_min,
    input  logic [ 9:0] x_max,
    input  logic [ 9:0] y_max,
    // BPBuffer로부터 읽을 addr
    output logic        en_rd,
    output logic [16:0] ROIAddr,
    // DataPath로 넘겨줄 ROI영역 내부 좌표
    output logic [ 9:0] x,
    output logic [ 9:0] y,
    output logic  [9:0] x_diff,
    output logic [9:0] y_diff,
    output logic        en_sum,
    output logic        en_center,
    output logic        clr_sum
);

    assign x_diff = x_max - x_min;
    assign y_diff = y_max - y_min;

    typedef enum logic [2:0] {
        IDLE,  // 대기 상태 (start 대기)
        WAIT,
        INIT,  // 누적합 초기화
        SCAN,  // ROI 순회 및 누적
        DONE   // 중심좌표 계산 지시
    } state_t;

    state_t state, state_next;

    logic clr_sum_reg, clr_sum_next;
    assign clr_sum = clr_sum_reg;

    logic en_sum_reg, en_sum_next;
    assign en_sum = en_sum_reg;

    logic en_center_reg, en_center_next;
    assign en_center = en_center_reg;

    logic en_rd_reg, en_rd_next;
    assign en_rd = en_rd_reg;

    logic [9:0] x_reg, x_next;
    assign x = x_reg;

    logic [9:0] y_reg, y_next;
    assign y = y_reg;

    assign ROIAddr = y_reg[9:1] * 320 + x_reg[9:1];

    logic flag_next, flag_reg;
    always_ff @(posedge clk , posedge reset) begin
        if (reset) begin
            state         <= IDLE;
            en_sum_reg    <= 1'b0;
            en_center_reg <= 1'b0;
            clr_sum_reg   <= 1'b0;
            x_reg         <= 10'd0;
            y_reg         <= 10'd0;
            en_rd_reg     <= 1'b0;
            flag_reg      <= 1'b0;
        end else begin
            state         <= state_next;
            en_sum_reg    <= en_sum_next;
            en_center_reg <= en_center_next;
            clr_sum_reg   <= clr_sum_next;
            x_reg         <= x_next;
            y_reg         <= y_next;
            en_rd_reg     <= en_rd_next;
            flag_reg      <= flag_next;
        end
    end

    always_comb begin
        state_next     = state;
        en_sum_next    = en_sum_reg;
        en_center_next = en_center_reg;
        clr_sum_next   = clr_sum_reg;
        x_next         = x_reg;
        y_next         = y_reg;
        en_rd_next     = en_rd_reg;
        flag_next      = flag_reg;
        case (state)
            IDLE: begin
                en_center_next = 1'b0;
                x_next = 0;
                y_next = 0;
                if (hue_max_done) begin
                    clr_sum_next = 1'b1;
                    state_next = WAIT;
                end
            end
            WAIT: begin
                if ((framedone == 1)) begin
                    flag_next=1;
                    state_next = INIT;
                end
                // if( scale_done == 1 && flag_reg == 1  ) begin
                //     state_next = INIT;
                // end
            end
            INIT: begin
                x_next = x_min;
                y_next = y_min;
                clr_sum_next = 1'b0;
                state_next   = SCAN;
                en_rd_next   = 1'b1;
                en_sum_next  = 1'b1;
            end
            SCAN: begin
                if (x_reg == x_max && y_reg == y_max) begin
                    state_next     = DONE;
                    en_sum_next    = 1'b0;
                    en_rd_next     = 1'b0;
                    x_next         = 10'd0;
                    y_next         = 10'd0;
                end else begin
                    if (x_reg < x_max) begin
                        x_next = x_reg + 1;
                    end else begin
                        x_next = x_min;
                        y_next = y_reg + 1;
                    end
                end
            end
            DONE: begin
                en_center_next = 1'b1;
                state_next     = IDLE;
            end
        endcase
    end

endmodule

module MeanShift_Datapath (
    input  logic        clk,
    input  logic        reset,
    input  logic [11:0] ROIrData,
    input  logic [ 9:0] x,
    input  logic [ 9:0] y,
    input logic  [9:0] x_diff,
    input logic [9:0] y_diff,
    input  logic        en_sum,
    input  logic        en_center,
    input  logic        clr_sum,
    output logic [40:0] M00,
    output logic [40:0] M10,
    output logic [40:0] M01,
    output logic [40:0] M20,
    output logic [40:0] M02,
    output logic [ 9:0] x_center,
    output logic [ 9:0] y_center,
    output logic        center_valid
);
    // 내부 레지스터
    logic [40:0] x_sum_reg, y_sum_reg, w_sum_reg, x2_sum_reg, y2_sum_reg;

    logic [9:0] x_div, y_div;
    logic valid_reg;

    // 곱셈 결과 임시 버퍼
    logic [40:0] x_mul, y_mul, x2_mul, y2_mul;

    assign M00 = w_sum_reg;
    assign M10 = x_sum_reg;
    assign M01 = y_sum_reg;
    assign M20 = x2_sum_reg;
    assign M02 = y2_sum_reg;
    assign x_center = x_div;
    assign y_center = y_div;
    assign center_valid = valid_reg;


    always_comb begin
        x_mul = x * ROIrData;   // M10
        y_mul = y * ROIrData;   // M01
        x2_mul = x*x*ROIrData;  // M20
        y2_mul = y*y*ROIrData;  // M02
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset || clr_sum) begin
            x_sum_reg <= 41'd0;
            y_sum_reg <= 41'd0;
            x2_sum_reg <= 41'd0;
            y2_sum_reg <= 41'd0;
            w_sum_reg <= 41'd0;
        end else if (en_sum) begin
            w_sum_reg <= w_sum_reg + ROIrData;  // M00
            x_sum_reg <= x_sum_reg + x_mul;     // M10
            y_sum_reg <= y_sum_reg + y_mul;     // M01
            x2_sum_reg <= x2_sum_reg + x2_mul;    // M20
            y2_sum_reg <= y2_sum_reg + y2_mul;    // M02
        end
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            x_div     <= 0;
            y_div     <= 0;
            valid_reg <= 1'b0;
        end else if (en_center) begin
            if (w_sum_reg != 0) begin
                x_div <= x_sum_reg / w_sum_reg;
                y_div <= y_sum_reg / w_sum_reg;
            end else begin
                x_div <= 10'd0;
                y_div <= 10'd0;
            end
            valid_reg <= 1'b1;
        end else begin
            valid_reg <= 1'b0;
        end
    end

endmodule

// module roiTest(
//     input logic clk,
//     input logic reset,
//     input logic start,
//     input logic [15:0] x_center,
//     input logic [15:0] y_center,
//     input logic center_valid,
// );

//     logic [15:0] prevX, prevY;

//     logic signed [15:0] x_diff, y_diff;

//     always_ff @( posedge clk ) begin
//         if (reset || start) begin
//             prevX <= 120;
//             prevY <= 90;
//             x_diff_sum <= 16'd0;
//             y_diff_sum <= 16'd0;
//         end else if (center_valid) begin
//             prevX <= x_center;
//             prevY <= y_center;
//         end
//     end

//     always_comb begin
//         x_diff = x_center - prevX;
//         y_diff = y_center - prevY;
//     end

// endmodule
