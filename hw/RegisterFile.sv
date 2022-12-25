module RegisterFile (
    input clk,
    input rst,
    input logic w0en,
    input uop_val_t w0addr,
    input uop_reg_t r0addr,
    input uop_reg_t r1addr,
    input uop_val_t w0val,
    output uop_reg_t r0val,
    output uop_reg_t r1val
);

  //TODO maybe move to blockram
  uop_val_t ram[32];

  always_ff @(posedge clk) begin
    if (w0en) ram[w0addr] <= w0val;
  end

  assign r0val = ram[r0addr];
  assign r1val = ram[r1addr];
endmodule
