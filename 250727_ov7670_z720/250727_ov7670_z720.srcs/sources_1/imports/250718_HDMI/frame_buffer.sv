`timescale 1ns / 1ps



module frame_buffer (
    input logic [ 9:0] h_counter_o,
    input logic [ 7:0] v_counter_o,
    //write side
    input  logic        wclk,
    input  logic        we, //write enable
    input  logic [16:0] wAddr,
    input  logic [15:0] wData,
    //read side
    input  logic        rclk,
    input  logic        oe, //ouput enable
    input  logic [16:0] rAddr,
    output logic [15:0] rData
);
    logic [15:0] mem[0:(320*240 -1)];
    logic [15:0] rData_o;
    logic [16:0] wAddr_1;
 
    assign wAddr_1 = (h_counter_o[9:1])+ (v_counter_o[7:0])*320;  

    always_ff @( posedge wclk ) begin : write_side
        if(we) begin
            mem[wAddr_1] <= wData;
        end
    end

    // read side
    always_ff @( posedge rclk ) begin : read_side
        if(oe) begin
            rData <= mem[rAddr];
        end
    end
endmodule
