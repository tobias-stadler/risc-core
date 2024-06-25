module IFetchStage (
    input logic clk,
    input logic rst,
    pipeline_if.Downstream d,
    output Uop::fetch_t uopOut,
    l1icache_core_if.Client cache,
    input Uop::redirect_pc_t redirect
);

  Uop::iaddr_t pc_q;
  Uop::iaddr_t pc_q2;
  Mem::lineaddr_t pc_line;
  logic [1:0] pc_word_2;

  // Before Cache pipeline stage
  always_comb begin
    pc_line = pc_q[29:2];
    cache.req_valid = !rst && !d.stall && !redirect.valid;
    cache.req_addr = pc_line;
  end

  // After Cache pipeline stage
  always_comb begin
    pc_word_2 = pc_q2[1:0];
    d.valid = cache.resp_valid;
    uopOut.enc = cache.resp_data[pc_word_2 * 32 +: 32];
    uopOut.pc = pc_q2;
  end

  // Fetch pipeline stage is in-sync with Cache pipeline stage
  always_ff @(posedge clk) begin
    if (rst) begin
      pc_q <= '0;
      pc_q2 <= 'x;
    end begin
      if(redirect.valid) begin
        pc_q <= redirect.pc;
        pc_q2 <= 'x;
      end else if(cache.req_valid && cache.req_ready) begin
        pc_q <= pc_q + 1;
        pc_q2 <= pc_q;
      end
    end
  end

endmodule
