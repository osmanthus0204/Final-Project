`timescale 1ns / 1ps

module MeanShiftCore_tb;

    logic clk, reset;
    logic hue_max_done, framedone;
    logic [9:0] roi_x, roi_y, roi_w, roi_h;

    logic en_rd;
    logic [16:0] ROIAddr;
    logic [11:0] ROIrData;
    logic [31:0] x_sum, y_sum, w_sum;
    logic [9:0] x_center, y_center;
    logic center_valid;

    // DUT 연결
    MeanShiftCore dut (
        .clk(clk),
        .reset(reset),
        .hue_max_done(hue_max_done),
        .framedone(framedone),
        .roi_x(roi_x),
        .roi_y(roi_y),
        .roi_w(roi_w),
        .roi_h(roi_h),
        .en_rd(en_rd),
        .ROIAddr(ROIAddr),
        .ROIrData(ROIrData),
        .x_sum(x_sum),
        .y_sum(y_sum),
        .w_sum(w_sum),
        .x_center(x_center),
        .y_center(y_center),
        .center_valid(center_valid)
    );

    // 320x240 frame
    localparam FRAME_WIDTH = 320;
    localparam FRAME_HEIGHT = 240;
    logic [11:0] fake_frame [0:FRAME_WIDTH*FRAME_HEIGHT-1];

    // 클럭 생성 (100MHz)
    always #5 clk = ~clk;

    // ROI 고정 위치
    localparam ROI_FIXED_X = 100;
    localparam ROI_FIXED_Y = 50;

    // 중심 가중치 이동 x좌표 리스트
    int high_w_x [0:2] = '{102, 106, 110};
    localparam int high_w_y = 52;

    int frame_idx = 0;

    initial begin
        $display("===== MeanShiftCore Horizontal Move Test =====");

        clk = 0;
        reset = 1;
        hue_max_done = 0;
        framedone = 0;

        roi_x = ROI_FIXED_X;
        roi_y = ROI_FIXED_Y;
        roi_w = 80;
        roi_h = 60;

        // 전체 프레임 초기화
        for (int i = 0; i < FRAME_WIDTH * FRAME_HEIGHT; i++)
            fake_frame[i] = 12'd10;

        #20 reset = 0;

        repeat (3) begin
            // 모든 픽셀 weight 초기화
            for (int i = 0; i < FRAME_WIDTH * FRAME_HEIGHT; i++)
                fake_frame[i] = 12'd10;

            // 중심 weight 부여 (frame_idx에 따라 위치 변경)
            fake_frame[high_w_y * FRAME_WIDTH + high_w_x[frame_idx]] = 12'd200;

            // 프레임 처리 시작
            #10 hue_max_done = 1;
            #10 hue_max_done = 0;
            #30 framedone = 1;
            #10 framedone = 0;

            // 중심 좌표 계산 완료 기다림
            wait (center_valid == 1);
            @(posedge clk);

            frame_idx++;
            #100;
        end

        $display("===== Simulation Finished =====");
        $finish;
    end

    // ROIAddr에 따라 fake_frame에서 ROIrData 읽어줌
    always_comb begin
        ROIrData = (en_rd) ? fake_frame[ROIAddr] : 12'd0;
    end

    // 결과 출력
    always_ff @(posedge clk) begin
        if (center_valid) begin
            $display("🟢 Frame %0d | ROI=(%0d,%0d) → Center=(%0d,%0d)", frame_idx, roi_x, roi_y, x_center, y_center);
            $display("   ▸ x_sum = %0d", x_sum);
            $display("   ▸ y_sum = %0d", y_sum);
            $display("   ▸ w_sum = %0d", w_sum);
        end
    end

endmodule






// `timescale 1ns / 1ps

// module tb_MeanShiftCore;

//     logic clk, reset;
//     logic hue_max_done, framedone;
//     logic [9:0] roi_x, roi_y, roi_w, roi_h;

//     logic en_rd;
//     logic [16:0] ROIAddr;
//     logic [11:0] ROIrData;
//     logic [31:0] x_sum, y_sum, w_sum;
//     logic [9:0] x_center, y_center;
//     logic center_valid;

//     // DUT 연결
//     MeanShiftCore dut (
//         .clk(clk),
//         .reset(reset),
//         .hue_max_done(hue_max_done),
//         .framedone(framedone),
//         .roi_x(roi_x),
//         .roi_y(roi_y),
//         .roi_w(roi_w),
//         .roi_h(roi_h),
//         .en_rd(en_rd),
//         .ROIAddr(ROIAddr),
//         .ROIrData(ROIrData),
//         .x_sum(x_sum),
//         .y_sum(y_sum),
//         .w_sum(w_sum),
//         .x_center(x_center),
//         .y_center(y_center),
//         .center_valid(center_valid)
//     );

//     // 가상 프레임 데이터 (320x240)
//     logic [11:0] fake_frame [0:76800]; // 320 * 240

//     // 클럭 생성 (100MHz)
//     always #5 clk = ~clk;

//     initial begin
//         clk = 0;
//         reset = 1;
//         hue_max_done = 0;
//         framedone = 0;

//         roi_x = 100;
//         roi_y = 50;
//         roi_w = 8;
//         roi_h = 6;

//         // 프레임 데이터 초기화
//         for (int i = 0; i < 76800; i++) begin
//             fake_frame[i] = 12'd1; // 단순화
//         end

//         // 리셋
//         #20;
//         reset = 0;

//         // hue_max_done → framedone → 시작
//         #10;
//         hue_max_done = 1;
//         #10;
//         hue_max_done = 0;

//         #30;
//         framedone = 1;
//         #10;
//         framedone = 0;

//         // 1ms 후 자동 종료
//         #1000;
//         $display("❌ Timeout: center_valid 신호 미도달");
//         $finish;
//     end

//     // ROIAddr로부터 픽셀 값 주기
//     always_comb begin
//         ROIrData = (en_rd) ? fake_frame[ROIAddr] : 12'd0;
//     end

//     // 출력 결과 모니터링
//     always_ff @(posedge clk) begin
//         if (center_valid) begin
//             $display("✅ ROI 중심 계산 완료:");
//             $display("   ▸ x_center = %d", x_center);
//             $display("   ▸ y_center = %d", y_center);
//             $display("   ▸ x_sum = %d", x_sum);
//             $display("   ▸ y_sum = %d", y_sum);
//             $display("   ▸ w_sum = %d", w_sum);
//             $finish;
//         end
//     end

// endmodule
