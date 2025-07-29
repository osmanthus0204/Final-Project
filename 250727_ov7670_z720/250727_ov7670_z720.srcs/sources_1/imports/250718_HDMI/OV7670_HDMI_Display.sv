`timescale 1ns / 1ps



module OV7640_HDMI_Display (
    //global signals
    input  logic       clk,
    input  logic       reset,
    input  logic       sccb_start,
    input  logic       btn_Histogram,
    //ov2640 signals
    output logic       ov7670_xclk,
    input  logic       ov7670_pclk,
    input  logic       ov7670_href,
    input  logic       ov7670_v_sync,
    input  logic [7:0] ov7670_data,
    output logic        SCL,
    output logic        SDA,
    //export signals
	output [2:0] TMDSp, TMDSn,
	output TMDSp_clock, TMDSn_clock,
    output logic [3:0] led_state
);

    logic        we;
    logic [16:0] wAddr;
    logic [15:0] wData;
    logic [16:0] rAddr;
    logic [15:0] rData;
    logic [ 9:0] h_counter_o;
    logic [ 7:0] v_counter_o;
    logic ov7670_pclk_f, ov7670_pclk_ff;

    logic        DE;
    logic        rclk;
    logic        oe;

    logic        w_sccb_start;

// 각종 필터및 캠쉬프트

    logic [9:0] x_center, y_center;
    
    logic [7:0] HSV_Filtered_Data;
    logic [12:0] max_value;
    logic [12:0] hueFreq;
    logic [12:0] hueFreqMax;
    logic frame_done;
    logic hue_max_done;

    logic [40:0] M00;
    logic [40:0] M10;
    logic [40:0] M01;
    logic [40:0] M20;
    logic [40:0] M02;

    logic center_valid;
    logic [9:0] x_min,y_min,x_max,y_max;
    logic [16:0] ROIAddr;
    logic [16:0] rAddr_320x240_back;
    logic [11:0]BrData;
    logic [11:0]rDataTest;
    logic ov7670_v_sync_prev;


    always_ff @( posedge clk, posedge reset ) begin
        if(reset) begin
            ov7670_pclk_f <= 0;
            ov7670_pclk_ff <=0;            
        end
        else begin
            ov7670_pclk_f <= ov7670_pclk;
            ov7670_pclk_ff <= ov7670_pclk_f;
        end
    end


    always_ff @(posedge ov7670_pclk_ff or posedge reset) begin
        if (reset) ov7670_v_sync_prev <= 0;
        else ov7670_v_sync_prev <= ov7670_v_sync;
    end
    assign frame_done = (ov7670_v_sync_prev && !ov7670_v_sync);


    btn_debounce U_btn_debounce(
        .clk(clk),
        .reset(reset),
        .i_btn(sccb_start),
        .o_btn(w_sccb_start)
    );

    btn_debounce U_btn_debounce2(
        .clk(ov7670_pclk_ff),
        .reset(reset),
        .i_btn(btn_Histogram),
        .o_btn(w_btn_Histogram)
    );

    pixel_clk_gen U_OV7670_Clk_Gen (
        .clk  (clk),
        .reset(reset),
        .pclk (ov7670_xclk)
    );


    OV7670_MemController U_OV7670_MemController (
        .pclk       (ov7670_pclk_ff),
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



    SCCB_intf U_SCCB_intf(
    .clk(clk),
    .reset(reset),
    .start_btn(w_sccb_start),
    .SCL(SCL),
    .SDA(SDA)
    );    

    frame_buffer U_FrameBuffer (
    .h_counter_o(h_counter_o),
    .v_counter_o(v_counter_o),
    //write side
    .wclk(ov7670_pclk_ff), // pclk
    .we(we), //write enable
    .wAddr(wAddr),
    .wData(wData),
    //read side
    .rclk(rclk),
    .oe(oe), //ouput enable
    .rAddr(rAddr),
    .rData(rData)
);


    HSV_Filter U_HSV_Filter (
        .rData            (wData),
        .HSV_Filtered_Data(HSV_Filtered_Data)
    );

    Histogram U_Histogram (
        .clk(ov7670_pclk_ff),
        .reset(reset),
        .btn_start(w_btn_Histogram),
        .frame_done(frame_done),
        .h_counter(h_counter_o),
        .v_counter(v_counter_o),
        .hue(HSV_Filtered_Data),
        .hueFreqMax(hueFreqMax),
        .rData(hueFreq),
        .led_state(led_state),
        .hue_max_done(hue_max_done)
    );


    BackProjection U_BackProjection (
        .clk (ov7670_pclk_ff),
        .rclk(clk),


        .v_counter_o(v_counter_o),
        .h_counter_o(h_counter_o),

        .rAddr       (ROIAddr),
        .hueFreq     (hueFreq),
        .hueFreqMax  (hueFreqMax),    // 히스토그램 최대값
        .hue_max_done(hue_max_done),
        .rData       (BrData)
    );

    BackProjection U_BackProjection2 (
        .clk (ov7670_pclk_ff),
        .rclk(clk),


        .v_counter_o(v_counter_o),
        .h_counter_o(h_counter_o),

        .rAddr       (rAddr_320x240_back),
        .hueFreq     (hueFreq),
        .hueFreqMax  (hueFreqMax),     // 히스토그램 최대값
        .hue_max_done(hue_max_done),
        .rData       (rDataTest)
    );




    MeanShiftCore U_MeanShiftCore (
        .clk(ov7670_pclk_ff),
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
        .ROIrData(BrData),
        .M00(M00),
        .M10(M10),
        .M01(M01),
        .M20(M20),
        .M02(M02),
        .x_center(x_center),
        .y_center(y_center),
        .center_valid(center_valid)
    );

logic [9:0] o_x_center, o_y_center, o_width, o_hegiht, w, h;

    scale_Calc scale_Calc(
        .clk(ov7670_pclk_ff),
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
        .clk(ov7670_pclk_ff),
        .reset(reset),
        .x_center(o_x_center),
        .y_center(o_y_center),
        .w(w),
        .h(h),
        .scale_done(scale_done),
        .x_min(x_min),
        .x_max(x_max),
        .y_min(y_min),
        .y_max(y_max)
    );



    HDMI_TX_TOP U_HDMI_TX_TOP(
        .clk(clk),  //  100MHz
        //frame buffer side
        .rclk(rclk), // 25MHz
        .DE(oe),
        .rAddr(rAddr_320x240_back),
        .rData(rDataTest),
        //export side
        .TMDSp(TMDSp),
        .TMDSn(TMDSn),
        .TMDSp_clock(TMDSp_clock),
        .TMDSn_clock(TMDSn_clock),
        .x_min(x_min),
        .y_min(y_min),
        .x_max(x_max),
        .y_max(y_max)
    );


endmodule


module pixel_clk_gen (
    input  logic clk,    //100MHz
    input  logic reset,
    output logic pclk
);

    logic [1:0] p_counter;

    always_ff @(posedge clk, posedge reset) begin  //25MHz 1tick generator
        if (reset) begin
            p_counter <= 0;
            pclk      <= 1'b0;
        end else begin
            if (p_counter == 3) begin
                p_counter <= 0;
                pclk      <= 1'b1;
            end else begin
                p_counter <= p_counter + 1;
                pclk      <= 1'b0;
            end
        end
    end
endmodule


module xy_min_max_calc(
    input logic clk,
    input logic reset,
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
        if(reset) begin
            x_min <= 80;
            x_max <= 120;
            y_min <= 60;
            y_max <= 90;
        end
        else begin
            if(scale_done) begin
                
                if(x_center > w) x_min <= x_center - w;
                else x_min <= 4;
                if(x_center < 640 - w) x_max <= x_center + w;
                else x_max <= 635 ;
                if(y_center > h) y_min <= y_center - h;
                else y_min <= 4;
                if(y_center < 480 - h) y_max <= y_center + h;
                else y_max <= 475;
            end
        end
    end

endmodule

