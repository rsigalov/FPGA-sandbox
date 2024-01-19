// High level module for putting together receiver,
// transmitter and 7-segment display conversion.
// Once the data byte is received it is send back
// along the serial port

module uart_loopback(
  input i_clk,
  input i_uart_rx,
  output o_uart_tx,
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
  output o_seg_2G
);

  // Will hard connect receiver and transmitter
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
    .o_uart_data(w_uart_data)
  );

  UART_TX #(.CLKS_PER_BIT(217)) UART_TX_inst (
    .i_clk(i_clk),
    .i_uart_dv(w_uart_dv),
    .i_uart_data(w_uart_data),
    .o_uart_tx(o_uart_tx),
    .o_done(),   // leave unconnected
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

endmodule

// Use a State machine for the module
// IDLE
// START_BIT
// DATA_BIT
// END_BIT
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