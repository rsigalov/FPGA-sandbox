// High level module
module pattern_game_top(
  input i_clk,
  input i_switch_1,
  input i_switch_2,
  input i_switch_3,
  input i_switch_4,
  output o_led_1,
  output o_led_2,
  output o_led_3,
  output o_led_4,
  output o_disp_A,
  output o_disp_B,
  output o_disp_C,
  output o_disp_D,
  output o_disp_E,
  output o_disp_F,
  output o_disp_G
);
  
  // Parameters
  localparam DEBOUNCE_LIMIT = 250000;
  localparam CLKS_PER_SEC = 25000000;
  // localparam DEBOUNCE_LIMIT = 10;
  // localparam CLKS_PER_SEC = 100;
  localparam GAME_LIMIT = 10;
  
  wire w_switch_1, w_switch_2, w_switch_3, w_switch_4;
  wire w_disp_A, w_disp_B, w_disp_C, w_dist_D;
  wire w_disp_E, w_disp_F, w_disp_G;
  
  wire [3:0] w_score;
  
  debounce_filter #(.DEBOUNCE_LIMIT(DEBOUNCE_LIMIT)) debounce_switch_inst_1(
    .i_clk(i_clk),
    .i_switch(i_switch_1),
    .o_switch_debounced(w_switch_1)
  );
  
  debounce_filter #(.DEBOUNCE_LIMIT(DEBOUNCE_LIMIT)) debounce_switch_inst_2(
    .i_clk(i_clk),
    .i_switch(i_switch_2),
    .o_switch_debounced(w_switch_2)
  );
  
  debounce_filter #(.DEBOUNCE_LIMIT(DEBOUNCE_LIMIT)) debounce_switch_inst_3(
    .i_clk(i_clk),
    .i_switch(i_switch_3),
    .o_switch_debounced(w_switch_3)
  );
  
  debounce_filter #(.DEBOUNCE_LIMIT(DEBOUNCE_LIMIT)) debounce_switch_inst_4(
    .i_clk(i_clk),
    .i_switch(i_switch_4),
    .o_switch_debounced(w_switch_4)
  );
  
  pattern_game_logic #(.GAME_LIMIT(GAME_LIMIT), .CLKS_PER_SEC(CLKS_PER_SEC)) game_inst(
    .i_clk(i_clk),
    .i_switch_1(w_switch_1),
    .i_switch_2(w_switch_2),
    .i_switch_3(w_switch_3),
    .i_switch_4(w_switch_4),
    .o_score(w_score),
    .o_led_1(o_led_1),
    .o_led_2(o_led_2),
    .o_led_3(o_led_3),
    .o_led_4(o_led_4)
  );
  
  binary_to_7seg_display bto7seg_inst (
    .i_clk(i_clk),
    .i_binary_num(w_score),
    .o_seg_A(w_disp_A),
    .o_seg_B(w_disp_B),
    .o_seg_C(w_disp_C),
    .o_seg_D(w_disp_D),
    .o_seg_E(w_disp_E),
    .o_seg_F(w_disp_F),
    .o_seg_G(w_disp_G)
  );
  
  // Inverting the 7-segment display output
  assign o_disp_A = !w_disp_A;
  assign o_disp_B = !w_disp_B;
  assign o_disp_C = !w_disp_C;
  assign o_disp_D = !w_disp_D;
  assign o_disp_E = !w_disp_E;
  assign o_disp_F = !w_disp_F;
  assign o_disp_G = !w_disp_G;
  
  
endmodule

module pattern_game_logic #(
  			parameter GAME_LIMIT = 6, 
  			parameter CLKS_PER_SEC = 25000000) (
  input i_clk,
  input i_switch_1,
  input i_switch_2,
  input i_switch_3,
  input i_switch_4,
  output [3:0] o_score,
  output o_led_1,
  output o_led_2,
  output o_led_3,
  output o_led_4
);
  
  // Encoding possible states
  localparam START        = 3'd0;
  localparam PATTERN_OFF  = 3'd1;
  localparam PATTERN_SHOW = 3'd2;
  localparam WAIT_PLAYER  = 3'd3;
  localparam INCR_SCORE   = 3'd4;
  localparam FAILURE      = 3'd5;
  localparam WINNER       = 3'd6;
  
  // Registers and wires
  reg [2:0] r_state;                        // to keep track of the state
  reg [1:0] r_pattern[0:10];                // 2-D array representing the pattern
  reg [1:0] r_switch_id;                    // what switch was pressed
  reg r_switch_dv;                          // indicator if can look at r_switch_id
  reg [3:0] r_score;
  reg [$clog2(GAME_LIMIT)-1:0] r_index;     // Index in the current pattern
  wire [21:0] w_lfsr_data;                  // To save "random" data from LFSR and save
  											// to r_pattern when the game starts
  
  // To allow falling edge detection of count_and_toggle
  // low w_toggle and high r_toggle indicates a falling edge
  reg r_toggle;                             // to monitor count_and_toggle delay
  wire w_toggle;                            // output of count_and_toggle
  wire w_counter_enable;
  
  reg r_switch_1;
  reg r_switch_2; 
  reg r_switch_3; 
  reg r_switch_4;
  
//   count_and_toggle #(.COUNT_LIMIT(CLKS_PER_SEC/4)) count_and_toggle_inst (
//     .i_clk(i_clk),
//     .i_enable(w_counter_enable),
//     .o_toggle(w_toggle)
//   );
  
  // Using external module, mine doesn't work for some reason
  Count_And_Toggle #(.COUNT_LIMIT(CLKS_PER_SEC/4)) Count_And_Toggle_Inst(
    .i_Clk(i_clk),
    .i_Enable(w_counter_enable),
    .o_Toggle(w_toggle)
  );
  
  always @(posedge i_clk)
    begin
      r_toggle <= w_toggle;
    end
  
  // Note that we don't light any LEDs inside of the main
  // logic. This will follow in a separate block
  always @(posedge i_clk)
    begin
      // reset logic (push two buttons)
      if (i_switch_1 & i_switch_4)
        begin
          r_state <= START;
        end
      
      // actions and transitions for each state
      case (r_state)
        
        // Wait for the RESET combination to be released and
        // then transition to the next state
        START:
        begin
          if (!i_switch_1 & !i_switch_4 & r_switch_dv)
            begin
              r_state <= PATTERN_OFF;
              r_score <= 0;
              r_index <= 0;
            end
        end
          
        PATTERN_OFF:
        begin
          if (!w_toggle & r_toggle)
            begin
              r_state <= PATTERN_SHOW;
            end
        end
        
        PATTERN_SHOW:
        begin
          if (!w_toggle & r_toggle)
            begin
              // If finished showing the sequence move to wait for player
              // Otherwise, increment the index and move to PATTERN_OFF
              if (r_score == r_index)
                begin
                  r_state <= WAIT_PLAYER;
                  r_index <= 0;
                end
              else
                begin
                  r_state <= PATTERN_OFF;
                  r_index <= r_index + 1;
                end
            end
        end
        
        WAIT_PLAYER:
        begin
          // Registering any button press
          if (r_switch_dv)
            begin
          
              if (r_pattern[r_index] == r_switch_id) // Correct button
                begin
                  if (r_index == r_score)
                    begin
                      r_state <= INCR_SCORE;
                      r_index <= 0;
                    end
                  else 
                    begin
                      r_state <= WAIT_PLAYER; // not necessary
                      r_index <= r_index + 1;
                    end
                end
              else if (r_pattern[r_index] !== r_switch_id) // Incorrect button
                begin
                  r_state <= FAILURE;
                end
            end
        end
        
        INCR_SCORE:
        begin
          r_score <= r_score + 1;
          if (r_score == GAME_LIMIT-1)
            begin
              r_state <= WINNER;
            end
          else
            begin
              r_state <= PATTERN_OFF;
            end
        end
        
        FAILURE:
        begin
          // TODO Display "F" on the 7-segment display
          r_score <= 4'hF;
        end
        
        WINNER:
        begin
          // TODO Display "A" on the 7-segment display
          r_score <= 4'hE;
        end
        
        default:
        begin
          r_state <= START;
        end
          
      endcase
      
    end
    
  	// Logic for detecting the falling edge of button presses
  	// and assigning the correct ID and setting DataValid (DV) high
    // Whenever r_switch_dv is high, we can look at r_switch_id
    // to determing what switch was pressed.
    always @(posedge i_clk)
      begin
        
		r_switch_1 <= i_switch_1;
        r_switch_2 <= i_switch_2;
        r_switch_3 <= i_switch_3;
        r_switch_4 <= i_switch_4;
        
        if (!i_switch_1 & r_switch_1)
          begin
            r_switch_dv <= 1'b1;
            r_switch_id <= 0;
          end
        else if (!i_switch_2 & r_switch_2)
          begin
            r_switch_dv <= 1'b1;
            r_switch_id <= 1;
          end
        else if (!i_switch_3 & r_switch_3)
          begin
            r_switch_dv <= 1'b1;
            r_switch_id <= 2;
          end
        else if (!i_switch_4 & r_switch_4)
          begin
            r_switch_dv <= 1'b1;
            r_switch_id <= 3;
          end
        else
          begin
            r_switch_dv <= 1'b0;
            r_switch_dv <= 0;
          end
      end
  
  // Logic for turning on LEDs either when showing the pattern
  // or when the player presses a switch
  assign o_led_1 = (r_state == PATTERN_SHOW && r_pattern[r_index] == 2'b00) ? 1'b1 : i_switch_1;
  assign o_led_2 = (r_state == PATTERN_SHOW && r_pattern[r_index] == 2'b01) ? 1'b1 : i_switch_2;
  assign o_led_3 = (r_state == PATTERN_SHOW && r_pattern[r_index] == 2'b10) ? 1'b1 : i_switch_3;
  assign o_led_4 = (r_state == PATTERN_SHOW && r_pattern[r_index] == 2'b11) ? 1'b1 : i_switch_4;
  	
  // Enabling the counter when PATTERN_OFF or PATTERN_SHOW
  assign w_counter_enable = ((r_state == PATTERN_OFF) || (r_state == PATTERN_SHOW));
  
  // Fixing a pattern from LFSR when in START state
  lfsr lfsr_inst(
    .i_clk(i_clk),
    .o_enable(),  // don't connect
    .o_lfsr(w_lfsr_data)
  );
  
  
 always @(posedge i_clk)
   begin
     if (r_state == START)
       begin
         // TODO replace with a for loop
         r_pattern[0] <= w_lfsr_data[1:0];
         r_pattern[1] <= w_lfsr_data[3:2];
         r_pattern[2] <= w_lfsr_data[5:4];
         r_pattern[3] <= w_lfsr_data[7:6];
         r_pattern[4] <= w_lfsr_data[9:8];
         r_pattern[5] <= w_lfsr_data[11:10];
         r_pattern[6] <= w_lfsr_data[13:12];
         r_pattern[7] <= w_lfsr_data[15:14];
         r_pattern[8] <= w_lfsr_data[17:16];
         r_pattern[9] <= w_lfsr_data[19:18];
         r_pattern[10] <= w_lfsr_data[21:20];
       end
   end
  
//    // Using a precified sequence
//    always @(posedge i_clk)
//      begin
//        if (r_state == START)
//          begin
//            // TODO replace with a for loop
//            r_pattern[0] <= 2'b00;
//            r_pattern[1] <= 2'b11;
//            r_pattern[2] <= 2'b00;
//            r_pattern[3] <= 2'b10;
//            r_pattern[4] <= 2'b10;
//            r_pattern[5] <= 2'b01;
//            r_pattern[6] <= 2'b00;
//            r_pattern[7] <= 2'b10;
//            r_pattern[8] <= 2'b11;
//            r_pattern[9] <= 2'b01;
//            r_pattern[10] <= 2'b10;
//          end
//      end
  
  // To output the score
  assign o_score = r_score;
  
endmodule

  
//   count_and_toggle #(.COUNT_LIMIT(CLKS_PER_SEC/4)) count_and_toggle_inst (
//     .i_clk(i_clk),
//     .i_enable(w_counter_enable),
//     .o_toggle(w_toggle)
//   );

// // Module to delay LED blinking so it is visible
// module count_and_toggle #(parameter COUNT_LIMIT = 10) (
//   input i_clk,
//   input i_enable,
//   output o_toggle
// );
  
//   reg r_toggle;
//   reg [$clog2(COUNT_LIMIT-1):0] r_counter;
  
  
//   always @(posedge i_clk)
//     begin
//       if (i_enable == 1'b1)
//         begin
//           if (r_counter == COUNT_LIMIT-1)
//             begin
//               r_toggle <= !r_toggle;
//               r_counter <= 0;
//             end
//           else
//             begin
//               $display($clog2(COUNT_LIMIT)-1, COUNT_LIMIT);
//               r_counter <= r_counter + 1;
//             end
//         end
//       else
//         begin
//           r_toggle <= 1'b0;
//         end
//     end
  
//   assign o_toggle = r_toggle;
  
// endmodule

module Count_And_Toggle #(parameter COUNT_LIMIT = 10)
 (input i_Clk,
  input i_Enable,
  output reg o_Toggle);
    
  // Create the signal to do the actual counting
  // Subtract 1, since counter starts at 0
  reg [$clog2(COUNT_LIMIT-1):0] r_Counter;

  // This always block toggles the output at desired frequency   
  always @(posedge i_Clk) 
  begin
    if (i_Enable == 1'b1)
    begin
      if (r_Counter == COUNT_LIMIT - 1)
      begin
        o_Toggle  <= !o_Toggle;
        r_Counter <= 0;
      end
      else
        r_Counter <= r_Counter + 1;
    end
    else
    begin
      o_Toggle  <= 1'b0;
      r_Counter <= 0;
    end
  end

endmodule

// Module to convert decimal score to a 7-segment display:
//   --A-- 
//  |     |
//  F     B
//  |     |
//   --G-- 
//  |     |
//  E     C
//  |     |
//   --D-- 
// In principle, I don't need to use a clock and can simply
// hard-wire everything. But probably better to keep everything 
// synchronized
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
    
  assign o_seg_A = r_hex_encoding[6];
  assign o_seg_B = r_hex_encoding[5];
  assign o_seg_C = r_hex_encoding[4];
  assign o_seg_D = r_hex_encoding[3];
  assign o_seg_E = r_hex_encoding[2];
  assign o_seg_F = r_hex_encoding[1];
  assign o_seg_G = r_hex_encoding[0];
  
endmodule

// Module for generating patterns for LED blinking based
// on LFSR states. Need to assign 2*11=22 states
module lfsr(
  input i_clk,
  output o_enable,
  output [21:0] o_lfsr
);
  
  reg [21:0] r_lfsr = 22'd0;
  wire w_XNOR;
  
  always @(posedge i_clk)
    begin
      r_lfsr[21:1] <= r_lfsr[20:0];
      r_lfsr[0] <= w_XNOR;
    end
  
  assign w_XNOR = (r_lfsr[21] ^~ r_lfsr[20]);
  assign o_enable = (r_lfsr == 22'd0); // won't be used here
  assign o_lfsr = r_lfsr;
  
endmodule

module debounce_filter #(parameter DEBOUNCE_LIMIT = 20) (
  input i_clk,
  input i_switch,
  output o_switch_debounced
);
  
  reg [($clog2(DEBOUNCE_LIMIT)-1):0] r_count = 0;
  reg r_state = 0;
  
  always @(posedge i_clk) 
    begin
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