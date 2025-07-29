`timescale 1ns / 1ps

module ROI_KalmanFilter (
    input  logic        clk,
    input  logic        reset,
    input  logic        valid_in,
    input  logic [9:0]  x_min,
    input  logic [9:0]  y_min,
    input  logic [9:0]  x_max,
    input  logic [9:0]  y_max,
    output logic [9:0]  x_min_o,
    output logic [9:0]  y_min_o,
    output logic [9:0]  x_max_o,
    output logic [9:0]  y_max_o
);
    Kalman1D k_xmin(.clk(clk), .reset(reset), .valid_in(valid_in), .z_pos(x_min), .x_out(x_min_o));
    Kalman1D k_ymin(.clk(clk), .reset(reset), .valid_in(valid_in), .z_pos(y_min), .x_out(y_min_o));
    Kalman1D k_xmax(.clk(clk), .reset(reset), .valid_in(valid_in), .z_pos(x_max), .x_out(x_max_o));
    Kalman1D k_ymax(.clk(clk), .reset(reset), .valid_in(valid_in), .z_pos(y_max), .x_out(y_max_o));
endmodule


`timescale 1ns / 1ps

module Kalman1D (
    input  logic        clk,
    input  logic        reset,
    input  logic        valid_in,
    input  logic [9:0]  z_pos,   // 측정된 위치
    output logic [9:0]  x_out    // 추정된 위치 출력
);

    // 상태 변수 (고정소수점 16비트)
    logic signed [15:0] x_est, v_est;
    logic signed [15:0] x_pred, v_pred;
    logic signed [15:0] z_ext, y_err;
    logic [15:0] Pxx, Pxv, Pvx, Pvv;
    logic [15:0] S, Kx, Kv;

    // 시스템 파라미터
    parameter logic [15:0] Q = 16'd1;
    parameter logic [15:0] R = 16'd15;
    parameter logic [15:0] dt = 16'd32;  // 0.125 (8.8 fixed-point)

    // 출력 변환
    assign x_out = x_est[15:6];

    // 내부 초기화 상태
    logic initialized;
    logic [15:0] abs_y_err;

    function [15:0] abs16(input signed [15:0] val);
        return (val[15]) ? (~val + 1) : val;
    endfunction

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            initialized <= 0;
            x_est <= 0;
            v_est <= 0;
            Pxx <= 16'd100;
            Pxv <= 0;
            Pvx <= 0;
            Pvv <= 16'd100;
        end else if (valid_in) begin
            z_ext = {6'd0, z_pos};

            if (!initialized) begin
                x_est <= z_ext;
                v_est <= 0;
                initialized <= 1;
                Pxx <= 16'd100;
                Pvv <= 16'd100;
                Pxv <= 0;
                Pvx <= 0;
            end else begin
                // 예측
                x_pred = x_est + ((v_est * dt) >>> 8);
                v_pred = v_est;

                // 공분산 예측
                Pxx = Pxx + ((Pxv * dt) >>> 8) + ((Pvx * dt) >>> 8)
                            + (((Pvv * dt * dt) >>> 8) >>> 8) + Q;
                Pxv = Pxv + ((Pvv * dt) >>> 8);
                Pvx = Pxv;
                Pvv = Pvv + Q;

                // 측정 보정
                y_err = z_ext - x_pred;
                abs_y_err = abs16(y_err);

                // 예외: 너무 튀면 강제 리셋
                if (abs_y_err > 16'd256) begin
                    x_est <= z_ext;
                    v_est <= 0;
                end else begin
                    S = Pxx + R;

                    Kx = (Pxx << 8) / S;
                    Kv = (Pvx << 8) / S;

                    // 최소 Kalman 이득 보장 (optional)
                    if (Kx < 8) Kx = 8;
                    if (Kv < 8) Kv = 8;

                    x_est <= x_pred + ((Kx * y_err) >>> 8);
                    v_est <= v_pred + ((Kv * y_err) >>> 8);

                    // 속도 클리핑
                    if (v_est > 16'sd512)  v_est <= 16'sd512;
                    else if (v_est < -16'sd512) v_est <= -16'sd512;

                    // 공분산 업데이트
                    Pxx = Pxx - ((Kx * Pxx) >>> 8);
                    Pxv = Pxv - ((Kx * Pxv) >>> 8);
                    Pvx = Pvx - ((Kv * Pxx) >>> 8);
                    Pvv = Pvv - ((Kv * Pxv) >>> 8);
                end
            end
        end
    end
endmodule



// module KalmanFilter (
//     input  logic       clk,
//     input  logic       reset,
//     input  logic       valid_in,      
//     input  logic [9:0] x_min,        
//     input  logic [9:0] y_min,        
//     input  logic [9:0] x_max,        
//     input  logic [9:0] y_max,        
//     output logic [9:0] x_min_o,        
//     output logic [9:0] y_min_o,        
//     output logic [9:0] x_max_o,        
//     output logic [9:0] y_max_o         
// );

//     // 내부 상태: 상태값, 공분산, Kalman Gain
//     logic [15:0] x_est[0:3];  // 추정값 (x_min, y_min, x_max, y_max)
//     logic [15:0] P[0:3];      // 공분산
//     logic [15:0] K[0:3];      // Kalman 이득
//     logic [15:0] z[0:3];      // 입력 측정값 (확장됨)
//     logic [15:0] diff[0:3];   // z - x_est

//     // 상수 파라미터: Q (프로세스 노이즈), R (측정 노이즈)
//     localparam logic [15:0] Q = 16'd2;     // 예측 잡음 (조정 가능)
//     localparam logic [15:0] R = 16'd20;    // 측정 잡음 (조정 가능)

//     // 추정 출력
//     assign x_min_o = x_est[0][15:6];  // 10비트 정수 출력 (fixed-point 상위 비트)
//     assign y_min_o = x_est[1][15:6];
//     assign x_max_o = x_est[2][15:6];
//     assign y_max_o = x_est[3][15:6];

//     always_ff @(posedge clk or posedge reset) begin
//         if (reset) begin
//             for (int i = 0; i < 4; i++) begin
//                 x_est[i] <= 0;
//                 P[i]     <= 16'd100;
//             end
//         end else if (valid_in) begin
//             // 입력값 확장
//             z[0] = {6'd0, x_min};
//             z[1] = {6'd0, y_min};
//             z[2] = {6'd0, x_max};
//             z[3] = {6'd0, y_max};

//             for (int i = 0; i < 4; i++) begin
//                 // 1. 예측 단계
//                 P[i] = P[i] + Q;

//                 // 2. Kalman 이득 계산
//                 K[i] = (P[i] << 8) / (P[i] + R);  // 고정소수점 대비 위해 <<8 (x256)

//                 // 3. 측정 오차
//                 diff[i] = z[i] - x_est[i];

//                 // 4. 상태 보정
//                 x_est[i] = x_est[i] + ((K[i] * diff[i]) >> 8);  // x̂ = x̂ + K * (z - x̂)

//                 // 5. 공분산 갱신
//                 P[i] = ((16'd256 - K[i]) * P[i]) >> 8;  // P = (1 - K) * P
//             end
//         end
//     end

// endmodule