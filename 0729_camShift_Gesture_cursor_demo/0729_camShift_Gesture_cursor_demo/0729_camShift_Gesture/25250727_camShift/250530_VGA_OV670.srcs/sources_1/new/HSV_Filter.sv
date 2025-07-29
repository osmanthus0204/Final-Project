module HSV_Filter (
    input  logic [15:0] rData,
    output logic [7:0] HSV_Filtered_Data  // H[3:0], S[3:0], V[3:0]
);
    // RGB 565 -> RGB 888 변환
    logic [7:0] R8 = {rData[15:11], 3'b000};  // 5bit -> 8bit R
    logic [7:0] G8 = {rData[10:5], 2'b00};  // 5bit -> 8bit G
    logic [7:0] B8 = {rData[4:0], 3'b000};  // 5bit -> 8bit B

    // Cmax = max(R', G', B'), Cmin = min(R', G', B')
    logic [7:0] Cmax = (R8 > G8) ? ((R8 > B8) ? R8 : B8) : ((G8 > B8) ? G8 : B8);  // RGB 중 가장 큰 값
    logic [7:0] Cmin = (R8 > G8) ? ((G8 > B8) ? B8 : G8) : ((R8 > B8) ? B8 : R8);  // RGB 중 가장 작은 값

    // Delta = Cmax - Cmin
    logic [7:0] Delta = Cmax - Cmin;

    // Hue(색조), Saturation(채도), Value(명도) = Cmax
    logic [7:0] Hue, Sat, Value;

    assign Value = Cmax;
    logic [7:0] diff = $signed(G8) - $signed(B8);

    // H, S, V Calculation
    always_comb begin
        if (Delta == 0) begin
            Hue = 0;
        end else if (Cmax == R8) begin
            if ((diff) < 0) begin
                Hue = 43 * (G8 - B8) / Delta + 256;  // 음수 보정
            end else begin
                Hue = 43 * (G8 - B8) / Delta;
            end
        end else if (Cmax == G8) begin
            Hue = 85 + 43 * (B8 - R8) / Delta;  // Cmax가 G8과 같을 때, 85는 43 * 2
        end else begin
            Hue = 171 + 43 * (R8 - G8) / Delta;  // Cmax가 B8과 같을 때, 171은 43 * 4
        end

        if (Cmax == 0) begin
            Sat = 0;
        end else begin
            Sat = (Delta * 255) / Cmax;
        end
    end

    // 8bit -> 4bit H, S, V 
    //assign HSV_filtered_data = {Hue[7:4], Sat[7:4], Value[7:4]};
    assign HSV_Filtered_Data = {Hue[7:0]};

        // logic pixel_valid;

        // // 피부색에 따른 Valid 신호
        // always_comb begin
        //     if ((Hue > 0 && Hue < 30) && (Sat > 30) && (Value > 30))  // 피부색 범위
        //         pixel_valid = 1;
        //     else
        //         pixel_valid = 0;
        // end

        // // Valid 신호에 따른 흰색 or 검은색 출력
        // assign HSV_Filtered_Data = (pixel_valid) ? 12'hFFF : 12'h000;
endmodule