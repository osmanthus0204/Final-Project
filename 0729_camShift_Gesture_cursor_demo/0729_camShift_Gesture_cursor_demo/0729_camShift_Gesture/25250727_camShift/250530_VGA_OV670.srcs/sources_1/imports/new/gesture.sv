`timescale 1ns / 1ps

module gesture(
    input logic clk,
    input logic fclk,
    input logic reset,
    input logic btn_start,
    input logic signed [8:0] x_dis_clk,
    input logic signed [8:0] y_dis_clk,
    input logic signed [8:0] x_dis_fclk, 
    input logic signed [8:0] y_dis_fclk, 
    output logic [8:0] o_gesture_detected,
    output logic o_gesture_done, // u
    output logic [11:0] led,
    output logic [9:0] o_movement,
    output logic [8:0] o_x_sum
    );

    localparam [2:0]
        DIR_NONE       = 3'd0,
        DIR_RIGHT      = 3'd1,
        DIR_DOWN       = 3'd2,
        DIR_LEFT       = 3'd3,
        DIR_UP         = 3'd4;

// 거리,속도,누적합 계산
    logic signed [8:0] x_sum,y_sum;
    logic [8:0] abs_x_dis_fclk, abs_y_dis_fclk;
    logic [9:0] movement;

// 손동작 인식 출력
    logic [2:0] line_code;
    logic [2:0] line1_next, line2_next, line3_next;
    logic [2:0] line1_reg, line2_reg, line3_reg;
    logic [8:0] gesture_detected_reg, gesture_detected_next;

// 라인코드 및 이동거리 정리 코드
    logic clear_reg, clear_next;
    logic line_state_in;

// 메타스테이블 상태 해결
    logic signed [8:0] x_dis_sync1, x_dis_sync2;
    logic signed [8:0] y_dis_sync1, y_dis_sync2;


// 상태 타입
    typedef enum  { IDLE, START, LINE1, WAIT1, LINE2, WAIT2, LINE3, LINE_END, STOP, SLOW1, SLOW2 } state_e;
    state_e state, state_next;



    assign o_gesture_detected = gesture_detected_reg;
    assign o_movement = movement;
    assign o_x_sum = x_sum;
    
    assign abs_x_dis_fclk = (x_dis_sync2 < 0) ? -x_dis_sync2 : x_dis_sync2;
    assign abs_y_dis_fclk = (y_dis_sync2 < 0) ? -y_dis_sync2 : y_dis_sync2;

    assign movement = abs_x_dis_fclk + abs_y_dis_fclk;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            x_dis_sync1 <= 0;
            x_dis_sync2 <= 0;
            y_dis_sync1 <= 0;
            y_dis_sync2 <= 0;
        end else begin
            x_dis_sync1 <= x_dis_fclk;
            x_dis_sync2 <= x_dis_sync1;

            y_dis_sync1 <= y_dis_fclk;
            y_dis_sync2 <= y_dis_sync1;
        end
    end

    always_ff @( posedge clk, posedge reset ) begin 
        if(reset) begin
            state <= IDLE;
            line1_reg <= 0;
            line2_reg <= 0;
            line3_reg <= 0;
            gesture_detected_reg <= 0;
            clear_reg <= 0;
        end
        else begin
            state <= state_next;
            line1_reg <= line1_next;
            line2_reg <= line2_next;
            line3_reg <= line3_next;
            gesture_detected_reg <= gesture_detected_next;
            clear_reg <= clear_next;
        end
    end

// 이동거리 누적합 계산
    always_ff @( posedge clk, posedge reset ) begin
        if(reset) begin
            x_sum <= 0;
            y_sum <= 0;
            line_code <= 0;
        end
        else if(clear_reg) begin
            x_sum <= 0;
            y_sum <= 0;
            line_code <= 0;
        end
        else if(btn_start) begin
            x_sum <= x_sum + x_dis_clk; // x 이동거리 누적 합
            y_sum <= y_sum + y_dis_clk; // y 이동거리 누적 합
            if(line_code == 0 && line_state_in) begin
                if (x_sum >= 20) begin
                    line_code <= DIR_RIGHT; // right = 1
                end
                if (x_sum <= -20) begin
                    line_code <= DIR_LEFT; // left = 2
                end
                if (y_sum >= 16) begin
                    line_code <= DIR_DOWN; // down = 3
                end
                if (y_sum <= -16) begin
                    line_code <= DIR_UP; // up = 4
                end
            end
        end
        else begin
            x_sum <= 0;
            y_sum <= 0;
            line_code <= 0;
        end
    end

    always_comb begin
        line_state_in = (state == LINE1 || state == LINE2 || state == LINE3); // line state 안에 있을떄
    end

    always_comb begin
        state_next = state;
        line1_next = line1_reg;
        line2_next = line2_reg;
        line3_next = line3_reg;
        gesture_detected_next = gesture_detected_reg;
        clear_next = 0;
        o_gesture_done = 0;
        led = 0;
        case (state)
            IDLE: begin
                line1_next = 0;
                line2_next = 0;
                line3_next = 0;
                led = 11'b0000_0000_000;
                if(btn_start) begin
                    state_next = START;
                end
            end
            START: begin
                led = 11'b0000_0000_001;
                if(movement >= 25) begin
                    state_next = LINE1;
                    clear_next = 1;
                end
                if(!btn_start) begin
                    state_next = LINE_END;
                end
            end
            LINE1: begin
                led = 11'b0000_0000_010;
                if(movement <= 5 && line_code != 0) begin
                    line1_next = line_code;
                    state_next = SLOW1;
                end

                if(!btn_start) begin
                    state_next = LINE_END;
                end
            end
            SLOW1: begin
                if(movement <= 5 ) begin
                    state_next = WAIT1;
                end
            end
            WAIT1: begin
                led = 11'b0000_0000_100;
                if(movement >= 25) begin
                    state_next = LINE2;
                    clear_next = 1;
                end
                if(!btn_start) begin
                    state_next = LINE_END;
                end
            end
            LINE2: begin 
                led = 11'b0000_0001_000;
                if( movement <= 5 && line_code != 0) begin
                    line2_next = line_code;
                    state_next = SLOW2;
                end

                if(!btn_start) begin
                    state_next = LINE_END;
                end
            end
            SLOW2: begin
                if(movement <=5) begin
                    state_next = WAIT2;
                end
            end
            WAIT2: begin
                led = 11'b0000_0010_000;
                if(movement >= 25 ) begin
                    state_next = LINE3;
                    clear_next = 1;
                end
                if(!btn_start) begin
                    state_next = LINE_END;
                end
            end
            LINE3: begin 
                led = 11'b0000_0100_000;
                if( line_code != 0) begin
                        line3_next = line_code;
                end

                if(!btn_start) begin
                    state_next = LINE_END;
                end
            end
            LINE_END: begin
                led = 11'b0000_1000_000;
                gesture_detected_next = {line3_reg, line2_reg, line1_reg};
                state_next = STOP;
            end
            STOP: begin
                led = 11'b0001_0000_000;
                state_next = IDLE;
                clear_next = 1;
                o_gesture_done = 1;
            end

        endcase
    end

endmodule

module gesture_to_number (
    input logic [8:0] gesture_detected,
    output logic [7:0] gesture_number
);

    localparam [2:0]
        DIR_NONE       = 3'd0,
        DIR_RIGHT      = 3'd1,
        DIR_DOWN       = 3'd2,
        DIR_LEFT       = 3'd3,
        DIR_UP         = 3'd4;

    always_comb begin
        case (gesture_detected)
            {DIR_NONE, DIR_NONE, DIR_RIGHT} : gesture_number = 8'h61; // 오른쪽으로만 이동 a
            {DIR_NONE, DIR_NONE, DIR_LEFT} :  gesture_number = 8'h62; // 왼쪽으로만 이동 b
            {DIR_NONE, DIR_NONE, DIR_UP} :  gesture_number = 8'h63; // 아래쪽으로만 이동 c
            {DIR_NONE, DIR_NONE, DIR_DOWN} :  gesture_number = 8'h64; // 위쪽으로만 이동 d
            {DIR_NONE, DIR_DOWN, DIR_RIGHT}  : gesture_number = 8'h65; // e -> 0
            {DIR_NONE, DIR_UP, DIR_RIGHT}    : gesture_number = 8'h66; // f -> 1
            {DIR_NONE, DIR_DOWN, DIR_LEFT}   : gesture_number = 8'h67; // g -> 2
            {DIR_NONE, DIR_UP, DIR_LEFT}     : gesture_number = 8'h68; // h -> 3
            {DIR_NONE, DIR_RIGHT, DIR_DOWN}  : gesture_number = 8'h69; // i -> 4
            {DIR_NONE, DIR_RIGHT, DIR_UP}    : gesture_number = 8'h6A; // j -> 5
            {DIR_NONE, DIR_LEFT, DIR_DOWN}   : gesture_number = 8'h6B; // k -> 6
            {DIR_NONE, DIR_LEFT, DIR_UP}     : gesture_number = 8'h6C; // l -> 7
            {DIR_NONE, DIR_UP, DIR_DOWN}     : gesture_number = 8'h6D; // m -> 8
            {DIR_NONE, DIR_RIGHT, DIR_LEFT}  : gesture_number = 8'h6E; // n -> 9
            default : gesture_number = 8'h65; 
        endcase
    end
    
endmodule

module dis_x_y (
    input logic clk,
    input logic reset,
    input logic [7:0] smoothed_col,
    input logic [7:0] smoothed_row,
    output logic signed [8:0] x_dis,
    output logic signed [8:0] y_dis
);
    logic [7:0] smoothed_col1, smoothed_row1;

    always_ff @( posedge clk, posedge reset ) begin
        if(reset) begin
            smoothed_col1 <= 0;
            smoothed_row1 <= 0;
        end
        else begin
            smoothed_col1 <= smoothed_col;
            smoothed_row1 <= smoothed_row;
            x_dis <= smoothed_col1 - smoothed_col;
            y_dis <= smoothed_row1 - smoothed_row;
        end
    end


endmodule