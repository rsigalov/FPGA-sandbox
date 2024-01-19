// Code your design here
module demux_lfsr(
  input i_clk,
  input i_switch_1,
  input i_switch_2,
  output o_led_1,
  output o_led_2,
  output o_led_3,
  output o_led_4
);
  
  reg r_lfsr_toggle = 1'b0;
  wire lfsr_enable;
  
  lfsr lfsr_inst(
    .i_clk(i_clk),
    .o_enable(lfsr_enable)
  );
  
  always @(posedge i_clk)
    begin
      if (lfsr_enable)
        begin
      	  r_lfsr_toggle <= ~r_lfsr_toggle;
        end
    end
  
  demux demux_inst(
    .i_clk(i_clk),
    .i_data(r_lfsr_toggle),
    .i_switch_1(i_switch_1),
    .i_switch_2(i_switch_2),
    .o_led_1(o_led_1),
    .o_led_2(o_led_2),
    .o_led_3(o_led_3),
    .o_led_4(o_led_4)
  );
  
endmodule


module demux(
  input i_clk,
  input i_data,
  input i_switch_1,
  input i_switch_2,
  output o_led_1,
  output o_led_2,
  output o_led_3,
  output o_led_4
);
  
  assign o_led_1 = !i_switch_1 & !i_switch_2 ? i_data : 1'b0;
  assign o_led_2 = i_switch_1 & !i_switch_2 ? i_data : 1'b0;
  assign o_led_3 = !i_switch_1 & i_switch_2 ? i_data : 1'b0;
  assign o_led_4 = i_switch_1 & i_switch_2 ? i_data : 1'b0;
  
endmodule

module lfsr(
  input i_clk,
  output o_enable
);
  
  reg [21:0] r_lfsr = 22'd0;
  wire w_XNOR;
  
  always @(posedge i_clk)
    begin
      r_lfsr[21:1] <= r_lfsr[20:0];
      r_lfsr[0] <= w_XNOR;
    end
  
  assign w_XNOR = (r_lfsr[21] ^~ r_lfsr[20]);
  assign o_enable = (r_lfsr == 22'd0);
  
endmodule