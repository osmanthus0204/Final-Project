`timescale 1ns / 1ps

module BackProjection (
    input logic clk,
    input logic rclk,
    input logic [7:0] v_counter_o,
    input logic [9:0] h_counter_o,
    input logic [16:0] rAddr,
    input logic [12:0] hueFreq,
    input logic [12:0] hueFreqMax,  // 히스토그램 최대값
    input logic hue_max_done,
    output logic [11:0] rData
);

    logic [11:0] probData;

    SimilarityCalc U_SimilarityCalc (
        .hueFreq(hueFreq),
        .hueFreqMax(hueFreqMax),
        .hue_max_done(hue_max_done),
        .wData(probData)
    );

    BPBuffer U_BPBuffer (
        .clk  (clk),
        .rclk (rclk),
        .en_rd(1),
        .v_counter_o(v_counter_o),
        .h_counter_o(h_counter_o),
        .rAddr(rAddr),
        .wData(probData),
        .rData(rData)
    );

endmodule

module SimilarityCalc (
    input  logic [12:0] hueFreq,   // LUT에서 읽은 hist[hue] 값 (0~4095 가능성 있음)
    input logic [12:0] hueFreqMax,  // 히스토그램 최대값
    input logic hue_max_done,
    output logic [11:0] wData  // 12-bit grayscale RGB (4-4-4)
);

    logic [15:0] scaled;  // 확률값 정규화 결과 (최대 12bit * 8bit)
    logic [12:0] threshold;

    // always_comb begin
    //     if (hue_max_done && hueFreqMax != 0) begin
    //         // threshold = hueFreqMax * 3 / 10 (≈ 30%)
    //         threshold = (hueFreqMax * 3) / 10;

    //         if (hueFreq < threshold)
    //             scaled = 0;
    //         else
    //             scaled = (hueFreq * 8'd255) / hueFreqMax;
    //     end else begin
    //         scaled = 0;
    //     end
    // end

    always_comb begin 
        if (hue_max_done == 1) scaled = (hueFreq * 8'd255) / hueFreqMax;
        else scaled = 16'd0;
    end

    assign wData = {scaled[7:4], scaled[7:4], scaled[7:4]};

endmodule

module BPBuffer (
    input  logic        clk,
    input logic [7:0] v_counter_o,
    input logic [9:0] h_counter_o,
    input  logic [16:0] rAddr,
    input  logic [11:0] wData,
    input  logic        rclk,
    input  logic        en_rd,
    output logic [11:0] rData
);
    logic [11:0] mem[0:(320*240 -1)];
    logic [16:0] wAddr;
    assign wAddr = (h_counter_o[9:1])+ (v_counter_o[7:0])*320;  

    always_ff @(posedge clk) begin
        mem[wAddr] <= wData;
    end

    always_ff @( posedge rclk ) begin 
        if (en_rd) begin
            rData <= mem[rAddr];
        end
    end

endmodule
