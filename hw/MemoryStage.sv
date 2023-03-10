module MemoryStage #(
    parameter int OFFSET_BITS = 4,
    parameter int SET_BITS = 5,
    parameter int TAG_BITS = 32 - SET_BITS - OFFSET_BITS
) (
    input logic clk,
    input logic rst,
    pipeline_if.Upstream u,
    pipeline_if.Downstream d,
    input Uop::execute_t uopIn,
    output Uop::memory_t uopOut
);

  typedef logic [2**OFFSET_BITS * 8 - 1:0] line_t;
  typedef logic [TAG_BITS-1:0] tag_t;
  typedef logic [SET_BITS-1:0] set_t;
  typedef logic [OFFSET_BITS-1:0] offset_t;

  typedef struct packed {
    logic valid;
    tag_t tag;
    line_t data;
  } entry_t;

  /*offset_t offset;
  assign offset = uop[OFFSET_BITS-1:0];
  tag_t tag;
  assign tag = mem[OFFSET_BITS+SET_BITS-1:SET_BITS];
  set_t set;
  assign set = mem[OFFSET_BITS+SET_BITS+TAG_BITS-1:OFFSET_BITS+SET_BITS];

      mem <= '{default:0};
  entry_t mem[2**SET_BITS];*/

  always_ff @(posedge clk) begin
    if (rst) begin
      u.stall <= 0;
      d.valid <= 0;
      uopOut  <= 0;
    end else begin
      d.valid <= u.valid;
      uopOut.ex <= uopIn.ex;
      uopOut.rd <= uopIn.rd;
      uopOut.rdVal <= uopIn.rdVal;
    end
  end

endmodule
