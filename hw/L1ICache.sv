module L1ICache #(
    parameter int OFFSET_BITS = 4,
    parameter int SET_BITS = 5,
    parameter int TAG_BITS = 32 - TAG_BITS - OFFSET_BITS,
    parameter int WAYS = 2
) (
    input logic clk,
    input logic rst,
    input Uop::val_t addr,
    output Uop::val_t data,
    output logic valid,
    output Cache::line_t tag,
    input Cache::l1i_tag_t line
);

  typedef logic [2**OFFSET_BITS * 8 - 1:0] line_t;
  typedef logic [TAG_BITS-1:0] tag_t;
  typedef logic [SET_BITS-1:0] set_t;
  typedef logic [OFFSET_BITS-1:0] offset_t;
  typedef struct packed {
    logic valid;
    tag_t tag;
    line_t;
  } entry_t;

  offset_t offset = addr[OFFSET_BITS-1:0];
  tag_t tag = addr[OFFSET_BITS+SET_BITS-1:SET_BITS];
  set_t set = addr[OFFSET_BITS+SET_BITS+TAG_BITS-1:OFFSET_BITS+SET_BITS];
  entry_t mem[WAYS][2**SET_BITS];

  logic hit;
  entry_t entry;

  assign valid = hit;

  always_ff @(posedge clk) begin
    if (rst) begin
      mem <= '{default: 0};
    end else begin
      hit <= 0;
      for (int i = 0; i < WAYS; i++) begin
        entry_t tmpEntry = mem[i][set];
        if (tmpEntry.valid && tmpEntry == tag) begin
          hit   <= 1;
          entry <= tmpEntry;
        end
      end
    end
  end

endmodule
