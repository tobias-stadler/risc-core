module StoreQueue #(
    parameter int STQ_SZ_EXP = 3
) (
    l1dcache_core_if.Server core,
    l1dcache_core_if.Client cache
);

  localparam int STQ_SZ = 2 ** STQ_SZ_EXP;

  typedef logic [STQ_SZ_EXP - 1:0] stq_ptr_t;

  typedef struct packed {
    logic success;
    logic fired;
    logic commited;
    Uop::waddr_t addr;
    logic [3:0] mask;
    Uop::w_t data;
    logic valid;
  } stq_entry_t;


  stq_entry_t stq[STQ_SZ];
  stq_ptr_t stqR;
  stq_ptr_t stqW;
  logic stqFull;

  logic stFail;

  logic forwardPresent;
  logic forwardLegal;
  Uop::w_t forwardData;
  logic [2*STQ_SZ-1:0] forwardPriority;

  //Before registers
  always_comb begin
    core.

    logic [STQ_SZ-1:0] possibleForwards;
    for (int i = 0; i < STQ_SZ; i++) begin
      stq_entry_t e = stq[i];
      logic _unused_e = &{1'b0, e};  // TODO remove, split CAM and STQ
      possibleForwards[i]  = e.valid && e.addrTag == coreTag && e.addrSet == coreSet && e.addrOffset == coreOffset;
      forwardPriority[i] = possibleForwards[i];
      forwardPriority[i*2] = possibleForwards[i] & i < stqW;  //TODO buggy when buffer full?
    end
  end

  //After registers
  always_comb begin
    logic lineValid = entry.valid && entry.tag == tagHold;
    if (isStHold) begin
      core.nack = stFail;
    end else begin
      core.nack = !(forwardPresent ? forwardLegal : lineValid);
    end
    if (forwardPresent) begin
      core.respData = forwardData;
    end else if (lineValid) begin
      core.respData = line[offsetHold];
    end else begin
      core.respData = '0;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      stq <= '{default: '0};
      mem <= '{default: '0};
      stqFull <= '0;
      stqR <= '0;
      stqW <= '0;
    end else begin
      if (core.en) begin
        if (core.enW) begin
          stFail <= 0;
          if (stqFull) begin
            stFail <= 1;
          end else begin
            stq_ptr_t stqWnext = {1'b0, stqW} + 1 == STQ_SZ[STQ_SZ_EXP:0] ? '0 : stqW + 1;
            stq[stqW] <= '{
                valid: '1,
                data: core.reqData,
                mask: core.mask,
                addrTag: coreTag,
                addrSet: coreSet,
                addrOffset: coreOffset,
                commited: '0,
                fired: '0,
                success: '0
            };
            stqW <= stqWnext;
            if (stqWnext == stqR) begin
              stqFull <= '1;
            end
          end
        end else begin
          entry <= meta[coreSet];
          line <= mem[coreSet];

          forwardPresent <= '0;
          for (int i = 0; i < STQ_SZ * 2; i++) begin
            if (forwardPriority[i]) begin
              stq_entry_t e = stq[i%STQ_SZ];
              logic _unused_e = &{1'b0, e};  // TODO remove, split CAM and STQ
              forwardData <= e.data;
              forwardPresent <= '1;
              forwardLegal <= (e.mask | core.mask) == e.mask;
            end
          end
        end
      end
    end
  end

endmodule
