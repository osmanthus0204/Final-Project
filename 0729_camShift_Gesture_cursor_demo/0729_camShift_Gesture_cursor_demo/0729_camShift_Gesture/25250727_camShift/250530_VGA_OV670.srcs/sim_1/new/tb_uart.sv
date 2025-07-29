`timescale 1ns / 1ps


module tb_uart(


    );

    logic clk;
    logic reset;
    logic start_trigger;
    logic two_byte_done;
    logic tx_finish;
    logic [9:0] x_count;
    logic [9:0] y_count;
    logic keep_start;
    logic all_trans_complete;
    logic [1:0]state,next;
    logic [9:0]  x_coord, y_coord;
    logic [16:0] rAddr_320x240;
    logic [7:0] tx_data;
    logic cu_state;
    logic [11:0] qvga_rData;
        logic [3:0] red_port, green_port, blue_port;

    assign uart_start_btn = start_trigger;
    localparam IDLE = 0, FIRST_BYTE = 1, SECOND_BYTE = 2;
    always #5 clk = ~clk;

    always_ff @( posedge clk,posedge reset ) begin : blockName
        if(reset) begin
            state <= 0;
        end else begin
            state <= next;
        end
    end
    always_comb begin
        next = state;
        two_byte_done = 1'b0;
        tx_data = 0;
        case (state)
            IDLE:begin
                two_byte_done = 1'b0;
                tx_data = 0;
                if(uart_start_btn)begin
                    next = FIRST_BYTE;
                end
            end
            FIRST_BYTE:begin
                two_byte_done = 1'b0;
                tx_data = {green_port,blue_port};
                if(tx_finish == 1) begin
                    next = SECOND_BYTE;
                end
                if((all_trans_complete))begin
                    next = IDLE;
                end
            end 
            SECOND_BYTE:begin
                tx_data = {4'b0,red_port};
                if(tx_finish == 1) begin
                    two_byte_done = 1'b1;
                    next = FIRST_BYTE;
                end
            end
        endcase
    end


    uart_cu dcu(    
    .clk(clk),
    .reset(reset),
    .start_trigger(uart_start_btn),
    .two_byte_done(two_byte_done),
    .tx_finish(tx_finish),
    .x_count(x_count),
    .y_count(y_count),
    .keep_start(keep_start),
    .all_trans_complete(all_trans_complete),
    .cu_state(cu_state)
);
    uart dut_uart(
    .*,
    .rst(reset),
    .btn_start(keep_start),
    .tx_data_in(tx_data),
    .tx(tx),
    .tx_done(tx_done),
    .tx_finish(tx_finish),
    .rx(),
    .rx_done(),
    .rx_data()
    );
        frame_buffer_320x240 U_FrameBuffer_320x240 (
        .photo_area(),
        .h_counter_o(),
        .v_counter_o(),
        //write side
        .wclk (), 
        .we   (),
        .wAddr(),
        .wData(),
        //read side
        .rclk (clk),
        .oe   (oe),
        .rAddr(rAddr_320x240),
        .rData(qvga_rData)
    );
        mux_2x1 U_MUX_X(
        .sel(keep_start),
        .x0(1),
        .x1(x_count),
        .y(x_coord)
    );
    mux_2x1 U_MUX_Y(
        .sel(keep_start),
        .x0(1),
        .x1(y_count),
        .y(y_coord)
    );

QVGA_MemController U_QVGA_MemController (
        //VGA Controller side
        .clk       (clk),
        .x_pixel   (x_coord),
        .y_pixel   (y_coord),
        .DE        (),
        //frame buffer side
        .rclk      (w_rclk),
        .d_en      (oe),
        .rAddr_320x240(rAddr_320x240),
        .rAddr_160x120(),
        .rData     (qvga_rData),
        //export side
        .red_port  (red_port),
        .green_port(green_port),
        .blue_port (blue_port)
    );
    initial begin
        clk = 0; reset = 1;
        #10;
        reset = 0;
        @(posedge clk);
        start_trigger = 1;
        #10;
        start_trigger = 0;

    end
endmodule
