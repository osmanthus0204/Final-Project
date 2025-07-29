`timescale 1ns / 1ps

module SCCB_intf(
    input logic clk,
    input logic reset,
    input logic start_btn,
    output logic SCL,
    output logic SDA
    );

    logic clk_800khz;
    logic btn;
    logic [7:0] addr;
    logic [15:0] dout;
    logic [23:0] Data;

    assign Data = {8'h42,dout}; 


btn_debounce U_btn_debounce(
    .*,
    .i_btn(start_btn),
    .o_btn(btn)
);

SCCB U_SCCB(
    .clk(clk),
    .reset(reset),
    .Data(Data),
    .btn(start_btn),
    .SCL(SCL),
    .SDA(SDA),
    .addr(addr)
);

OV7670_config_rom U_config_rom(
    .clk(clk),
    .addr(addr),
    .dout(dout)
);


endmodule


module SCCB(
    input logic clk,
    input logic reset,
    input logic [23:0] Data,
    input logic btn,
    output logic SCL,
    output logic SDA,
    output logic [7:0] addr
);
    typedef enum  { IDLE, 
                    START1,
                    START2, 
                    DEVICE_ID1,
                    DEVICE_ID2, 
                    DEVICE_ID3, 
                    DEVICE_ID4, 
                    ADDRESS1,
                    ADDRESS2, 
                    ADDRESS3, 
                    ADDRESS4, 
                    DATA1,
                    DATA2, 
                    DATA3, 
                    DATA4, 
                    STOP1,
                    STOP2,
                    HOLD
    } state_e;


    state_e state, state_next;
    logic [23:0] temp_data_reg, temp_data_next;
    logic [3:0] bit_cnt_reg, bit_cnt_next;
    logic [$clog2(1000):0] clk_cnt_reg, clk_cnt_next;
    logic [7:0] addr_reg,addr_next;

    assign addr = addr_reg;

    always_ff @( posedge clk, posedge reset ) begin : blockName
        if(reset) begin
            state <= IDLE;
            temp_data_reg <= 0;
            bit_cnt_reg <= 0;
            clk_cnt_reg <= 0;
            addr_reg <= 0;
        end
        else begin
            state <= state_next;
            temp_data_reg <= temp_data_next;
            bit_cnt_reg <= bit_cnt_next; 
            clk_cnt_reg <= clk_cnt_next;
            addr_reg <= addr_next;
        end
    end

    always_comb begin
        state_next = state;
        temp_data_next = temp_data_reg;
        bit_cnt_next = bit_cnt_reg;
        clk_cnt_next = clk_cnt_reg;
        addr_next = addr_reg;
        SCL = 1;
        SDA = 1;
        case(state)
            IDLE : begin
                SDA = 1;
                SCL = 1;
                if(btn) begin
                    state_next = START1;
                end
            end
            START1: begin
                SDA = 0;
                SCL = 1;
                if(clk_cnt_reg == 499) begin
                    state_next = START2;
                    temp_data_next = Data;
                    clk_cnt_next = 0;
                end
                else begin
                    clk_cnt_next = clk_cnt_reg + 1;
                end
            end
            START2: begin
                SDA = 0;
                SCL = 0;
                if(clk_cnt_reg == 499) begin
                    state_next = DEVICE_ID1;
                    clk_cnt_next = 0;
                end
                else begin
                    clk_cnt_next = clk_cnt_reg + 1;
                end
            end
            DEVICE_ID1: begin
                SCL = 0;
                SDA = temp_data_reg[23];
                if(clk_cnt_reg == 249) begin
                    state_next = DEVICE_ID2;
                    clk_cnt_next = 0;
                end
                else begin
                    clk_cnt_next = clk_cnt_reg + 1;
                end
            end
            DEVICE_ID2: begin
                SCL = 1;
                SDA = temp_data_reg[23];
                if(clk_cnt_reg == 249) begin
                    state_next = DEVICE_ID3;
                    clk_cnt_next = 0;
                end
                else begin
                    clk_cnt_next = clk_cnt_reg + 1;
                end
            end
            DEVICE_ID3: begin
                SCL = 1;
                SDA = temp_data_reg[23];
                if(clk_cnt_reg == 249) begin
                    state_next = DEVICE_ID4;
                    clk_cnt_next = 0;
                end
                else begin
                    clk_cnt_next = clk_cnt_reg + 1;
                end
            end
            DEVICE_ID4: begin
                SCL = 0;
                SDA = temp_data_reg[23];
                if(clk_cnt_reg == 249) begin
                    clk_cnt_next = 0;
                    if(bit_cnt_reg == 8) begin
                        state_next = ADDRESS1;
                        bit_cnt_next = 0;
                    end
                    else begin
                        temp_data_next = {temp_data_reg[22:0], 1'b0};
                        bit_cnt_next = bit_cnt_reg + 1;
                        state_next = DEVICE_ID1;
                    end
                end
                else begin
                    clk_cnt_next = clk_cnt_reg + 1;
                end
            end
            ADDRESS1: begin
                SCL = 0;
                SDA = temp_data_reg[23];
                if(clk_cnt_reg == 249) begin
                    state_next = ADDRESS2;
                    clk_cnt_next = 0;
                end
                else begin
                    clk_cnt_next = clk_cnt_reg + 1;
                end
            end
            ADDRESS2: begin
                SCL = 1;
                SDA = temp_data_reg[23];
                if(clk_cnt_reg == 249) begin
                    state_next = ADDRESS3;
                    clk_cnt_next = 0;
                end
                else begin
                    clk_cnt_next = clk_cnt_reg + 1;
                end
            end
            ADDRESS3: begin
                SCL = 1;
                SDA = temp_data_reg[23];
                if(clk_cnt_reg == 249) begin
                    state_next = ADDRESS4;
                    clk_cnt_next = 0;
                end
                else begin
                    clk_cnt_next = clk_cnt_reg + 1;
                end
            end
            ADDRESS4: begin
                SCL = 0;
                SDA = temp_data_reg[23];
                SDA = temp_data_reg[23];
                if(clk_cnt_reg == 249) begin
                    clk_cnt_next = 0;
                    if(bit_cnt_reg == 8) begin
                        state_next = DATA1;
                        bit_cnt_next = 0;
                    end
                    else begin
                        temp_data_next = {temp_data_reg[22:0], 1'b0};
                        bit_cnt_next = bit_cnt_reg + 1;
                        state_next = ADDRESS1;
                    end
                end
                else begin
                    clk_cnt_next = clk_cnt_reg + 1;
                end
            end
            DATA1: begin
                SCL = 0;
                SDA = temp_data_reg[23];
                if(clk_cnt_reg == 249) begin
                    state_next = DATA2;
                    clk_cnt_next = 0;
                end
                else begin
                    clk_cnt_next = clk_cnt_reg + 1;
                end
            end
            DATA2: begin
                SCL = 1;
                SDA = temp_data_reg[23];
                if(clk_cnt_reg == 249) begin
                    state_next = DATA3;
                    clk_cnt_next = 0;
                end
                else begin
                    clk_cnt_next = clk_cnt_reg + 1;
                end
            end
            DATA3: begin
                SCL = 1;
                SDA = temp_data_reg[23];
                if(clk_cnt_reg == 249) begin
                    state_next = DATA4;
                    clk_cnt_next = 0;
                end
                else begin
                    clk_cnt_next = clk_cnt_reg + 1;
                end
            end
            DATA4: begin
                SCL = 0;
                SDA = temp_data_reg[23];
                if(clk_cnt_reg == 249) begin
                    clk_cnt_next = 0;
                    if(bit_cnt_reg == 8) begin
                        bit_cnt_next = 0;
                        state_next = STOP1;
                    end
                    else begin
                        temp_data_next = {temp_data_reg[22:0], 1'b0};
                        bit_cnt_next = bit_cnt_reg + 1;
                        state_next = DATA1;
                    end
                end
                else begin
                    clk_cnt_next = clk_cnt_reg + 1;
                end
            end
            STOP1: begin
                SCL = 1;
                SDA = 0;
                if(clk_cnt_reg == 499) begin
                    clk_cnt_next = 0;
                    state_next = STOP2;
                end
                else begin
                    clk_cnt_next = clk_cnt_reg + 1;
                end
            end
            STOP2: begin
                SCL = 1;
                SDA = 1;
                if(clk_cnt_reg == 499) begin
                    clk_cnt_next = 0;
                    if(addr_reg == 75) begin
                        state_next = IDLE;
                    end
                    else begin
                        addr_next = addr_reg + 1;
                        state_next = HOLD;
                    end
                end
                else begin
                    clk_cnt_next = clk_cnt_reg + 1;
                end
            end
            HOLD: begin
                if(clk_cnt_reg == 499) begin
                    state_next = START1;
                    clk_cnt_next = 0;
                end
                else begin
                    clk_cnt_next = clk_cnt_reg + 1;
                end
            end
        endcase
    end


endmodule


module btn_debounce (
    input clk,
    input reset,
    input i_btn,
    output o_btn
);

    reg state, next;
    reg [7:0] q_reg , q_next;
    reg edge_detect;

    wire btn_deb;

    // 1mhz clk generate
    reg [$clog2(100) - 1 : 0] counter;
    reg r_1mhz;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter <= 0;
            r_1mhz <= 1'b0;
        end
        else if (counter == 100 - 1) begin
            counter <= 0;
            r_1mhz <= 1'b1;
        end
        else begin
            counter <= counter + 1;
            r_1mhz <= 1'b0;
        end                   
    end

    // SR state logic
    always @(posedge r_1mhz, posedge reset) begin
        if (reset)  begin
            q_reg <= 0;
        end
        else begin
            q_reg <= q_next;  
        end      
    end
    
    // next logic
    always @(r_1mhz, i_btn, q_reg) begin
        q_next = {i_btn, q_reg[7:1]};  // 8SR 마지막 비트 밀어내기       
    end

    // 8-input and gate
    assign btn_deb = &q_reg; 

    // edge detector
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            edge_detect <= 1'b0 ;
        end else begin
            edge_detect <= btn_deb;
        end
    end

    // final output
    assign o_btn = btn_deb & (~ edge_detect);
endmodule 

module OV7670_config_rom (
    input logic clk,
    input logic [7:0] addr,
    output logic [15:0] dout
);

    //FFFF is end of rom, FFF0 is delay
    always @(posedge clk) begin
        case (addr)
            0: dout <= 16'h12_80;  //reset
            1: dout <= 16'hFF_F0;  //delay
            2: dout <= 16'h12_14;  // COM7,     set RGB color output and set QVGA
            3: dout <= 16'h11_80;  // CLKRC     internal PLL matches input clock
            4: dout <= 16'h0C_04;  // COM3,     default settings
            5: dout <= 16'h3E_19;  // COM14,    no scaling, normal pclock
            6: dout <= 16'h04_00;  // COM1,     disable CCIR656
            7: dout <= 16'h40_d0;  //COM15,     RGB565, full output range
            8: dout <= 16'h3a_04;  //TSLB       
            9: dout <= 16'h14_18;  //COM9       MAX AGC value x4
            10: dout <= 16'h4F_B3;  //MTX1       
            11: dout <= 16'h50_B3;  //MTX2
            12: dout <= 16'h51_00;  //MTX3
            13: dout <= 16'h52_3d;  //MTX4
            14: dout <= 16'h53_A7;  //MTX5
            15: dout <= 16'h54_E4;  //MTX6
            16: dout <= 16'h58_9E;  //MTXS
            17:
            dout <= 16'h3D_C0; //COM13      sets gamma enable, does not preserve reserved bits, may be wrong?
            18: dout <= 16'h17_15;  //HSTART     start high 8 bits 
            19:
            dout <= 16'h18_03; //HSTOP      stop high 8 bits //these kill the odd colored line
            20: dout <= 16'h32_00;  //91  //HREF       edge offset
            21: dout <= 16'h19_03;  //VSTART     start high 8 bits
            22: dout <= 16'h1A_7B;  //VSTOP      stop high 8 bits
            23: dout <= 16'h03_00;  // 00 //VREF       vsync edge offset
            24: dout <= 16'h0F_41;  //COM6       reset timings
            25:
            dout <= 16'h1E_00; //MVFP       disable mirror / flip //might have magic value of 03
            26: dout <= 16'h33_0B;  //CHLF       //magic value from the internet
            27: dout <= 16'h3C_78;  //COM12      no HREF when VSYNC low
            28: dout <= 16'h69_00;  //GFIX       fix gain control
            29: dout <= 16'h74_00;  //REG74      Digital gain control
            30:
            dout <= 16'hB0_84; //RSVD       magic value from the internet *required* for good color
            31: dout <= 16'hB1_0c;  //ABLC1
            32: dout <= 16'hB2_0e;  //RSVD       more magic internet values
            33: dout <= 16'hB3_80;  //THL_ST
            //begin mystery scaling numbers
            34: dout <= 16'h70_3a;
            35: dout <= 16'h71_35;
            36: dout <= 16'h72_11;
            37: dout <= 16'h73_f1;
            38: dout <= 16'ha2_02;
            //gamma curve values
            39: dout <= 16'h7a_20;
            40: dout <= 16'h7b_10;
            41: dout <= 16'h7c_1e;
            42: dout <= 16'h7d_35;
            43: dout <= 16'h7e_5a;
            44: dout <= 16'h7f_69;
            45: dout <= 16'h80_76;
            46: dout <= 16'h81_80;
            47: dout <= 16'h82_88;
            48: dout <= 16'h83_8f;
            49: dout <= 16'h84_96;
            50: dout <= 16'h85_a3;
            51: dout <= 16'h86_af;
            52: dout <= 16'h87_c4;
            53: dout <= 16'h88_d7;
            54: dout <= 16'h89_e8;
            //AGC and AEC
            55: dout <= 16'h13_e0;  //COM8, disable AGC / AEC
            56: dout <= 16'h00_00;  //set gain reg to 0 for AGC
            57: dout <= 16'h10_00;  //set ARCJ reg to 0
            58: dout <= 16'h0d_40;  //magic reserved bit for COM4
            59: dout <= 16'h14_18;  //COM9, 4x gain + magic bit
            60: dout <= 16'ha5_05;  // BD50MAX
            61: dout <= 16'hab_07;  //DB60MAX
            62: dout <= 16'h24_95;  //AGC upper limit
            63: dout <= 16'h25_33;  //AGC lower limit
            64: dout <= 16'h26_e3;  //AGC/AEC fast mode op region
            65: dout <= 16'h9f_78;  //HAECC1
            66: dout <= 16'ha0_68;  //HAECC2
            67: dout <= 16'ha1_03;  //magic
            68: dout <= 16'ha6_d8;  //HAECC3
            69: dout <= 16'ha7_d8;  //HAECC4
            70: dout <= 16'ha8_f0;  //HAECC5
            71: dout <= 16'ha9_90;  //HAECC6
            72: dout <= 16'haa_94;  //HAECC7
            73: dout <= 16'h13_e7;  //COM8, enable AGC / AEC
            74: dout <= 16'h69_07;
            default: dout <= 16'hFF_FF;  //mark end of ROM

        endcase
    end
endmodule
