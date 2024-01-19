// Writing out an example multiplication to determine
// how many resources will it eat up in the absence
// of dedicated DSPs.

module mult_test(
  input i_clk,
  output o_led_1,
  output o_led_2,
  output o_led_3,
  output o_led_4
);

  reg [7:0] r_index;
  reg [7:0] r_arg1;
  reg [7:0] r_arg2;
  wire [15:0] w_result;

  mult mult_inst (
    .i_clk(i_clk),
    .i_arg1(r_arg1),
    .i_arg2(r_arg2),
    .o_result(w_result)
  );

  // Changing the value of a given bit at every clock cycle
  always @(posedge i_clk)
    begin
      if (r_index < 8'b11111111)
        begin
          r_index <= r_index + 1;
          r_arg1 <= r_arg1 + 1;
          r_arg2 <= r_arg1 + 1;
        end
      else
        begin
          r_index <= 0;
          r_arg1 <= 0;
          r_arg2 <= r_arg1 + 1;
        end
    end

  assign o_led_1 = w_result[0];
  assign o_led_2 = w_result[5];
  assign o_led_3 = w_result[10];
  assign o_led_4 = w_result[15];

endmodule

module mult(
    input i_clk,
    input [7:0] i_arg1,
    input [7:0] i_arg2,
    output [15:0] o_result
);

  reg [15:0] r_result;

  always @(posedge i_clk)
    begin
      r_result <= i_arg1 * i_arg2;
    end

  assign o_result = r_result;


endmodule