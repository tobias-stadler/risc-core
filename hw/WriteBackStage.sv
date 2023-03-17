module WriteBackStage (
    input logic clk,
    input logic rst,
    pipeline_if.Upstream u,
    input Uop::memory_t uopIn,
    regfile_write_if.Client write0,
    bypass_if.Subject bypass
);

  import Uop::*;

  logic   valid;
  reg_t   rd;
  val_t   rdVal;
  flags_t flags;

  assign bypass.rValid = valid;
  assign bypass.r = rd;
  assign bypass.rVal = rdVal;
  assign bypass.flags = flags;
  assign bypass.flagsValid = '1;

  assign u.stall = 0;
  assign write0.en = u.valid && uopIn.ex == EX_NONE;
  assign write0.addr = uopIn.rd;
  assign write0.val = uopIn.rdVal;

  always_ff @(posedge clk) begin
    if (rst) begin
      flags <= '0;
      valid <= '0;
    end else begin
      valid <= u.valid;
      rd <= uopIn.rd;
      rdVal <= uopIn.rdVal;
      if (uopIn.flagsValid) begin
        flags <= uopIn.flags;
      end
    end
  end
endmodule
