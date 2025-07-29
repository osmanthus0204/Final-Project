`timescale 1ns/1ps

module tb_ScaleController();

    // Inputs
    logic        clk, reset, center_valid;
    logic [31:0] M00, M10, M01, M20, M02;
    logic [9:0]  x_center, y_center;

    // Outputs
    logic [9:0]  o_x_center, o_y_center, o_width, o_hegiht;
    logic        scale_done;

    // Instantiate DUT
     scale_Calc dut (
        .clk(clk),
        .reset(reset),
        .center_valid(center_valid),
        .M00(M00),
        .M10(M10),
        .M01(M01),
        .M20(M20),
        .M02(M02),
        .x_center(x_center),
        .y_center(y_center),
        .o_x_center(o_x_center),
        .o_y_center(o_y_center),
        .o_width(o_width),
        .o_hegiht(o_hegiht),
        .scale_done(scale_done)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Stimulus
    initial begin
        // 기본 세팅
        reset = 1; center_valid = 0;
        M00 = 0; M10 = 0; M01 = 0; M20 = 0; M02 = 0;
        x_center = 0; y_center = 0;
        #20;
        reset = 0;
        #20;

        // 모멘트 및 중심 좌표 입력 (임의값 예시)
        // (아래는 M20/M00, M02/M00 값이 각각 (x_center^2 + 100), (y_center^2 + 225)라 가정)
        M00 = 1000;
        x_center = 30;
        y_center = 40;
        M20 = (x_center * x_center + 100) * M00;
        M02 = (y_center * y_center + 225) * M00;
        M10 = x_center * M00;
        M01 = y_center * M00;

        // 검증 시작
        @(negedge clk);
        center_valid = 1;
        @(negedge clk);
        center_valid = 0;

        // scale_done 신호 기다리기
        wait(scale_done == 1);

        // 결과 출력
        $display("Result: x_center=%d, y_center=%d, width=%d, height=%d", o_x_center, o_y_center, o_width, o_hegiht);

        // 예시: 더 검증할 값 입력
        @(negedge clk);
        M00 = 400;
        x_center = 20;
        y_center = 25;
        M20 = (x_center * x_center + 64) * M00;
        M02 = (y_center * y_center + 121) * M00;
        M10 = x_center * M00;
        M01 = y_center * M00;

        @(negedge clk);
        center_valid = 1;
        @(negedge clk);
        center_valid = 0;

        wait(scale_done == 1);
        $display("Result: x_center=%d, y_center=%d, width=%d, height=%d", o_x_center, o_y_center, o_width, o_hegiht);

        #100 $finish;
    end

endmodule
