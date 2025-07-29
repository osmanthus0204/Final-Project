`timescale 1ns / 1ps

module OV7670_VGA_Display (
    //global signals
    input  logic       clk,
    input  logic       reset,
    //
    //input  logic       up_btn,
    input  logic       down_btn,
    input  logic       select,
    input  logic       btn_Histogram,
    //
    input  logic       sw_emoji,
    input  logic       sw_cursor_color,
    input  logic       sw_cursor_size,
    input  logic       sw_filter,
    input  logic       sw_all_clear,
    input  logic       sw_erase,
    input  logic       write_btn,
    //
    input  logic [3:0] sw_select_area,
    //ov7670 signals
    output logic       ov7670_xclk,
    input  logic       ov7670_pclk,
    input  logic       ov7670_href,
    input  logic       ov7670_v_sync,
    input  logic [7:0] ov7670_data,
    //export signals
    output logic       h_sync,
    output logic       v_sync,
    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port,
    input  logic       start_button,
    output logic       SCL,
    output logic       SDA,
    output logic [3:0] fndCom,
    output logic [7:0] fndFont,

    //uart
    //input logic uart_start_btn,
    output logic tx,
    output logic uart_tx,
    output logic cu_state,
    output logic [1:0] vga_state,
    input logic gesture_btn,

    //    output logic [11:0] led

    output logic [5:0] led_state
);

    logic gesture_btn2;
    logic i_uart_start_btn;
    logic [9:0] smoothed_col, smoothed_col1;
    logic [9:0] smoothed_row, smoothed_row1;
    logic [8:0] gesture_detected;
    logic [7:0] gesture_number;
    logic gesture_valid;
    logic gesture_done;
    logic [9:0] o_movement;
    logic [8:0] o_x_dis;
    logic [8:0] o_x_sum;
    logic clk_10hz;


    logic [11:0] qvgaMemData;

    logic w_start_button;
    logic w_up_btn, w_down_btn;


    logic [ 3:0] filter_number;
    logic [ 3:0] cursor_size_number;
    logic [ 2:0] cursor_color_number;

    logic        we;
    logic [16:0] wAddr;
    logic [15:0] wData;


    logic [11:0] filtered_data;

    logic        w_btn_Histogram;

    logic [11:0] rData;

    logic [11:0] cursor_rData, draw_rData;


    logic       DE;
    logic [9:0] x_pixel;
    logic [9:0] y_pixel;
    logic w_rclk, rclk;
    logic        oe;

    logic [11:0] qvga_rData;

    logic [16:0] rAddr_320x240;
    logic [16:0] rAddr_160x120;

    logic [ 2:0] photo_area;  // photo area

    logic [ 2:0] updown_select;

    logic [ 3:0] pen_data;  // isp_for_pen output

    logic [13:0] fndData;

    logic [ 9:0] h_counter_o;
    logic [ 7:0] v_counter_o;
    logic [11:0] original_color;

    //uart
    logic [ 7:0] tx_data;
    logic [1:0] state, state_next;
    logic two_byte_done, tx_finish, keep_start, all_trans_complete;
    logic [9:0] x_count, y_count, x_coord, y_coord;

    logic hue_max_done;

    logic [40:0] M00;
    logic [40:0] M10;
    logic [40:0] M01;
    logic [40:0] M20;
    logic [40:0] M02;
    logic [9:0] o_x_center;
    logic [9:0] o_y_center;
    logic [9:0] o_width;
    logic [9:0] o_hegiht;



    localparam IDLE = 0, WAIT = 1, FIRST = 2;


    assign uart_tx = tx;
    assign original_color = {wData[15:12], wData[10:7], wData[4:1]};

    always_comb begin
        casex (sw_select_area)
            4'b0001: photo_area = 3'd0;
            4'b001x: photo_area = 3'd1;
            4'b01xx: photo_area = 3'd2;
            4'b1xxx: photo_area = 3'd3;
            default: photo_area = 3'd4;
        endcase
    end

    always_comb begin
        casex ({
            sw_cursor_color, sw_cursor_size, sw_filter
        })
            3'b001:  updown_select = 3'b001;
            3'b01x:  updown_select = 3'b010;
            3'b1xx:  updown_select = 3'b100;
            default: updown_select = 3'b001;
        endcase
    end

    btn_debounce U_btn_debounce_Histogram (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_Histogram),
        .o_btn(w_btn_Histogram)
    );

    btn_debounce U_btn_debounce_StartButton (
        .clk  (clk),
        .reset(reset),
        .i_btn(start_button),
        .o_btn(w_start_button)
    );

    logic rf_signal;

    // btn_debounce_keep U_btn_debounce_gesture (
    //     .clk  (clk),
    //     .reset(reset),
    //     .i_btn(rf_signal),
    //     .o_btn(gesture_btn2)
    // );
    
    btn_rf U_btn_rf(
        .clk(clk),         // 100MHz 시스템 클럭
        .rst(reset),         // 리셋
        .rf_signal(gesture_btn),   // RF 수신기 출력
        .signal(gesture_btn2)       // LED 출력
    );

    SCCB_intf U_SCCB_intf (
        .clk(clk),
        .reset(reset),
        .startSig(w_start_button),
        .SCL(SCL),
        .SDA(SDA)
    );


    pixel_clk_gen U_OV7670_Clk_Gen (
        .clk  (clk),
        .reset(reset),
        .pclk (ov7670_xclk)
    );

    VGA_Controller U_VGA_Controller (
        .clk    (clk),
        .pclk   (ov7670_xclk),
        .reset  (reset),
        .rclk   (w_rclk),
        .h_sync (h_sync),
        .v_sync (v_sync),
        .DE     (DE),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel)
    );


    OV7670_MemController U_OV7670_MemController (
        .pclk       (ov7670_pclk),
        .reset      (reset),
        .href       (ov7670_href),
        .v_sync     (ov7670_v_sync),
        .ov7670_data(ov7670_data),
        .h_counter_o(h_counter_o),
        .v_counter_o(v_counter_o),
        .we         (we),
        .wAddr      (wAddr),
        .wData      (wData)
    );
    logic [9:0] x_center, y_center;
    logic [7:0] HSV_Filtered_Data;
    logic [12:0] max_value;
    logic [12:0] hueFreq;
    logic [12:0] hueFreqMax;
    logic frame_done;

    HSV_Filter U_HSV_Filter (
        .rData            (wData),
        .HSV_Filtered_Data(HSV_Filtered_Data)
    );

    Histogram U_Histogram (
        .clk(ov7670_pclk),
        .reset(reset),
        .btn_start(btn_Histogram),
        .frame_done(frame_done),
        .h_counter(h_counter_o),
        .v_counter(v_counter_o),
        .hue(HSV_Filtered_Data),
        .hueFreqMax(hueFreqMax),
        .rData(hueFreq),
        .led_state(led_state),
        .hue_max_done(hue_max_done)
    );

    logic [11:0] rDataTest;

    logic [16:0] ROIAddr;
    logic [15:0] x_diff_sum, y_diff_sum;

    BackProjection U_BackProjection (
        .clk (ov7670_pclk),
        .rclk(w_rclk),


        .v_counter_o(v_counter_o),
        .h_counter_o(h_counter_o),

        .rAddr       (ROIAddr),
        .hueFreq     (hueFreq),
        .hueFreqMax  (hueFreqMax),    // 히스토그램 최대값
        .hue_max_done(hue_max_done),
        .rData       (rData)
    );

    BackProjection U_BackProjection2 (
        .clk (ov7670_pclk),
        .rclk(w_rclk),


        .v_counter_o(v_counter_o),
        .h_counter_o(h_counter_o),

        .rAddr       (rAddr_320x240),
        .hueFreq     (hueFreq),
        .hueFreqMax  (hueFreqMax),     // 히스토그램 최대값
        .hue_max_done(hue_max_done),
        .rData       (rDataTest)
    );

    // logic first;
    // logic [15:0] x_f,y_f;
    // always_ff @( posedge clk ) begin : blockName
    //     if(reset) begin
    //         state <= 0;
    //     end else begin
    //         state <= state_next;
    //     end
    // end
    // always_comb begin : blockName1
    //     state_next = state;
    //     case(state)
    //         IDLE: begin
    //             first = 0;
    //             if(btn_Histogram) begin
    //                 first = 1'b1;
    //                 state_next = WAIT;
    //             end
    //         end
    //         WAIT: if(hue_max_done) state_next = FIRST;
    //         FIRST: begin
    //             if(frame_done) begin
    //                 first = 1'b0;
    //             end
    //         end
    //     endcase

    // end

    // assign x_f = first ? 80 : x_center - 80;
    // assign y_f = first ? 60 : x_center - 60;
    // ROI 좌표 계산용 레지스터
    logic [9:0] roi_x_reg, roi_y_reg;
    logic start_prev, start_rise;

    // Edge detection for start
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            start_prev <= 1'b0;
        end else begin
            start_prev <= btn_Histogram;
        end
    end

    logic [9:0] w,h,meanshift_w,meanshift_h;

    // assign start_rise = btn_Histogram & ~start_prev;

    // // ROI 좌표 초기화 및 갱신
    // always_ff @(posedge ov7670_pclk or posedge reset) begin
    //     if (reset) begin
    //         roi_x_reg <= 80;
    //         roi_y_reg <= 60;
    //         meanshift_w <= 40;
    //         meanshift_h <= 30;
    //     end else if (start_rise) begin
    //         roi_x_reg <= 80;
    //         roi_y_reg <= 60;
    //         meanshift_w <= 40;
    //         meanshift_h <= 30;
    //     end else if (scale_done) begin
    //         meanshift_w <= w;
    //         meanshift_h <= h;
    //         // x 방향 보정 (0 ~ 160)
    //         if (o_x_center < w) roi_x_reg <= 0;
    //         else if (o_x_center > 640-w)  // 239 이상이면 159 이상 나옴 → 320-160
    //             roi_x_reg <= 409-w;
    //         else roi_x_reg <= o_x_center - w;

    //         // y 방향 보정 (0 ~ 120)
    //         if (o_y_center < h) roi_y_reg <= 0;
    //         else if (o_y_center > 480-h)  // 179 이상이면 119 이상 나옴 → 240-120
    //             roi_y_reg <= 479-h;
    //         else roi_y_reg <= o_y_center - h;
    //     end
    // end

    logic [9:0] x_min, x_max, y_min, y_max;
    logic [9:0] x_min_filt, x_max_filt, y_min_filt, y_max_filt;

    MeanShiftCore U_MeanShiftCore (
        .clk(ov7670_pclk),
        .reset(reset),
        .start(btn_Histogram),
        .hue_max_done(hue_max_done),
        .framedone(frame_done),
        .x_min(x_min),
        .y_min(y_min),
        .x_max(x_max),  // 
        .y_max(y_max),
        .en_rd(),
        .scale_done(scale_done),
        .ROIAddr(ROIAddr),
        .ROIrData(rData),
        .M00(M00),
        .M10(M10),
        .M01(M01),
        .M20(M20),
        .M02(M02),
        .x_center(x_center),
        .y_center(y_center),
        .center_valid(center_valid)
    );


    scale_Calc scale_Calc(
    .clk(ov7670_pclk),
    .reset(reset),
    .M00(M00),
    .M10(M10),
    .M01(M01),
    .M20(M20),
    .M02(M02),
    .x_center(x_center),
    .y_center(y_center),
    .center_valid(center_valid),
    .o_x_center(o_x_center),
    .o_y_center(o_y_center),
    .o_width(o_width),
    .o_hegiht(o_hegiht),
    .w(w),
    .h(h),
    .scale_done(scale_done)
    );

    xy_min_max_calc xy_min_max_calc(
    .clk(ov7670_pclk),
    .reset(reset),
    .btn_Histogram(btn_Histogram),
    .x_center(x_center),
    .y_center(y_center),
    .w(10'd40),
    .h(10'd30),
    .scale_done(scale_done),
    .x_min(x_min),
    .x_max(x_max),
    .y_min(y_min),
    .y_max(y_max)
    );  




    ISP_for_pen U_ISP_PEN (
        .clk                (clk),
        .ov7670_pclk        (ov7670_pclk),
        .reset              (reset),
        .ov7670_v_sync      (ov7670_v_sync),
        .wData              (wData),
        .v_counter_o        (v_counter_o),
        .h_counter_o        (h_counter_o),
        .sw_erase           (0),
        .up_btn             (0),
        .down_btn           (0),
        .select_cursor_size (),                     // sw_cursor_size
        .select_cursor_color(),                     //sw_cursor_color
        .data_out           (pen_data),
        .cursor_size        (cursor_size_number),
        .cursor_color       (cursor_color_number),
        .emoji_select       (0),
        .smoothed_col       (smoothed_col),
        .smoothed_row       (smoothed_row),
        .frame_done         (frame_done)
    );


    frame_buffer_320x240 U_FrameBuffer_320x240 (
        .photo_area (photo_area),
        .h_counter_o(h_counter_o),
        .v_counter_o(v_counter_o),
        //write side
        .wclk       (ov7670_pclk),
        .we         (we),
        .wAddr      (wAddr),
        .wData      (original_color),
        //read side
        .rclk       (w_rclk),
        .oe         (oe),
        .rAddr      (rAddr_320x240),
        .rData      (qvga_rData)
    );

    clk_div_100M_to_10Hz U_clk_div_100m_to_10 (
        .clk     (clk),      // 100MHz input clock
        .reset   (reset),    // active-high synchronous reset
        .clk_10Hz(clk_10hz)  // 10Hz output clock
    );

    logic [8:0] x_dis_clk, y_dis_clk, x_dis_fclk, y_dis_fclk;

    dis_x_y dis_clk(
    .clk(clk),
    .reset(reset),
    .smoothed_col(smoothed_col),
    .smoothed_row(smoothed_row),
    .x_dis(x_dis_clk),
    .y_dis(y_dis_clk)
);

dis_x_y dis_fclk(
    .clk(clk_10hz),
    .reset(reset),
    .smoothed_col(smoothed_col),
    .smoothed_row(smoothed_row),
    .x_dis(x_dis_fclk),
    .y_dis(y_dis_fclk)
);


    frame_buffer_160x120_cursor U_FRAME_BUFFER_160x120_cursor (
        //write side
        .wclk       (ov7670_pclk),
        .we         (we),
        .h_counter_o(h_counter_o),
        .v_counter_o(v_counter_o),
        .wData_color(pen_data),
        //read side
        .rclk       (w_rclk),
        .oe         (oe),
        .rAddr      (rAddr_160x120),
        .rData_rgb  (cursor_rData)
    );

    mux3x1 U_MUX_3X1 (
        .switch(cursor_rData),
        .x0    (rDataTest),
        .x1    (cursor_rData),
        .y     (qvgaMemData)                 //rData)
    );

    //         mux_2x1 U_MUX_X(
    //         .sel(keep_start),
    //         .x0(x_pixel),
    //         .x1(x_count),
    //         .y(x_coord)
    //     );
    //     mux_2x1 U_MUX_Y(
    //         .sel(keep_start),
    //         .x0(y_pixel),
    //         .x1(y_count),
    //         .y(y_coord)
    // );

    logic motor_trigger;
    logic [7:0] dirData;

    QVGA_MemController U_QVGA_MemController (
        //VGA Controller side
        .clk          (w_rclk),
        .reset        (reset),
        .x_pixel      (x_pixel),
        .y_pixel      (y_pixel),
        .DE           (DE),
        //frame buffer side
        .rclk         (rclk),
        .d_en         (oe),
        .rAddr_320x240(rAddr_320x240),
        .rAddr_160x120(rAddr_160x120),
        .rData        (qvgaMemData),
        //export side
        .red_port     (red_port),
        .green_port   (green_port),
        .blue_port    (blue_port),

        .x_min          (x_min),
        .y_min          (y_min),
        .x_max          (x_max),
        .y_max          (y_max),
        .smoothed_col(smoothed_col),
        .smoothed_row(smoothed_row),
        .frame_done(frame_done),
        .start_trigger(motor_trigger),
        .dirData(dirData)
    );





    // mux_14bit #(.switch(3)) U_Mux_14bit(
    //     .sel(updown_select),
    //     .x0(),
    //     .x1(cursor_size_number),
    //     .x2(cursor_color_number),
    //     .y(fndData)
    // );


    fndController U_FndController (
        .clk    (clk),
        .reset  (reset),
        .fndData(o_x_sum),
        .fndDot (4'b1111),
        .fndCom (fndCom),
        .fndFont(fndFont)
    );
 gesture U_gesture(
    .clk(clk),
    .fclk(clk_10hz),
    .reset(reset),
    .btn_start(gesture_btn2),
    .x_dis_clk(x_dis_clk),
    .y_dis_clk(y_dis_clk),
    .x_dis_fclk(x_dis_fclk), 
    .y_dis_fclk(y_dis_fclk), 
    .o_gesture_detected(gesture_detected),
    .o_gesture_done(gesture_done),
    .led(),
    .o_movement(o_movement),
    .o_x_sum(o_x_sum)
    );

    // gesture U_gesture (
    //     .clk               (clk),
    //     .fclk              (clk_10hz),
    //     .reset             (reset),
    //     .btn_start         (gesture_btn2),
    //     .x_first           (smoothed_col),
    //     .y_first           (smoothed_row),
    //     .x_second          (smoothed_col1),
    //     .y_second          (smoothed_row1),
    //     .o_gesture_detected(gesture_detected),
    //     .o_gesture_valid   (gesture_valid), //uart start(gesture)
    //     .led               (),                  //led),
    //     .o_movement        (o_movement),
    //     .o_x_dis           (o_x_dis),
    //     .o_x_sum           (o_x_sum)
    // );

    gesture_to_number U_gesture_to_number (
        .gesture_detected(gesture_detected),
        .gesture_number  (gesture_number)
    );
    // assign tx_data = gesture_done ? gesture_number : (motor_trigger ? dirData : 0);

    logic prev;

    always_ff @( posedge clk ) begin 
       prev <= gesture_done;
    end
    logic ges_done_f;
    assign ges_done_f = ~prev & gesture_done;


    always_comb begin 
        case ({ges_done_f,motor_trigger})
            2'b00: tx_data = 0; 
            2'b01: tx_data = dirData;
            2'b10: tx_data = gesture_number;
            2'b11: tx_data = gesture_number;
        endcase
    end

    UART_TX U_uart (
        .clk          (clk),
        .rst          (reset),
        .tick         (tick),
        .start_trigger(motor_trigger| ges_done_f),
        .data_in      (tx_data),
        .o_tx         (tx),
        .o_tx_done    ()
    );

    baud_tick_genp U_tick_gen (
        .clk      (clk),
        .rst      (reset),
        .baud_tick(tick)
    );

endmodule

module mux_2x1 (
    input logic sel,
    input logic [9:0] x0,
    input logic [9:0] x1,
    output logic [9:0] y
);
    always_comb begin
        case (sel)
            0: y = x0;
            1: y = x1;
            default: y = x0;
        endcase
    end
endmodule

module mux3x1 (
    input logic [11:0] switch,
    input logic [11:0] x0,  // qvga_rData
    input logic [11:0] x1,  //cursor_rData
    // input logic [11:0] x2,  //draw_rData
    output logic [11:0] y
);

    logic sel;

    always_comb begin
        if (switch == 12'd0) sel = 1'b0;
        else sel = 1'b1;
    end


    always_comb begin
        case (sel)
            1'b0:   y = x0;
            1'b1:   y = x1;
            // 2'b10:   y = x2;
            default: y = x0;
        endcase
    end
endmodule

module mux_14bit #(
    parameter switch = 3
) (
    input logic [switch-1:0] sel,
    input logic [13:0] x0,
    input logic [13:0] x1,
    input logic [13:0] x2,
    output logic [13:0] y
);

    always_comb begin
        casex (sel)
            3'b001:  y = x0;
            3'b010:  y = x1;
            3'b100:  y = x2;
            default: y = 0;
        endcase
    end
endmodule

module reg_x_y (
    input logic clk,
    input logic reset,
    input logic [7:0] smoothed_col,
    input logic [7:0] smoothed_row,
    output logic [7:0] smoothed_col1,
    output logic [7:0] smoothed_row1
);

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            smoothed_col1 <= 0;
            smoothed_row1 <= 0;
        end else begin
            smoothed_col1 <= smoothed_col;
            smoothed_row1 <= smoothed_row;
        end
    end


endmodule

module clk_div_100M_to_10Hz (
    input  logic clk,      // 100MHz input clock
    input  logic reset,    // active-high synchronous reset
    output logic clk_10Hz  // 10Hz output clock
);

    // 100MHz → 10Hz 분주: 1초에 10번 토글 → 한 쪽 주기 = 5,000,000 클럭
    localparam COUNT_MAX = 5_000_000 - 1;

    logic [22:0] counter = 0;  // 23비트면 최대 8백만 이상 가능
    logic toggle_clk = 0;

    always_ff @(posedge clk) begin
        if (reset) begin
            counter    <= 0;
            toggle_clk <= 0;
        end else begin
            if (counter == COUNT_MAX) begin
                counter    <= 0;
                toggle_clk <= ~toggle_clk;
            end else begin
                counter <= counter + 1;
            end
        end
    end

    assign clk_10Hz = toggle_clk;

endmodule

module xy_min_max_calc(
    input logic clk,
    input logic reset,
    input logic btn_Histogram,
    input logic [9:0] x_center,
    input logic [9:0] y_center,
    input logic [9:0] w,
    input logic [9:0] h,
    input logic scale_done,
    output logic [9:0] x_min,
    output logic [9:0] x_max,
    output logic [9:0] y_min,
    output logic [9:0] y_max
);

    always_ff @( posedge clk, posedge reset ) begin
        if(reset || btn_Histogram) begin
            x_min <= 80;
            x_max <= 160;
            y_min <= 60;
            y_max <= 120;
        end
        else begin
            if(scale_done) begin
                if (x_center < w) begin
                    x_min <= 4;
                    x_max <= 4+(w<<1);
                end else if (x_center > 640-w) begin
                    x_min <= 635-(w<<1);
                    x_max <= 635;
                end else begin
                    x_min <= x_center - w;
                    x_max <= x_center + w;
                end

                if (y_center < h) begin
                    y_min <= 4;
                    y_max <= 4+(h<<1);
                end else if (y_center > 480-h) begin
                    y_min <= 475-(h<<1);
                    y_max <= 475;
                end else begin
                    y_min <= y_center - h;
                    y_max <= y_center + h;
                end
            end
        end
    end

endmodule