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
  stq_ptr_t stqR;
  stq_ptr_t stqRnext;
  stq_ptr_t stqW;
  logic stqFull;

  logic stFail;
  logic stHold;
  logic stFired;
  logic stClear;

  logic forwardPresent;
  logic forwardLegal;
  Mem::w_t forwardData;
  logic [STQ_SZ-1:0] possibleForwards;
  logic [2*STQ_SZ-1:0] forwardPriority;

  //Before registers
  always_comb begin
    stq_ptr_t p = stFired && !cache.nAck || stClear ? stqRnext : stqR;

    cache.mask = core.mask;
    cache.addr = core.addr;
    cache.reqData = core.reqData;
    cache.en = 0;
    cache.enW = 0;
    if (core.en && !core.enW) begin
      cache.en = 1;
    end else if (!core.en) begin
      cache.enW = 1;
      cache.en = cam[p].valid;
      cache.addr = cam[p].addr;
      cache.mask = stq[p].mask;
      cache.reqData = stq[p].data;
    end

    for (int i = 0; i < STQ_SZ; i++) begin
      cam_entry_t e = cam[i];
      possibleForwards[i] = e.valid && e.addr == core.addr;
      forwardPriority[i] = possibleForwards[i];
      forwardPriority[i+STQ_SZ] = possibleForwards[i] & i < stqW;  //TODO buggy when buffer full?
    end
  end

  //After registers
  always_comb begin
    if (stHold) begin
      core.nAck = stFail;
    end else begin
      core.nAck = forwardPresent ? !forwardLegal : cache.nAck;
    end
    if (forwardPresent) begin
      core.respData = forwardData;
    end else begin
      core.respData = cache.respData;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      stq <= '{default: 0};
      cam <= '{default: 0};
      stqFull <= 0;
      stqR <= 0;
      stqRnext <= 1;
      stqW <= 0;
      stFail <= 0;
      stHold <= 0;
      stFired <= 0;
      stClear <= 0;
    end else begin
      stHold  <= 0;
      stFired <= 0;
      stClear <= 0;
      if (core.en && core.enW) begin  //Store
        stHold <= 1;
        stFail <= 0;
        if (stqFull) begin
          stFail <= 1;
        end else begin
          stq_ptr_t stqWnext = {1'b0, stqW} + 1 == STQ_SZ[STQ_SZ_EXP:0] ? 0 : stqW + 1;
          cam[stqW] <= '{valid: 1, addr: core.addr};
          stq[stqW] <= '{mask: core.mask, data: core.reqData};
          stqW <= stqWnext;
          if (stqWnext == stqR) begin
            stqFull <= 1;
          end
        end
      end else if (core.en && !core.enW) begin  //Load
        stClear <= stFired && !cache.nAck;
        forwardPresent <= 0;
        for (int i = 0; i < STQ_SZ * 2; i++) begin
          if (forwardPriority[i]) begin
            stq_entry_t e = stq[i%STQ_SZ];
            forwardData <= e.data;
            forwardPresent <= 1;
            forwardLegal <= (e.mask | core.mask) == e.mask;
          end
        end
      end else begin
        stFired <= cache.en && cache.enW;
      end


      //TODO only clear stq entry when cacheline isn't being evicted

      // On non-load cycle the cache accesses the data RAM.
      // Only then can the STQ entry be cleared otherwise store-forwarding
      // would stop before the data reaches the cache line.
      if ((stFired && !cache.nAck || stClear) && (!core.en || core.enW)) begin
        stq_ptr_t stqRnext2 = {1'b0, stqRnext} + 1 == STQ_SZ[STQ_SZ_EXP:0] ? 0 : stqRnext + 1;
        stqRnext <= stqRnext2;
        stqR <= stqRnext;
        stqFull <= 0;
        cam[stqR].valid <= 0;
      end
    end
  end

endmodule
