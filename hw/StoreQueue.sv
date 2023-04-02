module StoreQueue #(
    parameter int STQ_SZ_EXP = 3
) (
    input logic clk,
    input logic rst,
    l1dcache_core_if.Server core,
    l1dcache_core_if.Client cache
);

  localparam int STQ_SZ = 2 ** STQ_SZ_EXP;

  typedef logic [STQ_SZ_EXP - 1:0] stq_ptr_t;

  typedef struct packed {
    logic valid;
    Mem::waddr_t addr;
  } cam_entry_t;

  typedef struct packed {
    logic [3:0] mask;
    Mem::w_t data;
  } stq_entry_t;

  cam_entry_t cam[STQ_SZ];
  stq_entry_t stq[STQ_SZ];
  stq_ptr_t stq_r_q;
  stq_ptr_t stq_r_next_q;
  stq_ptr_t stq_r_next2;
  stq_ptr_t stq_w_q;
  stq_ptr_t stq_w_next;
  logic stq_full_q;
  logic stq_fail_q;

  logic req_load;
  logic req_store;
  logic req_load_q;
  logic req_store_q;

  logic forward_hit_q;
  logic forward_legal_q;
  Mem::w_t forward_data_q;
  logic forward_hit;
  stq_ptr_t forward_ptr;
  logic forward_legal;
  Mem::w_t forward_data;
  logic [STQ_SZ-1:0] forward_hits;
  logic [2*STQ_SZ-1:0] forward_hits_prio;

  stq_ptr_t store_next;
  logic store_firing;
  logic store_firing_q;
  logic store_clear_q2;
  logic store_clear_valid;

  assign req_load = core.req_valid && !core.req_we;
  assign req_store = core.req_valid && core.req_we;

  //TODO fix overflow
  assign stq_w_next = stq_w_q + 1;
  assign stq_r_next2 = stq_r_next_q + 1;
  // {1'b0, stqW} + 1 == STQ_SZ[STQ_SZ_EXP:0] ? 0 : stqW + 1;
  // {1'b0, stqRnext} + 1 == STQ_SZ[STQ_SZ_EXP:0] ? 0 : stqRnext + 1;


  // Store forwarding CAM lookup
  always_comb begin
    for (int i = 0; i < STQ_SZ; i++) begin
      forward_hits[i] = cam[i].valid && cam[i].addr == core.req_addr;
      forward_hits_prio[i] = forward_hits[i];
      forward_hits_prio[i+STQ_SZ] = forward_hits[i] & i < stq_w_q;  //TODO when buffer full?
    end

    forward_hit = |forward_hits;
    forward_ptr = 0;

    //Priority encoder to search most recent forwardable store
    for (int i = 0; i < STQ_SZ * 2; i++) begin
      if (forward_hits_prio[i]) begin
        forward_ptr = i[STQ_SZ_EXP-1:0];
      end
    end

    forward_data  = stq[forward_ptr].data;
    forward_legal = (stq[forward_ptr].mask | core.req_mask) == stq[forward_ptr].mask;
  end

  // Cache access
  always_comb begin
    store_clear_valid = (store_firing_q && cache.resp_ack) || store_clear_q2;
    store_next = store_clear_valid ? stq_r_next_q : stq_r_q;

    cache.req_valid = 0;
    cache.req_we = 0;
    cache.req_mask = 0;
    cache.req_addr = 0;
    cache.req_data = 0;

    store_firing = 0;
    if (req_load) begin
      cache.req_valid = 1;
      cache.req_mask  = core.req_mask;
      cache.req_addr  = core.req_addr;
      cache.req_data  = core.req_data;
    end else begin
      store_firing = cam[store_next].valid;
      cache.req_we = 1;
      cache.req_valid = cam[store_next].valid;
      cache.req_addr = cam[store_next].addr;
      cache.req_mask = stq[store_next].mask;
      cache.req_data = stq[store_next].data;
    end

  end

  //After registers
  always_comb begin
    core.resp_ack  = 0;
    core.resp_data = 0;

    if (req_load_q) begin
      if (forward_hit_q) begin
        core.resp_ack  = forward_legal_q;
        core.resp_data = forward_data_q;
      end else begin
        core.resp_ack  = cache.resp_ack;
        core.resp_data = cache.resp_data;
      end
    end else if (req_store_q) begin
      core.resp_ack = !stq_fail_q;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      stq <= '{default: 0};
      cam <= '{default: 0};
      stq_full_q <= 0;
      stq_r_q <= 0;
      stq_r_next_q <= 1;
      stq_w_q <= 0;
      req_load_q <= 0;
      req_store_q <= 0;
      store_firing_q <= 0;
      store_clear_q2 <= 0;
    end else begin
      req_load_q <= req_load;
      req_store_q <= req_store;
      store_firing_q <= store_firing;
      store_clear_q2 <= store_firing_q && cache.resp_ack;
      forward_legal_q <= forward_legal;
      forward_data_q <= forward_data;
      forward_hit_q <= forward_hit;

      if (req_load) begin
      end else if (store_clear_valid) begin
        // On non-load cycle the cache accesses the data RAM for stores.
        // Only then can the STQ entry be cleared otherwise store-forwarding
        // would stop before the data reaches the cache line.

        store_clear_q2 <= 0;
        stq_r_next_q <= stq_r_next2;
        stq_r_q <= stq_r_next_q;
        stq_full_q <= 0;
        cam[stq_r_q].valid <= 0;
      end

      //TODO FIFO read and write simultaneously race condition
      // - w
      // B r
      // C
      // D

      if (req_store) begin
        stq_fail_q <= 0;
        if (stq_full_q) begin
          stq_fail_q <= 1;
        end else begin
          cam[stq_w_q] <= '{valid: 1, addr: core.req_addr};
          stq[stq_w_q] <= '{mask: core.req_mask, data: core.req_data};
          stq_w_q <= stq_w_next;
          if (stq_w_next == stq_r_q) begin
            stq_full_q <= 1;
          end
        end
      end
    end
  end

endmodule
