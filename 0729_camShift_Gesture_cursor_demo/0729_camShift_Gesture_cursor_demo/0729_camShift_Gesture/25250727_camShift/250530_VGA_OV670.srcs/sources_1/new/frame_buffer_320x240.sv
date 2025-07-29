`timescale 1ns / 1ps

module frame_buffer_320x240 (
    //
    input  logic  [2:0] photo_area,
    input logic [ 9:0] h_counter_o,
    input logic [ 7:0] v_counter_o,
    //write side
    input  logic        wclk,
    input  logic        we, //write enable
    input  logic [16:0] wAddr,
    input  logic [11:0] wData,
    //read side
    input  logic        rclk,
    input  logic        oe, //ouput enable
    input  logic [16:0] rAddr,
    output logic [11:0] rData
);
    logic [11:0] mem[0:(320*240 -1)];
    logic [11:0] rData_o;
    logic [16:0] wAddr_1;
    logic [16:0] wAddr_2;
    logic [16:0] wAddr_3;
    logic [16:0] wAddr_4;
 
    assign wAddr_1 = (h_counter_o[9:1])+ (v_counter_o[7:0])*320;  

    // //write side
    // assign wAddr_1 = (h_counter_o[9:2])+ (v_counter_o[7:1])*320;  
    // assign wAddr_2 = ((h_counter_o[9:2])+160)+ (v_counter_o[7:1])*320;  
    // assign wAddr_3 = (h_counter_o[9:2])+ ((v_counter_o[7:1]+120)*320);  
    // assign wAddr_4 =  ((h_counter_o[9:2])+160)+ ((v_counter_o[7:1]+120)*320);  

// initial begin
//     for (int i = 0; i < 320*240; i++) begin
//         mem[i] = i + 1;
//     end
// end

    always_ff @( posedge wclk ) begin : write_side
        if(we) begin
            case (photo_area)
                3'b000: begin
                    mem[wAddr_1] <= wData;
                end 
                3'b001: begin
                    mem[wAddr_2] <= wData;
                end 
                3'b010: begin
                    mem[wAddr_3] <= wData;
                end 
                3'b011: begin
                    mem[wAddr_4] <= wData;
                end
                default : ;
            endcase
        end
    end

    // read side
    always_ff @( posedge rclk ) begin : read_side
        if(oe) begin
            rData <= mem[rAddr];
        end
    end
endmodule
