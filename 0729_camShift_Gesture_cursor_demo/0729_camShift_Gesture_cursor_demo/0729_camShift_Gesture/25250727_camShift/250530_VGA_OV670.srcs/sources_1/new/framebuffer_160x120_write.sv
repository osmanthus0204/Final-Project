`timescale 1ns / 1ps



module frame_buffer_160x120_draw_erase (
    //write side
    input  logic        all_clear,
    input  logic        erase,
    input  logic        write_btn,
    input  logic        wclk,
    input  logic        we,           //write enable
    input  logic [ 9:0] h_counter_o,
    input  logic [ 7:0] v_counter_o,
    input  logic [ 3:0]  wData_color,
    //read side
    input  logic        rclk,
    input  logic        oe,           //ouput enable
    input  logic [16:0] rAddr,
    output logic [11:0] rData_rgb
);
    logic [3:0] mem[0:(160*120 -1)];
    logic [16:0] wAddr;

    assign wAddr = (h_counter_o[9:2]) + (v_counter_o[7:1]) * 160;

    //write side
    always_ff @(posedge wclk) begin : write_side
        if (we && all_clear) begin //all clear
            mem[wAddr] <= 4'd0;
        end else if (we && write_btn) begin 
            if (!erase) begin //draw
                if (wData_color != 4'd0) mem[wAddr] <= wData_color;
            end else begin         //erase
                if (wData_color != 0) mem[wAddr] <= 4'd0;
            end
        end
    end
    // read side
    always_ff @(posedge rclk) begin : read_side
        if (oe) begin
            case (mem[rAddr])
                4'd0: rData_rgb = 12'h000;  //투명(빈 데이터)
                4'd1: rData_rgb = 12'hf00;  // 빨 
                4'd2: rData_rgb = 12'hf80;  // 주
                4'd3: rData_rgb = 12'hff0;  // 노
                4'd4: rData_rgb = 12'h0f0;  // 초
                4'd5: rData_rgb = 12'h00f;  // 파
                4'd6: rData_rgb = 12'h358;  // 남
                4'd7: rData_rgb = 12'h80f;  // 보
                4'd8: rData_rgb = 12'h741;  // 갈
                4'd9: rData_rgb = 12'hfff;  // 흰
                4'd10: rData_rgb = 12'h001;  // 검
                default: rData_rgb = 12'h000;  //투명(빈 데이터)            
            endcase
        end
    end

endmodule
