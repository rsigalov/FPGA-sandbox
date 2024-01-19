module vga_test_2(
  input i_clk,
  input i_switch_1,
  input i_uart_rx,
  output o_uart_tx,

  // 7 segment display outputs
  output o_seg_1A,
  output o_seg_1B,
  output o_seg_1C,
  output o_seg_1D,
  output o_seg_1E,
  output o_seg_1F,
  output o_seg_1G,
  
  output o_seg_2A,
  output o_seg_2B,
  output o_seg_2C,
  output o_seg_2D,
  output o_seg_2E,
  output o_seg_2F,
  output o_seg_2G,

  // VGA outputs
  output o_VGA_HSync,
  output o_VGA_VSync,
  output o_VGA_Red_0,
  output o_VGA_Red_1,
  output o_VGA_Red_2,
  output o_VGA_Grn_0,
  output o_VGA_Grn_1,
  output o_VGA_Grn_2,
  output o_VGA_Blu_0,
  output o_VGA_Blu_1,
  output o_VGA_Blu_2  
);

  // Using my own UART_TX and UART_RX modules because the other ones don't
  // work and I am not sure why exactly. Should investigate
  wire [7:0] w_uart_data;
  wire w_uart_dv;

  wire [3:0] w_disp1_data;
  wire [3:0] w_disp2_data;
  
  assign w_disp_1_data = w_uart_data[3:0];
  assign w_disp_2_data = w_uart_data[7:4];

  UART_RX #(.CLKS_PER_BIT(217)) UART_RX_inst (
    .i_clk(i_clk),
    .i_uart_rx(i_uart_rx),
    .o_uart_dv(w_uart_dv),
    // .o_uart_dv(w_uart_dv),
    .o_uart_data(w_uart_data)
  );

  wire w_uart_tx_done;
  wire [7:0] w_uart_tx_data;
  wire w_uart_tx_dv;

  UART_TX #(.CLKS_PER_BIT(217)) UART_TX_inst (
    .i_clk(i_clk),
    .i_uart_dv(w_uart_tx_dv),
    .i_uart_data(w_uart_tx_data),
    .o_uart_tx(o_uart_tx),
    .o_done(w_uart_tx_done),   // leave unconnected
    .o_active()  // leave unconnected
  );

  binary_to_7seg_display disp1 (
    .i_clk(i_clk),
    .i_binary_num(w_uart_data[7:4]),
    .o_seg_A(o_seg_1A),
    .o_seg_B(o_seg_1B),
    .o_seg_C(o_seg_1C),
    .o_seg_D(o_seg_1D),
    .o_seg_E(o_seg_1E),
    .o_seg_F(o_seg_1F),
    .o_seg_G(o_seg_1G)
  );
  
  binary_to_7seg_display disp2 (
    .i_clk(i_clk),
    .i_binary_num(w_uart_data[3:0]),
    .o_seg_A(o_seg_2A),
    .o_seg_B(o_seg_2B),
    .o_seg_C(o_seg_2C),
    .o_seg_D(o_seg_2D),
    .o_seg_E(o_seg_2E),
    .o_seg_F(o_seg_2F),
    .o_seg_G(o_seg_2G)
  );


  //////////////////////////////////////////////////////////////////
  // VGA Test Patterns
  //////////////////////////////////////////////////////////////////

  // VGA Constants to set Frame Size
  parameter c_VIDEO_WIDTH = 3;
  parameter c_TOTAL_COLS  = 800;
  parameter c_TOTAL_ROWS  = 525;
  parameter c_ACTIVE_COLS = 640;
  parameter c_ACTIVE_ROWS = 480;
   
  wire w_RX_DV;
  wire [7:0] w_RX_Byte;
  wire w_TX_Active, w_TX_Serial;

  wire w_HSync_Start, w_VSync_Start;
  wire w_HSync_TP, w_VSync_TP;
  wire w_HSync_Porch, w_VSync_Porch;

  reg [3:0] r_TP_Index;

  reg [3:0] w_fixed_pattern = 5;

  // Common VGA Signals
  wire [c_VIDEO_WIDTH-1:0] w_Red_Video_TP, w_Red_Video_Porch;
  wire [c_VIDEO_WIDTH-1:0] w_Grn_Video_TP, w_Grn_Video_Porch;
  wire [c_VIDEO_WIDTH-1:0] w_Blu_Video_TP, w_Blu_Video_Porch;

  // Purpose: Register test pattern from UART when DV pulse is seen
  // Only least significant 4 bits are needed from whole byte.
  always @(posedge i_clk)
  begin
    if (w_uart_dv == 1'b1)
      r_TP_Index <= w_uart_data[3:0];
  end

  // Sending coordinates to UART
  wire [9:0] w_Col_Count;
  wire [9:0] w_Row_Count;

  Sync_To_Count #(.TOTAL_COLS(c_TOTAL_COLS),
                  .TOTAL_ROWS(c_TOTAL_ROWS))
  Sync_To_Count_Inst (.i_Clk      (i_Clk),
       .i_HSync    (w_HSync_TP),
       .i_VSync    (w_VSync_TP),
       .o_HSync    (),
       .o_VSync    (),
       .o_Col_Count(w_Col_Count),
       .o_Row_Count(w_Row_Count)
      );

  
  wire w_switch_debounced_1;

  debounce_filter #(.DEBOUNCE_LIMIT(20)) debounce_filter_1 (
    .i_clk(i_clk),
    .i_switch(i_switch_1),
    .o_switch_debounced(w_switch_debounced_1)
  );

  reg r_switch_1;

  always @(posedge i_clk)
  begin
    r_switch_1 <= w_switch_debounced_1;

    if (r_switch_1 == 1'b1 && w_switch_debounced_1 == 1'b0)
    begin
      w_uart_tx_dv <= 1'b1;
      w_uart_tx_data <= {5'b00000, w_Grn_Video_Porch};
    end

    if (w_uart_tx_dv == 1'b1)
    begin
      w_uart_tx_dv <= 1'b0;
    end
  end
   
  // Generates Sync Pulses to run VGA
  VGA_Sync_Pulses #(.TOTAL_COLS(c_TOTAL_COLS),
                    .TOTAL_ROWS(c_TOTAL_ROWS),
                    .ACTIVE_COLS(c_ACTIVE_COLS),
                    .ACTIVE_ROWS(c_ACTIVE_ROWS)) 
  VGA_Sync_Pulses_Inst 
  (.i_Clk(i_clk),
   .o_HSync(w_HSync_Start),
   .o_VSync(w_VSync_Start),
   .o_Col_Count(),
   .o_Row_Count()
  );
   
  // Drives Red/Grn/Blue video - Test Pattern 5 (Color Bars)
  Test_Pattern_Gen  #(.VIDEO_WIDTH(c_VIDEO_WIDTH),
                      .TOTAL_COLS(c_TOTAL_COLS),
                      .TOTAL_ROWS(c_TOTAL_ROWS),
                      .ACTIVE_COLS(c_ACTIVE_COLS),
                      .ACTIVE_ROWS(c_ACTIVE_ROWS))
  Test_Pattern_Gen_Inst
   (.i_Clk(i_clk),
    // .i_Pattern(w_fixed_pattern),
    .i_Pattern(r_TP_Index),
    .i_HSync(w_HSync_Start),
    .i_VSync(w_VSync_Start),
    .o_HSync(w_HSync_TP),
    .o_VSync(w_VSync_TP),
    .o_Red_Video(w_Red_Video_TP),
    .o_Grn_Video(w_Grn_Video_TP),
    .o_Blu_Video(w_Blu_Video_TP));


  
     
  VGA_Sync_Porch  #(.VIDEO_WIDTH(c_VIDEO_WIDTH),
                    .TOTAL_COLS(c_TOTAL_COLS),
                    .TOTAL_ROWS(c_TOTAL_ROWS),
                    .ACTIVE_COLS(c_ACTIVE_COLS),
                    .ACTIVE_ROWS(c_ACTIVE_ROWS))
  VGA_Sync_Porch_Inst
   (.i_Clk(i_clk),
    .i_HSync(w_HSync_TP),
    .i_VSync(w_VSync_TP),
    .i_Red_Video(w_Red_Video_TP),
    .i_Grn_Video(w_Grn_Video_TP),
    .i_Blu_Video(w_Blu_Video_TP),
    .o_HSync(w_HSync_Porch),
    .o_VSync(w_VSync_Porch),
    .o_Red_Video(w_Red_Video_Porch),
    .o_Grn_Video(w_Grn_Video_Porch),
    .o_Blu_Video(w_Blu_Video_Porch));
       
  assign o_VGA_HSync = w_HSync_Porch;
  assign o_VGA_VSync = w_VSync_Porch;
       
  assign o_VGA_Red_0 = w_Red_Video_Porch[0];
  assign o_VGA_Red_1 = w_Red_Video_Porch[1];
  assign o_VGA_Red_2 = w_Red_Video_Porch[2];
   
  assign o_VGA_Grn_0 = w_Grn_Video_Porch[0];
  assign o_VGA_Grn_1 = w_Grn_Video_Porch[1];
  assign o_VGA_Grn_2 = w_Grn_Video_Porch[2];
 
  assign o_VGA_Blu_0 = w_Blu_Video_Porch[0];
  assign o_VGA_Blu_1 = w_Blu_Video_Porch[1];
  assign o_VGA_Blu_2 = w_Blu_Video_Porch[2];

endmodule

module debounce_filter #(parameter DEBOUNCE_LIMIT = 20) (
  input i_clk,
  input i_switch,
  output o_switch_debounced
);
  
  reg [($clog2(DEBOUNCE_LIMIT)-1):0] r_count = 0;
  reg r_state = 0;
  
  always @(posedge i_clk) begin
    if (i_switch !== r_state && r_count < DEBOUNCE_LIMIT-1)
    begin
      r_count <= r_count + 1;
    end
    else if (i_switch !== r_state && r_count == DEBOUNCE_LIMIT-1)
    begin
      r_state <= i_switch;
      r_count <= 0;
    end
    else
    begin
      r_count <= 0;  
    end  
  end
  
  assign o_switch_debounced = r_state;
  
endmodule

// This module is designed for 640x480 with a 25 MHz input clock.

module VGA_Sync_Pulses 
 #(parameter TOTAL_COLS  = 800, 
   parameter TOTAL_ROWS  = 525,
   parameter ACTIVE_COLS = 640, 
   parameter ACTIVE_ROWS = 480)
  (input            i_Clk, 
   output           o_HSync,
   output           o_VSync,
   output reg [9:0] o_Col_Count = 0, 
   output reg [9:0] o_Row_Count = 0
  );  
  
  always @(posedge i_Clk)
  begin
    if (o_Col_Count == TOTAL_COLS-1)
    begin
      o_Col_Count <= 0;
      if (o_Row_Count == TOTAL_ROWS-1)
        o_Row_Count <= 0;
      else
        o_Row_Count <= o_Row_Count + 1;
    end
    else
      o_Col_Count <= o_Col_Count + 1;
      
  end
	  
  assign o_HSync = o_Col_Count < ACTIVE_COLS ? 1'b1 : 1'b0;
  assign o_VSync = o_Row_Count < ACTIVE_ROWS ? 1'b1 : 1'b0;
  
endmodule

// The purpose of this module is to modify the input HSync and VSync signals to
// include some time for what is called the Front and Back porch.  The front
// and back porch of a VGA interface used to have more meaning when a monitor
// actually used a Cathode Ray Tube (CRT) to draw an image on the screen.  You
// can read more about the details of how old VGA monitors worked.  These
// days, the notion of a front and back porch is maintained, due more to
// convention than to the physics of the monitor.
// New standards like DVI and HDMI which are meant for digital signals have
// removed this notion of the front and back porches.  Remember that VGA is an
// analog interface.
// This module is designed for 640x480 with a 25 MHz input clock.

module VGA_Sync_Porch #(parameter VIDEO_WIDTH = 3,  // remember to 
                        parameter TOTAL_COLS  = 3,  // overwrite
                        parameter TOTAL_ROWS  = 3,  // these defaults
                        parameter ACTIVE_COLS = 2,
                        parameter ACTIVE_ROWS = 2)
  (input i_Clk,
   input i_HSync,
   input i_VSync,
   input [VIDEO_WIDTH-1:0] i_Red_Video,
   input [VIDEO_WIDTH-1:0] i_Grn_Video,
   input [VIDEO_WIDTH-1:0] i_Blu_Video,
   output reg o_HSync,
   output reg o_VSync,
   output reg [VIDEO_WIDTH-1:0] o_Red_Video,
   output reg [VIDEO_WIDTH-1:0] o_Grn_Video,
   output reg [VIDEO_WIDTH-1:0] o_Blu_Video
   );

  parameter c_FRONT_PORCH_HORZ = 18;
  parameter c_BACK_PORCH_HORZ  = 50;
  parameter c_FRONT_PORCH_VERT = 10;
  parameter c_BACK_PORCH_VERT  = 33;

  wire w_HSync;
  wire w_VSync;
  
  wire [9:0] w_Col_Count;
  wire [9:0] w_Row_Count;
  
  reg [VIDEO_WIDTH-1:0] r_Red_Video = 0;
  reg [VIDEO_WIDTH-1:0] r_Grn_Video = 0;
  reg [VIDEO_WIDTH-1:0] r_Blu_Video = 0;
  
  Sync_To_Count #(.TOTAL_COLS(TOTAL_COLS),
                  .TOTAL_ROWS(TOTAL_ROWS)) UUT 
  (.i_Clk      (i_Clk),
   .i_HSync    (i_HSync),
   .i_VSync    (i_VSync),
   .o_HSync    (w_HSync),
   .o_VSync    (w_VSync),
   .o_Col_Count(w_Col_Count),
   .o_Row_Count(w_Row_Count)
  );
	  
  // Purpose: Modifies the HSync and VSync signals to include Front/Back Porch
  always @(posedge i_Clk)
  begin
    if ((w_Col_Count < c_FRONT_PORCH_HORZ + ACTIVE_COLS) || 
        (w_Col_Count > TOTAL_COLS - c_BACK_PORCH_HORZ - 1))
      o_HSync <= 1'b1;
    else
      o_HSync <= w_HSync;
    
    if ((w_Row_Count < c_FRONT_PORCH_VERT + ACTIVE_ROWS) ||
        (w_Row_Count > TOTAL_ROWS - c_BACK_PORCH_VERT - 1))
      o_VSync <= 1'b1;
    else
      o_VSync <= w_VSync;
  end

  
  // Purpose: Align input video to modified Sync pulses.
  // Adds in 2 Clock Cycles of Delay
  always @(posedge i_Clk)
  begin
    r_Red_Video <= i_Red_Video;
    r_Grn_Video <= i_Grn_Video;
    r_Blu_Video <= i_Blu_Video;

    o_Red_Video <= r_Red_Video;
    o_Grn_Video <= r_Grn_Video;
    o_Blu_Video <= r_Blu_Video;
  end
  
endmodule

// This module will take incoming horizontal and veritcal sync pulses and
// create Row and Column counters based on these syncs.
// It will align the Row/Col counters to the output Sync pulses.
// Useful for any module that needs to keep track of which Row/Col position we
// are on in the middle of a frame
module Sync_To_Count 
 #(parameter TOTAL_COLS = 800,
   parameter TOTAL_ROWS = 525)
  (input            i_Clk,
   input            i_HSync,
   input            i_VSync, 
   output reg       o_HSync = 0,
   output reg       o_VSync = 0,
   output reg [9:0] o_Col_Count = 0,
   output reg [9:0] o_Row_Count = 0);
   
   wire w_Frame_Start;
   
  // Register syncs to align with output data.
  always @(posedge i_Clk)
  begin
    o_VSync <= i_VSync;
    o_HSync <= i_HSync;
  end

  // Keep track of Row/Column counters.
  always @(posedge i_Clk)
  begin
    if (w_Frame_Start == 1'b1)
    begin
      o_Col_Count <= 0;
      o_Row_Count <= 0;
    end
    else
    begin
      if (o_Col_Count == TOTAL_COLS-1)
      begin
        if (o_Row_Count == TOTAL_ROWS-1)
        begin
          o_Row_Count <= 0;
        end
        else
        begin
          o_Row_Count <= o_Row_Count + 1;
        end
        o_Col_Count <= 0;
      end
      else
      begin
        o_Col_Count <= o_Col_Count + 1;
      end
    end
  end
  
    
  // Look for rising edge on Vertical Sync to reset the counters
  assign w_Frame_Start = (~o_VSync & i_VSync);

endmodule


// This module is designed for 640x480 with a 25 MHz input clock.
// All test patterns are being generated all the time.  This makes use of one
// of the benefits of FPGAs, they are highly parallelizable.  Many different
// things can all be happening at the same time.  In this case, there are several
// test patterns that are being generated simulatenously.  The actual choice of
// which test pattern gets displayed is done via the i_Pattern signal, which is
// an input to a case statement.

// Available Patterns:
// Pattern 0: Disables the Test Pattern Generator
// Pattern 1: All Red
// Pattern 2: All Green
// Pattern 3: All Blue
// Pattern 4: Checkerboard white/black
// Pattern 5: Color Bars
// Pattern 6: White Box with Border (2 pixels)

// Note: Comment out this line when building in iCEcube2:
//`include "Sync_To_Count.v"


module Test_Pattern_Gen 
 #(parameter VIDEO_WIDTH = 3,
   parameter TOTAL_COLS = 800,
   parameter TOTAL_ROWS = 525,
   parameter ACTIVE_COLS = 640,
   parameter ACTIVE_ROWS = 480)
  (input       i_Clk,
   input [3:0] i_Pattern,
   input       i_HSync,
   input       i_VSync,
   output reg  o_HSync = 0,
   output reg  o_VSync = 0,
   output reg [VIDEO_WIDTH-1:0] o_Red_Video,
   output reg [VIDEO_WIDTH-1:0] o_Grn_Video,
   output reg [VIDEO_WIDTH-1:0] o_Blu_Video);
  
  wire w_VSync;
  wire w_HSync;
  
  
  // Patterns have 16 indexes (0 to 15) and can be g_Video_Width bits wide
  wire [VIDEO_WIDTH-1:0] Pattern_Red[0:15];
  wire [VIDEO_WIDTH-1:0] Pattern_Grn[0:15];
  wire [VIDEO_WIDTH-1:0] Pattern_Blu[0:15];
  
  // Make these unsigned counters (always positive)
  wire [9:0] w_Col_Count;
  wire [9:0] w_Row_Count;

  wire [6:0] w_Bar_Width;
  wire [2:0] w_Bar_Select;
  
  Sync_To_Count #(.TOTAL_COLS(TOTAL_COLS),
                  .TOTAL_ROWS(TOTAL_ROWS))
  
  UUT (.i_Clk      (i_Clk),
       .i_HSync    (i_HSync),
       .i_VSync    (i_VSync),
       .o_HSync    (w_HSync),
       .o_VSync    (w_VSync),
       .o_Col_Count(w_Col_Count),
       .o_Row_Count(w_Row_Count)
      );
	  
  
  // Register syncs to align with output data.
  always @(posedge i_Clk)
  begin
    o_VSync <= w_VSync;
    o_HSync <= w_HSync;
  end
  
  /////////////////////////////////////////////////////////////////////////////
  // Pattern 0: Disables the Test Pattern Generator
  /////////////////////////////////////////////////////////////////////////////
  assign Pattern_Red[0] = 0;
  assign Pattern_Grn[0] = 0;
  assign Pattern_Blu[0] = 0;
  
  /////////////////////////////////////////////////////////////////////////////
  // Pattern 1: All Red
  /////////////////////////////////////////////////////////////////////////////
  assign Pattern_Red[1] = (w_Col_Count < ACTIVE_COLS && w_Row_Count < ACTIVE_ROWS) ? {VIDEO_WIDTH{1'b1}} : 0;
  assign Pattern_Grn[1] = 0;
  assign Pattern_Blu[1] = 0;

  /////////////////////////////////////////////////////////////////////////////
  // Pattern 2: All Green
  /////////////////////////////////////////////////////////////////////////////
  assign Pattern_Red[2] = 0;
  assign Pattern_Grn[2] = (w_Col_Count < ACTIVE_COLS && w_Row_Count < ACTIVE_ROWS) ? {VIDEO_WIDTH{1'b1}} : 0;
  assign Pattern_Blu[2] = 0;
  
  /////////////////////////////////////////////////////////////////////////////
  // Pattern 3: All Blue
  /////////////////////////////////////////////////////////////////////////////
  assign Pattern_Red[3] = 0;
  assign Pattern_Grn[3] = 0;
  assign Pattern_Blu[3] = (w_Col_Count < ACTIVE_COLS && w_Row_Count < ACTIVE_ROWS) ? {VIDEO_WIDTH{1'b1}} : 0;

  /////////////////////////////////////////////////////////////////////////////
  // Pattern 4: Checkerboard white/black
  /////////////////////////////////////////////////////////////////////////////
  assign Pattern_Red[4] = w_Col_Count[5] ^ w_Row_Count[5] ? {VIDEO_WIDTH{1'b1}} : 0;
  assign Pattern_Grn[4] = Pattern_Red[4];
  assign Pattern_Blu[4] = Pattern_Red[4];
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Pattern 5: Color Bars
  // Divides active area into 8 Equal Bars and colors them accordingly
  // Colors Each According to this Truth Table:
  // R G B  w_Bar_Select  Ouput Color
  // 0 0 0       0        Black
  // 0 0 1       1        Blue
  // 0 1 0       2        Green
  // 0 1 1       3        Turquoise
  // 1 0 0       4        Red
  // 1 0 1       5        Purple
  // 1 1 0       6        Yellow
  // 1 1 1       7        White
  /////////////////////////////////////////////////////////////////////////////
  assign w_Bar_Width = ACTIVE_COLS/8;
  
  assign w_Bar_Select = w_Col_Count < w_Bar_Width*1 ? 0 : 
                        w_Col_Count < w_Bar_Width*2 ? 1 :
				        w_Col_Count < w_Bar_Width*3 ? 2 :
				        w_Col_Count < w_Bar_Width*4 ? 3 :
				        w_Col_Count < w_Bar_Width*5 ? 4 :
				        w_Col_Count < w_Bar_Width*6 ? 5 :
				        w_Col_Count < w_Bar_Width*7 ? 6 : 7;
				  
  // Implement Truth Table above with Conditional Assignments
  assign Pattern_Red[5] = (w_Bar_Select == 4 || w_Bar_Select == 5 ||
                           w_Bar_Select == 6 || w_Bar_Select == 7) ? 
                          {VIDEO_WIDTH{1'b1}} : 0;
					 
  assign Pattern_Grn[5] = (w_Bar_Select == 2 || w_Bar_Select == 3 ||
                           w_Bar_Select == 6 || w_Bar_Select == 7) ? 
                          {VIDEO_WIDTH{1'b1}} : 0;
					 					 
  assign Pattern_Blu[5] = (w_Bar_Select == 1 || w_Bar_Select == 3 ||
                           w_Bar_Select == 5 || w_Bar_Select == 7) ?
                          {VIDEO_WIDTH{1'b1}} : 0;


  /////////////////////////////////////////////////////////////////////////////
  // Pattern 6: Black With White Border
  // Creates a black screen with a white border 2 pixels wide around outside.
  /////////////////////////////////////////////////////////////////////////////
  assign Pattern_Red[6] = (w_Row_Count <= 1 || w_Row_Count >= ACTIVE_ROWS-1-1 ||
                           w_Col_Count <= 1 || w_Col_Count >= ACTIVE_COLS-1-1) ?
                          {VIDEO_WIDTH{1'b1}} : 0;
  assign Pattern_Grn[6] = Pattern_Red[6];
  assign Pattern_Blu[6] = Pattern_Red[6];
  

  /////////////////////////////////////////////////////////////////////////////
  // Select between different test patterns
  /////////////////////////////////////////////////////////////////////////////
  always @(posedge i_Clk)
  begin
    case (i_Pattern)
      4'h0 : 
      begin
	    o_Red_Video <= Pattern_Red[0];
        o_Grn_Video <= Pattern_Grn[0];
        o_Blu_Video <= Pattern_Blu[0];
      end
      4'h1 :
      begin
        o_Red_Video <= Pattern_Red[1];
        o_Grn_Video <= Pattern_Grn[1];
        o_Blu_Video <= Pattern_Blu[1];
      end
      4'h2 :
      begin
        o_Red_Video <= Pattern_Red[2];
        o_Grn_Video <= Pattern_Grn[2];
        o_Blu_Video <= Pattern_Blu[2];
      end
      4'h3 :
      begin
        o_Red_Video <= Pattern_Red[3];
        o_Grn_Video <= Pattern_Grn[3];
        o_Blu_Video <= Pattern_Blu[3];
      end
      4'h4 :
      begin
        o_Red_Video <= Pattern_Red[4];
        o_Grn_Video <= Pattern_Grn[4];
        o_Blu_Video <= Pattern_Blu[4];
      end
      4'h5 :
      begin
        o_Red_Video <= Pattern_Red[5];
        o_Grn_Video <= Pattern_Grn[5];
        o_Blu_Video <= Pattern_Blu[5];
      end
      4'h6 :
      begin
        o_Red_Video <= Pattern_Red[6];
        o_Grn_Video <= Pattern_Grn[6];
        o_Blu_Video <= Pattern_Blu[6];
      end
      default:
      begin
        o_Red_Video <= Pattern_Red[0];
        o_Grn_Video <= Pattern_Grn[0];
        o_Blu_Video <= Pattern_Blu[0];
      end
    endcase
  end
endmodule



module UART_TX #(parameter CLKS_PER_BIT = 217) (
  input       i_clk,
  input       i_uart_dv,
  input [7:0] i_uart_data,
  output      o_uart_tx,
  output      o_done,
  output      o_active
);

  // Enumerating possible states
  localparam IDLE      = 2'b00;
  localparam START_BIT = 2'b01;
  localparam DATA_BIT  = 2'b10;
  localparam END_BIT   = 2'b11;
  
  reg [2:0] r_state;
  reg [2:0] r_index;
  reg [$clog2(CLKS_PER_BIT-1):0] r_counter;
  reg r_active;
  reg r_done;
  reg r_uart_tx;
  

  always @(posedge i_clk)
    begin

      case (r_state)

        IDLE:
          begin
            r_uart_tx <= 1'b1; // default value is 1
            r_index <= 0;
            r_counter <= 0;
            r_active <= 1'b0;
            r_done <= 1'b0;

            if (i_uart_dv)
              begin
                // r_uart_tx <= 1'b0;
                r_active <= 1'b1;
                r_state <= START_BIT;
              end
            else
              begin
                r_state <= IDLE;
              end
          end

        START_BIT:
          begin
            r_uart_tx <= 1'b0;

            if (r_counter == CLKS_PER_BIT - 1)
              begin
                r_counter <= 0;
                r_state <= DATA_BIT;
              end
            else
              begin
                r_counter <= r_counter + 1;
                r_state <= START_BIT;
              end
          end

        DATA_BIT:
          begin
            r_uart_tx <= i_uart_data[r_index];

            if (r_counter == CLKS_PER_BIT - 1)
              begin

                r_counter <= 0;

                if (r_index == 7)
                  begin
                    r_index <= 0;
                    r_state <= END_BIT;
                  end
                else
                  begin
                    r_index <= r_index + 1;
                    r_state <= DATA_BIT;
                  end
              end
            else
              begin
                r_counter <= r_counter + 1;
                r_state <= DATA_BIT;
              end
          end

        END_BIT:
          begin

            r_uart_tx <= 1'b1;

            if (r_counter == CLKS_PER_BIT - 1)
              begin
                r_counter <= 0;
                r_state <= IDLE;
                r_active <= 1'b0;
                r_done <= 1'b1;
              end
            else
              begin
                r_counter <= r_counter + 1;
              end
          end


        default:
          r_state <= IDLE;

      endcase


    end
  
  assign o_active = r_active;
  assign o_done = r_done;
  assign o_uart_tx = r_uart_tx;

endmodule


module UART_RX #(parameter CLKS_PER_BIT = 217) (
  input i_clk,
  input i_uart_rx,
  output o_uart_dv,
  output [7:0] o_uart_data
);
  
  localparam IDLE      = 3'd0;
  localparam START_BIT = 3'd1;
  localparam READ_BIT  = 3'd2;
  localparam STOP_BIT  = 3'd3;
  localparam DONE      = 3'd4;
  
  reg [3:0] r_state      = 0;
  reg [$clog2(CLKS_PER_BIT-1):0] r_counter    = 0;
  reg [7:0] r_uart_data  = 0;
  reg [3:0] r_bit_index  = 0;
  reg       r_uart_dv    = 0;
  
  
  
  always @(posedge i_clk)
    begin
      
      case (r_state)
        
        IDLE:
          begin
            r_uart_dv <= 1'b0;
            r_counter <= 0;
            r_bit_index <= 0;
            
            if (~i_uart_rx)
              r_state <= START_BIT;
            else
              r_state <= IDLE;
          end
        
        START_BIT:
          begin
            if (r_counter == CLKS_PER_BIT/2)
              begin
                // Make sure that start bit is still zero. If it is, move
                // to reading data, otherwise, back to IDLE
                if (~i_uart_rx)
                  begin
                    r_state <= READ_BIT;
                    r_counter <= 0;
                  end
                else 
                  begin
                    r_state <= IDLE;
                  end
              end
            else
              begin
                r_counter <= r_counter + 1;
              end
          end 
        
        READ_BIT:
          begin
            if (r_counter == CLKS_PER_BIT) 
              begin
                r_uart_data[r_bit_index] = i_uart_rx;
                r_counter <= 0;
                
                // Check if we received all bits
                if (r_bit_index == 3'b111)
                  begin
                    r_state <= STOP_BIT;
                  end
                else
                  begin
                    r_state <= READ_BIT;
                  	r_bit_index <= r_bit_index + 1;
                  end
              end
            else
              begin
                r_counter <= r_counter + 1;
              end
            
              
          end
        
        STOP_BIT:
          begin
            if (r_counter == CLKS_PER_BIT-1)
              begin
                r_uart_dv <= 1'b1;
                r_state <= DONE;
              end
            else
              begin
                r_counter <= r_counter + 1;
              end
          end
        
        DONE:
          begin
            r_uart_dv <= 1'b0;
            r_counter <= 0;
            r_state <= IDLE;
          end
          
      endcase
      
    end
  
  assign o_uart_dv = r_uart_dv;
  assign o_uart_data = r_uart_data;
  
endmodule

module binary_to_7seg_display(
  input i_clk, // do I really need it, or should I just hard wire
  input [3:0] i_binary_num,
  output o_seg_A,
  output o_seg_B,
  output o_seg_C,
  output o_seg_D,
  output o_seg_E,
  output o_seg_F,
  output o_seg_G
);
  
  reg [6:0] r_hex_encoding;
  
  always @(posedge i_clk)
    begin
      case (i_binary_num)
        4'b0000 : r_hex_encoding <= 7'b1111110; // 0
        4'b0001 : r_hex_encoding <= 7'b0110000; // 1
        4'b0010 : r_hex_encoding <= 7'b1101101; // 2
        4'b0011 : r_hex_encoding <= 7'b1111001; // 3
        4'b0100 : r_hex_encoding <= 7'b0110011; // 4
        4'b0101 : r_hex_encoding <= 7'b1011011; // 5
        4'b0110 : r_hex_encoding <= 7'b1011111; // 6
        4'b0111 : r_hex_encoding <= 7'b1110000; // 7
        4'b1000 : r_hex_encoding <= 7'b1111111; // 8
        4'b1001 : r_hex_encoding <= 7'b1111011; // 9
        4'b1010 : r_hex_encoding <= 7'b1110111; // A
        4'b1011 : r_hex_encoding <= 7'b0011111; // B
        4'b1100 : r_hex_encoding <= 7'b1001110; // C
        4'b1101 : r_hex_encoding <= 7'b0111101; // D
        4'b1110 : r_hex_encoding <= 7'b1001111; // E
        4'b1111 : r_hex_encoding <= 7'b1000111; // F
      endcase
    end      
    
  // Need to invert connections
  assign o_seg_A = ~r_hex_encoding[6];
  assign o_seg_B = ~r_hex_encoding[5];
  assign o_seg_C = ~r_hex_encoding[4];
  assign o_seg_D = ~r_hex_encoding[3];
  assign o_seg_E = ~r_hex_encoding[2];
  assign o_seg_F = ~r_hex_encoding[1];
  assign o_seg_G = ~r_hex_encoding[0];
  
endmodule