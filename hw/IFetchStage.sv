module IFetchStage (
    input logic clk,
    input logic rst,
    pipeline_if.Downstream d,
    output Uop::fetch_t uopOut,
    l1icache_core_if.Client cache
);

  Uop::iaddr_t pc_q;
  logic pc_line_changed_q;
  Mem::lineaddr_t pc_line;
  logic [1:0] pc_word;
  Uop::iaddr_t pc_q2;
  Uop::iaddr_t pc_q3;

  Uop::iaddr_t pc_next;
  Mem::lineaddr_t pc_next_line;

  logic line_valid_q;

  logic fetch_ready;
  logic advance_ready;

  always_comb begin
    pc_line = pc_q[29:2];
    pc_word = pc_q[1:0];
    pc_next_line = pc_next[29:2];
  end

  always_comb begin
    if (rst) begin
      pc_next = 0;
    end else begin
      pc_next = pc_q + 1;
    end
  end

  always_comb begin
    cache.req_valid = !rst && !d.stall && pc_line_changed_q;
    cache.req_addr  = pc_next_line;
  end

  assign d.valid = line_valid_q;

  always_ff @(posedge clk) begin
    if (rst) begin
      line_valid_q <= 0;
      pc_line_changed_q <= 1;
      uopOut <= 0;
    end else begin
      if (cache.req_ready && !d.stall) begin
        pc_q <= pc_next;
        pc_line_changed_q <= pc_line != pc_next_line;
        pc_q2 <= pc_q;
      end
      if (cache.resp_valid) begin
        line_valid_q <= 1;
      end
      uopOut.enc <= cache.resp_data[pc_q2[1:0]*32+:32];
    end
  end

endmodule
