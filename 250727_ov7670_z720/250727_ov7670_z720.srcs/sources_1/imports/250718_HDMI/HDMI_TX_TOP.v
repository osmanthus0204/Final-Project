`timescale 1ns / 1ps

// (c) fpga4fun.com & KNJN LLC 2013
// edited/updated for vivado 2020.1 
// clk 100MHz MODIFIED

////////////////////////////////////////////////////////////////////////
module HDMI_TX_TOP(
	input clk,  //  100MHz
  //frame buffer side
   output        rclk, //pixclk 25MHz
   output        DE,
   output [16:0] rAddr,
   input  [11:0] rData,
   input [9:0] x_min,x_max,y_min,y_max,
   //export side
	output [2:0] TMDSp, TMDSn,
	output TMDSp_clock, TMDSn_clock
);

////////////////////////////////////////////////////////////////////////
// clk divider 100 MHz to 25 MHz pixclk, and multiplier 100 MHz to 250 MHz
wire MMCM_pix_clock, pixclk;
wire clk_TMDS, DCM_TMDS_CLKFX;
wire clkfb_in, clkfb_out;

   // MMCME2_BASE: Base Mixed Mode Clock Manager
   //              Artix-7
   // Xilinx HDL Language Template, version 2020.1

   MMCME2_BASE #(
      .BANDWIDTH("OPTIMIZED"),   // Jitter programming (OPTIMIZED, HIGH, LOW)
      .CLKFBOUT_MULT_F(10.0),     // Multiply value for all CLKOUT (2.000-64.000).  //MODIFIED
      .CLKFBOUT_PHASE(0.0),      // Phase offset in degrees of CLKFB (-360.000-360.000).
      .CLKIN1_PERIOD(8.0),       // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
      // CLKOUT0_DIVIDE - CLKOUT6_DIVIDE: Divide amount for each CLKOUT (1-128)
      .CLKOUT1_DIVIDE(40),  // 100*10/40 = 25 MHz  //MODIFIED
      .CLKOUT2_DIVIDE(4),   // 100*10/4  = 250 MHz //MODIFIED
      .CLKOUT3_DIVIDE(1),
      .CLKOUT4_DIVIDE(1),
      .CLKOUT5_DIVIDE(1),
      .CLKOUT6_DIVIDE(1),
      .CLKOUT0_DIVIDE_F(1.0),    // Divide amount for CLKOUT0 (1.000-128.000).
      // CLKOUT0_DUTY_CYCLE - CLKOUT6_DUTY_CYCLE: Duty cycle for each CLKOUT (0.01-0.99).
      .CLKOUT0_DUTY_CYCLE(0.5),
      .CLKOUT1_DUTY_CYCLE(0.5),
      .CLKOUT2_DUTY_CYCLE(0.5),
      .CLKOUT3_DUTY_CYCLE(0.5),
      .CLKOUT4_DUTY_CYCLE(0.5),
      .CLKOUT5_DUTY_CYCLE(0.5),
      .CLKOUT6_DUTY_CYCLE(0.5),
      // CLKOUT0_PHASE - CLKOUT6_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
      .CLKOUT0_PHASE(0.0),
      .CLKOUT1_PHASE(0.0),
      .CLKOUT2_PHASE(0.0),
      .CLKOUT3_PHASE(0.0),
      .CLKOUT4_PHASE(0.0),
      .CLKOUT5_PHASE(0.0), 
      .CLKOUT6_PHASE(0.0),
      .CLKOUT4_CASCADE("FALSE"), // Cascade CLKOUT4 counter with CLKOUT6 (FALSE, TRUE)
      .DIVCLK_DIVIDE(1),         // Master division value (1-106)
      .REF_JITTER1(0.0),         // Reference input jitter in UI (0.000-0.999).
      .STARTUP_WAIT("FALSE")     // Delays DONE until MMCM is locked (FALSE, TRUE)
   )
   MMCME2_BASE_INST (
      // Clock Outputs: 1-bit (each) output: User configurable clock outputs
      .CLKOUT0(CLKOUT0),     // 1-bit output: CLKOUT0
      .CLKOUT0B(CLKOUT0B),   // 1-bit output: Inverted CLKOUT0
      .CLKOUT1(MMCM_pix_clock),     // 1-bit output: CLKOUT1
      .CLKOUT1B(CLKOUT1B),   // 1-bit output: Inverted CLKOUT1
      .CLKOUT2(DCM_TMDS_CLKFX),     // 1-bit output: CLKOUT2
      .CLKOUT2B(CLKOUT2B),   // 1-bit output: Inverted CLKOUT2
      .CLKOUT3(CLKOUT3),     // 1-bit output: CLKOUT3
      .CLKOUT3B(CLKOUT3B),   // 1-bit output: Inverted CLKOUT3
      .CLKOUT4(CLKOUT4),     // 1-bit output: CLKOUT4
      .CLKOUT5(CLKOUT5),     // 1-bit output: CLKOUT5
      .CLKOUT6(CLKOUT6),     // 1-bit output: CLKOUT6
      // Feedback Clocks: 1-bit (each) output: Clock feedback ports
      .CLKFBOUT(clkfb_in),   // 1-bit output: Feedback clock
      .CLKFBOUTB(CLKFBOUTB), // 1-bit output: Inverted CLKFBOUT
      // Status Ports: 1-bit (each) output: MMCM status ports
      .LOCKED(LOCKED),       // 1-bit output: LOCK
      // Clock Inputs: 1-bit (each) input: Clock input
      .CLKIN1(clk),       // 1-bit input: Clock
      // Control Ports: 1-bit (each) input: MMCM control ports
      .PWRDWN(PWRDWN),       // 1-bit input: Power-down
      .RST(1'b0),             // 1-bit input: Reset
      // Feedback Clocks: 1-bit (each) input: Clock feedback ports
      .CLKFBIN(clkfb_out)      // 1-bit input: Feedback clock
   );

   // End of MMCME2_BASE_inst instantiation

// clock buffers
   // BUFG: Global Clock Simple Buffer
   //       Artix-7
   // Xilinx HDL Language Template, version 2020.1

   BUFG BUFG_pixclk (
      .O(pixclk), // 1-bit output: Clock output
      .I(MMCM_pix_clock)  // 1-bit input: Clock input
   );
   
   // BUFG: Global Clock Simple Buffer
   //       Artix-7
   // Xilinx HDL Language Template, version 2020.1

   BUFG BUFG_TMDSp (
      .O(clk_TMDS), // 1-bit output: Clock output
      .I(DCM_TMDS_CLKFX)  // 1-bit input: Clock input
   );
   
   // BUFG: Global Clock Simple Buffer
   //       Artix-7
   // Xilinx HDL Language Template, version 2020.1

   BUFG BUFG_CLKFB (
      .O(clkfb_out), // 1-bit output: Clock output
      .I(clkfb_in)  // 1-bit input: Clock input
   );

   // End of BUFG_inst instantiation
// end clk divider to 25 MHz pixclk

////////////////////////////////////////////////////////////////////////


// counter and sync generation
reg [9:0] x_pixel = 0, y_pixel = 0;
reg hSync, vSync, DrawArea;


always @(posedge pixclk)
    begin  
        DrawArea <= (x_pixel<640) && (y_pixel<480);           // define picture dimensions for 640x480 (off-screen data 800x525)
        x_pixel <= (x_pixel==799) ? 0 : x_pixel+1;           // horizontal counter (including off-screen horizontal 160 pixels) total of 800 pixels 
        if(x_pixel==799) 
            y_pixel <= (y_pixel==524) ? 0 : y_pixel+1;       /* vertical counter (including off-screen vertical 45 pixels) total of 525 pixels
                                                                   only counts up 1 count after horizontal finishes. */                                                          
        hSync <= (x_pixel>=656) && (x_pixel<752);         // hsync high for 96 counts                                                 
        vSync <= (y_pixel>=490) && (y_pixel<492);         // vsync high for 2 counts
    end


assign DE = DrawArea; //to FrameBuffer_oe
assign rAddr =  DrawArea  ? (y_pixel[9:1] * 320 + x_pixel[9:1]) : 0;
assign rclk = pixclk;
// end counter and sync generation  

///////////////////////////////////////////////////////////////////////



// color generation (not part of HDMI standard, jsut for generating some patterns)
// wire [7:0] W = {8{x_pixel[7:0]==y_pixel[7:0]}};                     
// wire [7:0] A = {8{x_pixel[7:5]==3'h2 && y_pixel[7:5]==3'h2}};                                                                                                                                                                                                     
reg [7:0] red, green, blue;
/*
always @(posedge pixclk) 
    red <= ({x_pixel[5:0] & {6{y_pixel[4:3]==~x_pixel[4:3]}}, 2'b00} | W) & ~A;
    
always @(posedge pixclk) 
    green <= (x_pixel[7:0] & {8{y_pixel[6]}} | W) & ~A;
    
always @(posedge pixclk) 
    blue <= y_pixel[7:0] | W | A;
// end color generation

*/

// shift와 덧셈만으로 근사 565 일경우
// always @( posedge pixclk) begin
//    red   <= (rData[15:11] << 3) | (rData[15:11] >> 2);  // x*8 + x/4 ≈ x*8.25
//    green <= (rData[10:5]  << 2) | (rData[10:5]  >> 4);  // x*4 + x/16 ≈ x*4.06
//    blue  <= (rData[4:0]   << 3) | (rData[4:0]   >> 2);   
   
// end


   reg is_frame_area;
   reg is_motor_area;
   wire [10:0] x_center,y_center;
   assign x_center = (x_min+x_max) >> 1;
   assign y_center = (y_min+y_max) >> 1;
// 444일경우
always @(posedge pixclk) begin
   if(is_frame_area) begin
      red <= 8'b11111111;
      green <= 8'b11111111;
      blue <= 8'b11111111;
   end
   else if(is_motor_area) begin
      red <= 8'b11111111;
      green <= 0;
      blue <= 0;
   end
   else begin
    red   <= {rData[11:8], rData[11:8]};
    green <= {rData[7:4],  rData[7:4]};
    blue  <= {rData[3:0],  rData[3:0]};
   end
end


always @( posedge clk ) begin 
      is_frame_area <= (
         // 상단 테두리
         (y_pixel == y_min && x_pixel >= x_min && x_pixel <= x_max) ||

         // 하단 테두리
         (y_pixel == y_max && x_pixel >= x_min && x_pixel <= x_max) ||

         // 좌측 테두리
         (x_pixel == x_min && y_pixel >= y_min && y_pixel <= y_max) ||

         // 우측 테두리
         (x_pixel == x_max && y_pixel >= y_min && y_pixel <= y_max) ||
         
         // 중심 좌표
         (x_pixel == x_center && y_pixel == y_center )
      );

      is_motor_area <= (
          (x_pixel == 100 || x_pixel == 101) || (x_pixel == 540 || x_pixel == 541)
      );
end




////////////////////////////////////////////////////////////////////////
// 8b/10b encoding for transmission
wire [9:0] TMDS_red, TMDS_green, TMDS_blue;

// instantiate TMDS encoders (TMDS_encoder.vhd file from github)
TMDS_encoder encode_R(.clk(pixclk), .VD(red  ), .CD(2'b00)        , .VDE(DrawArea), .TMDS(TMDS_red));
TMDS_encoder encode_G(.clk(pixclk), .VD(green), .CD(2'b00)        , .VDE(DrawArea), .TMDS(TMDS_green));
TMDS_encoder encode_B(.clk(pixclk), .VD(blue ), .CD({vSync,hSync}), .VDE(DrawArea), .TMDS(TMDS_blue));   // I think HDMI standard says both "sync" signals are sent over the "blue" line control inputs
// end 8b/10b encoding

////////////////////////////////////////////////////////////////////////
// Serializer and output buffers
reg [3:0] TMDS_mod10=0;  // modulus 10 counter
reg [9:0] TMDS_shift_red=0, TMDS_shift_green=0, TMDS_shift_blue=0;
reg TMDS_shift_load=0;

always @(posedge clk_TMDS) 
    TMDS_shift_load <= (TMDS_mod10==4'd9);  // shift load is high only if mod ten counter is done

always @(posedge clk_TMDS)
    begin
        TMDS_shift_red   <= TMDS_shift_load ? TMDS_red   : TMDS_shift_red  [9:1];  // only if all the old data has been serialized, then start shifting new data
        TMDS_shift_green <= TMDS_shift_load ? TMDS_green : TMDS_shift_green[9:1];  // kind of a wierd way of shifting but it works. replacing the last shift data with the MSB:LSB+1
        TMDS_shift_blue  <= TMDS_shift_load ? TMDS_blue  : TMDS_shift_blue [9:1];	
        TMDS_mod10 <= (TMDS_mod10==4'd9) ? 4'd0 : TMDS_mod10+4'd1;                 // increase counter or reset after 10 counts
    end

// instantiate differential output buffers
   // OBUFDS: Differential Output Buffer
   //         Artix-7
   // Xilinx HDL Language Template, version 2020.1
   
   OBUFDS #(
      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
      .SLEW("SLOW")           // Specify the output slew rate
   ) OBUFDS_red (
      .O(TMDSp[2]),     // Diff_p output (connect directly to top-level port)
      .OB(TMDSn[2]),   // Diff_n output (connect directly to top-level port)
      .I(TMDS_shift_red[0])      // Buffer input
   );

   // End of OBUFDS_inst instantiation
   
   // OBUFDS: Differential Output Buffer
   //         Artix-7
   // Xilinx HDL Language Template, version 2020.1
   
   OBUFDS #(
      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
      .SLEW("SLOW")           // Specify the output slew rate
   ) OBUFDS_green (
      .O(TMDSp[1]),     // Diff_p output (connect directly to top-level port)
      .OB(TMDSn[1]),   // Diff_n output (connect directly to top-level port)
      .I(TMDS_shift_green[0])      // Buffer input
   );

   // End of OBUFDS_inst instantiation

   // OBUFDS: Differential Output Buffer
   //         Artix-7
   // Xilinx HDL Language Template, version 2020.1

   OBUFDS #(
      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
      .SLEW("SLOW")           // Specify the output slew rate
   ) OBUFDS_blue (
      .O(TMDSp[0]),     // Diff_p output (connect directly to top-level port)
      .OB(TMDSn[0]),   // Diff_n output (connect directly to top-level port)
      .I(TMDS_shift_blue[0])      // Buffer input
   );

   // End of OBUFDS_inst instantiation
   // OBUFDS: Differential Output Buffer
   //         Artix-7
   // Xilinx HDL Language Template, version 2020.1

   OBUFDS #(
      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
      .SLEW("SLOW")           // Specify the output slew rate
   ) OBUFDS_clock (
      .O(TMDSp_clock),     // Diff_p output (connect directly to top-level port)
      .OB(TMDSn_clock),   // Diff_n output (connect directly to top-level port)
      .I(pixclk)      // Buffer input
   );

   // End of OBUFDS_inst instantiation
// end serializer and output buffers

endmodule  

