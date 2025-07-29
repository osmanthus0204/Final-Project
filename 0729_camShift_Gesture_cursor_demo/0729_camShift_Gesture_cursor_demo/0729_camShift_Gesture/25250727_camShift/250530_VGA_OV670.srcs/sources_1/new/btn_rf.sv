module btn_rf(
    input  logic clk,         // 100MHz 시스템 클럭
    input  logic rst,         // 리셋
    input  logic rf_signal,   // RF 수신기 출력
    output logic signal       // LED 출력
);

    logic rf_sync_1, rf_sync_2;
    logic [20:0] high_counter;
    logic [23:0] low_counter;

    // 시간 기준 (100MHz 기준)
    parameter integer HIGH_THRESHOLD = 21'd100_000;   // 1ms
    parameter integer LOW_THRESHOLD  = 24'd1_000_000; // 10ms

    // 동기화
    always_ff @(posedge clk, posedge rst) begin
        if(rst) begin
            rf_sync_1 <= 0;
            rf_sync_2 <= 0;
        end
        else begin
            rf_sync_1 <= rf_signal;
            rf_sync_2 <= rf_sync_1;
        end
    end

assign singal =  rf_sync_2;

    // always_ff @(posedge clk or posedge rst) begin
    //     if (rst) begin
    //         signal <= 0;
    //         high_counter <= 0;
    //         low_counter <= 0;
    //     end else begin
    //         if (rf_sync_2) begin    // HIGH 상태
    //             high_counter <= high_counter + 1;
    //             low_counter <= 0;
    //             if (high_counter >= HIGH_THRESHOLD)
    //                 signal <= 1;
    //         end else begin          // LOW 상태
    //             high_counter <= 0;
    //             low_counter <= low_counter + 1;
    //             if (low_counter >= LOW_THRESHOLD)
    //                 signal <= 0;
    //         end
    //     end
    // end

endmodule