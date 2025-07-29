`timescale 1ns / 1ps
module scale_Calc(
    input logic clk,
    input logic reset,
    input logic [40:0] M00,
    input logic [40:0] M10,
    input logic [40:0] M01,
    input logic [40:0] M20,
    input logic [40:0] M02,
    input logic [9:0] x_center,
    input logic [9:0] y_center,
    input logic center_valid,
    output logic [9:0] o_x_center,
    output logic [9:0] o_y_center,
    output logic [9:0] o_width,
    output logic [9:0] o_hegiht,
    output logic [9:0] w,
    output logic [9:0] h,
    output logic scale_done
);

    logic [31:0] variance_x, variance_x_next;
    logic [31:0] variance_y, variance_y_next;
    logic x_start, x_start_next;
    logic y_start, y_start_next;
    logic x_sqrt_done, y_sqrt_done;
    logic [15:0] x_sqrt, y_sqrt;
    logic [9:0] x_center_reg, x_center_next;
    logic [9:0] y_center_reg, y_center_next;
    logic [9:0] width, width_next;
    logic [9:0] height, height_next;
    logic scale_done_reg, scale_done_next;
    logic [9:0] w_reg, w_next;
    logic [9:0] h_reg, h_next;
    logic [31:0] x_mul;
    logic [31:0] y_mul;

    typedef enum  { IDLE, VAR,  W_H_CALC_START, W_H_CALC_WAIT, W_H_CALC, DONE } state_e;    

    state_e state, state_next;

    assign o_x_center = x_center_reg;
    assign o_y_center = y_center_reg;
    assign o_width = width;
    assign o_hegiht = height;
    assign scale_done = scale_done_reg;
    assign x_mul = x_center * x_center;
    assign y_mul = y_center * y_center;
    assign w = w_reg;
    assign h = h_reg;

    always_ff @( posedge clk, posedge reset  ) begin
        if(reset) begin
            state <= IDLE;
            x_start <= 0;
            y_start <= 0;
            width <= 0;
            height <= 0;
            x_center_reg <= 0;
            y_center_reg <= 0;
            w_reg <= 0;
            h_reg <= 0;
            variance_x <= 0;
            variance_y <= 0;
            scale_done_reg <= 0;
        end
        else begin
            state <= state_next;
            x_start <= x_start_next;
            y_start <= y_start_next;
            width <= width_next;
            height <= height_next;
            x_center_reg <= x_center_next;
            y_center_reg <= y_center_next;
            w_reg <= w_next;
            h_reg <= h_next;
            variance_x <= variance_x_next;
            variance_y <= variance_y_next;
            scale_done_reg <= scale_done_next;
        end
    end


    always_comb begin 
        state_next = state;
        x_start_next = 0;
        y_start_next = 0;
        variance_x_next = variance_x;
        variance_y_next = variance_y;
        width_next = width;
        height_next = height;
        x_center_next = x_center_reg;
        y_center_next = y_center_reg;
        w_next= w_reg;
        h_next = h_reg;
        scale_done_next = 0;
        case (state)
            IDLE: begin
                scale_done_next = 1'b0;
                if(center_valid) begin
                    state_next = VAR;
                end
            end 
            VAR: begin
                // variance_x_next = (M20*M00 - M10*M10)/(M00*M00);
                // variance_y_next = (M02*M00 - M01*M01)/(M00*M00);
                if(M20/M00 > x_mul) variance_x_next = M20/M00 - x_mul;
                else variance_x_next = 0;
                if(M02/M00 > y_mul) variance_y_next = M02/M00 - y_mul;
                else variance_y_next = 0;
                state_next = W_H_CALC_START;
            end
            W_H_CALC_START : begin
                x_start_next = 1;
                y_start_next = 1;
                state_next = W_H_CALC_WAIT;
            end
            W_H_CALC_WAIT : begin
                if(x_sqrt_done && y_sqrt_done) begin
                    state_next = W_H_CALC;
                end
            end
            W_H_CALC : begin
                width_next = x_sqrt<<1;
                height_next = y_sqrt<<1;
                x_center_next = x_center;
                y_center_next = y_center;
                if( x_sqrt < 80)
                    w_next = x_sqrt;
                else w_next = 80;
                if(y_sqrt < 60)
                    h_next = y_sqrt;
                else 
                    h_next = 60;
                state_next = DONE;
            end
            DONE : begin
                scale_done_next = 1;
                state_next = IDLE;
            end
        endcase
    end


    sqrt_lut X_sqrt(
        .clk(clk),
        .reset(reset),
        .start(x_start),
        .value_in(variance_x),
        .done(x_sqrt_done),
        .sqrt_out(x_sqrt)
    );

    sqrt_lut Y_sqrt(
        .clk(clk),
        .reset(reset),
        .start(y_start),
        .value_in(variance_y),
        .done(y_sqrt_done),
        .sqrt_out(y_sqrt)
    );



endmodule

module sqrt_lut (
    input  logic        clk,
    input  logic        reset,
    input  logic        start,
    input  logic [31:0] value_in,   // 14비트 입력
    output logic [15:0]  sqrt_out,    // 8비트 출력 (정수 sqrt)
    output logic        done
);

    logic [31:0] rom [0:65535];  // 2^14 entries, each 8-bit

    initial begin
        $readmemh("sqrt_table.mem", rom);  // Hex 파일 로딩
    end

    always_ff @(posedge clk) begin
        if(start) begin
            sqrt_out <= rom[value_in];
            done <= 1;
        end
        else begin
            done <= 0;
        end
    end

endmodule

// module sqrt(
//     input  logic        clk,
//     input  logic        reset,
//     input  logic        start,
//     input  logic [14:0] value_in,         // 입력값
//     output logic [15:0] sqrt_out,  // 근사 결과
//     output logic        done
// );

//     logic [14:0] temp_reg, temp_next, calc_next, calc_reg, add_next, add_reg;
//     logic [5:0] cnt_reg, cnt_next;
//     logic done_reg, done_next;

//     typedef enum { IDLE, START, CALC, SHIFT, ADD, DONE } state_e;

//     state_e state, state_next;

//     assign done = done_reg;
//     assign sqrt_out = temp_reg;


//     always_ff @( posedge clk, posedge reset ) begin
//         if(reset) begin
//             state <= IDLE;
//             temp_reg <= 0;
//             add_reg <= 0;
//             calc_reg <=0 ;
//             cnt_reg <= 0;
//             done_reg <= 0;
//         end
//         else begin
//             state <= state_next;
//             temp_reg <= temp_next;
//             add_reg <= add_next;
//             calc_reg <= calc_next;
//             cnt_reg <= cnt_next;
//             done_reg <= done_next;
//         end
//     end


//     always_comb begin
//         state_next = state;
//         temp_next = temp_reg;
//         calc_next = calc_reg;
//         add_next = add_reg;
//         cnt_next = cnt_reg;
//         done_next = 0;
//         case (state)
//             IDLE: begin
//                 if(start) begin
//                     state_next = START;
//                 end
//             end 
//             START: begin
//                 temp_next = value_in>>1;
//                 state_next = CALC;
//             end
//             CALC : begin
//                 if(cnt_reg==10) begin
//                     state_next = DONE;
//                 end
//                 else begin
//                     calc_next = value_in / temp_next;
//                     state_next = ADD;
//                 end
//             end
//             ADD : begin
//                 add_next = temp_reg + calc_reg;
//                 state_next = SHIFT;
//             end
//             SHIFT : begin
//                temp_next =  add_reg >> 1;
//                cnt_next = cnt_reg + 1;
//                state_next = CALC;
//             end
//             DONE: begin
//                 cnt_next = 0;
//                 done_next = 1;
//                 state_next = IDLE;
//             end
//         endcase
//     end


// endmodule

