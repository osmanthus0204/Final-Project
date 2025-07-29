`timescale 1ns / 1ps


module uart_cu(
    input  logic clk,
    input  logic reset,
    input  logic start_trigger,
    input  logic two_byte_done,
    input  logic tx_finish,
    output logic [9:0] x_count,
    output logic [9:0] y_count,
    output logic keep_start,
    output logic all_trans_complete,
    output logic cu_state
    );
    logic  state, next;
    logic [9:0] x_count_next, x_count_reg;
    logic [9:0] y_count_next, y_count_reg;
    logic all_trans_complete_next, all_trans_complete_reg;
    // logic keep_start_next, keep_start_reg;
    // assign keep_start = keep_start_reg;
    assign x_count = x_count_reg;
    assign y_count = y_count_reg;
    assign all_trans_complete = all_trans_complete_reg;
    assign cu_state = state;
    localparam  IDLE = 0, COUNT = 1;
    always_ff @( posedge clk, posedge reset) begin
        if (reset) begin
            state <= 0;
            // keep_start_reg <= 0;
            x_count_reg <= 0;
            y_count_reg <= 0;
            all_trans_complete_reg <= 0;
        end else begin
            state <= next;
            // keep_start_reg <= keep_start_next;
            x_count_reg <= x_count_next;
            y_count_reg <= y_count_next;
            all_trans_complete_reg <= all_trans_complete_next;
        end
    end


    always_comb begin
        next = state;
///     keep_start_next = keep_start_reg;
        keep_start = 0;
        x_count_next = x_count_reg;
        y_count_next = y_count_reg;
        all_trans_complete_next = all_trans_complete_reg;
        case (state)
            IDLE : begin
                x_count_next = 0;
                y_count_next = 0;
                keep_start=0;
                all_trans_complete_next = 0;
                if(start_trigger) begin
                    // keep_start_next = 1'b1;
                    next = COUNT;
                end
            end 
            COUNT : begin
                keep_start = 1'b1;
                if(two_byte_done == 1) begin
                    if(x_count_reg == 319) begin
                        if(y_count_reg == 239) begin
                            x_count_next = 0;
                            y_count_next = 0;
                            all_trans_complete_next = 1'b1;
                            // keep_start_next = 0;
                            next = IDLE;
                        end else begin
                            y_count_next = y_count_reg + 1;
                            x_count_next = 0;
                        end
                    end else begin
                        x_count_next = x_count_reg + 1;    
                    end
                end 
            end
        endcase
    end
endmodule
