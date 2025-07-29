`timescale 1ns / 1ps

module tb_mean_scale_xy;
    // Clock
    reg clk = 0;
    always #5 clk = ~clk;  // 100 MHz

    // Global reset
    reg reset;

    // MeanShiftCore control signals
    reg start;
    reg hue_max_done;
    reg framedone;
    wire center_valid;

    // ROI bounds (loopback outputs of xy_min_max_calc)
    wire [9:0] x_min, x_max, y_min, y_max;

    // MeanShift outputs
    wire [31:0] M00, M10, M01, M20, M02;
    wire [9:0]  ms_xc, ms_yc;

    // scale_Calc outputs
    wire [9:0] sc_xc, sc_yc, w, h;
    wire       scale_done;

    // ROIrData: now random 0~255 each clock
    reg [11:0] ROIrData;
    always_ff @(posedge clk) begin
        ROIrData <= 1;
    end

    // Instantiate MeanShiftCore
    MeanShiftCore U_MS (
      .clk         (clk),
      .reset       (reset),
      .hue_max_done(hue_max_done),
      .framedone   (framedone),
      .scale_done  (scale_done),
      .start       (start),
      .x_min       (x_min),
      .y_min       (y_min),
      .x_max       (x_max),
      .y_max       (y_max),
      .en_rd       (),        
      .ROIAddr     (),        
      .ROIrData    (ROIrData),
      .M00         (M00),
      .M10         (M10),
      .M01         (M01),
      .M20         (M20),
      .M02         (M02),
      .x_center    (ms_xc),
      .y_center    (ms_yc),
      .center_valid(center_valid)
    );

    // Instantiate scale_Calc
    scale_Calc U_SC (
      .clk         (clk),
      .reset       (reset),
      .M00         (M00),
      .M10         (M10),
      .M01         (M01),
      .M20         (M20),
      .M02         (M02),
      .x_center    (ms_xc),
      .y_center    (ms_yc),
      .center_valid(center_valid),
      .o_x_center  (sc_xc),
      .o_y_center  (sc_yc),
      .o_width     (),
      .o_hegiht    (),
      .w           (w),
      .h           (h),
      .scale_done  (scale_done)
    );

    // Instantiate xy_min_max_calc
    xy_min_max_calc U_XY (
      .clk        (clk),
      .reset      (reset),
      .x_center   (sc_xc),
      .y_center   (sc_yc),
      .w          (w),
      .h          (h),
      .scale_done (scale_done),
      .x_min      (x_min),
      .x_max      (x_max),
      .y_min      (y_min),
      .y_max      (y_max)
    );

    integer i;
    initial begin
        // reset
        reset = 1;  start = 0; hue_max_done = 0; framedone = 0;
        #20 reset = 0;
        #10;

        // 5번 반복
        for (i = 0; i < 5; i = i + 1) begin
            // 1) start 펄스
            #10 start = 1; #10 start = 0;
            // 2) hue_max_done 펄스
            #10 hue_max_done = 1; #10 hue_max_done = 0;
            // 3) framedone 펄스
            #20 framedone = 1; #10 framedone = 0;
            // 4) 동작 완료 대기
            wait(center_valid);
            wait(scale_done);
            #5;

            // 결과 출력
            $display("Iter %0d: MS center=(%0d,%0d), w,h=(%0d,%0d), ROI x[%0d..%0d], y[%0d..%0d]",
                     i, ms_xc, ms_yc, w, h, x_min, x_max, y_min, y_max);
        end

        $finish;
    end
endmodule
