
module debounce(
  input i_clk,
  input i_switch,
  output o_led);
  
  wire w_switch_debounced;
  
  debounce_filter #(.DEBOUNCE_LIMIT(250000)) debounce_filter_inst (
    .i_clk(i_clk),
    .i_switch(i_switch),
    .o_switch_debounced(w_switch_debounced)
  );
  
  led_toggle led_toggle_inst(
    .i_clk(i_clk),
    .i_switch(w_switch_debounced),
    .o_led(o_led)
  );
  
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

module led_toggle(
  input i_clk,
  input i_switch,
  output o_led
);
  
  reg r_led = 1'b0;
  reg r_switch = 1'b0;
  
  always @(posedge i_clk)
    begin
      r_switch <= i_switch;
      
      if (i_switch == 1'b0 && r_switch == 1'b1)
        begin
          r_led <= ~r_led;
        end
    end
  
  assign o_led = r_led;
  
endmodule
  
  