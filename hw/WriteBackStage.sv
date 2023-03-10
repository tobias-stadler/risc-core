module WriteBackStage (
    input logic clk,
    input logic rst,
    pipeline_if.Upstream u,
    input Uop::memory_t uopIn,
    regfile_write_if.Client write0
);

  import Uop::*;

  assign u.stall = 0;

  always_ff @(posedge clk) begin
    if (rst) begin
      write0.en <= 0;
    end else begin
      write0.en <= 0;
      if (uopIn.ex == EX_NONE && u.valid) begin
        write0.en   <= 1;
        write0.addr <= uopIn.rd;
        write0.val  <= uopIn.rdVal;
      end
    end
  end
endmodule
