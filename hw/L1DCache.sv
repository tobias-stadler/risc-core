module L1DCache #(
    parameter int OFFSET_BITS = 2,
    parameter int SET_BITS = 5,
    parameter int ADDR_BITS = 30,
    parameter int STQ_SZ_EXP = 3,
    parameter int LFB_SZ = 8
) (
    input logic clk,
    input logic rst,
    l1dcache_core_if.Server core
);


  localparam int STQ_SZ = 2 ** STQ_SZ_EXP;
  localparam int TAG_BITS = ADDR_BITS - SET_BITS - OFFSET_BITS;
  localparam int SETS = 2 ** SET_BITS;

  typedef logic [TAG_BITS-1:0] tag_t;
  typedef logic [SET_BITS-1:0] set_t;
  typedef logic [OFFSET_BITS-1:0] offset_t;

  offset_t coreOffset;
  assign coreOffset = core.addr[0+:OFFSET_BITS];
  set_t coreSet;
  assign coreSet = core.addr[OFFSET_BITS+:SET_BITS];
  tag_t coreTag;
  assign coreTag = core.addr[OFFSET_BITS+SET_BITS+:TAG_BITS];

  typedef struct packed {
    logic valid;
    tag_t tag;
  } meta_entry_t;

  typedef struct packed {
    logic success;
    logic fired;
    logic commited;
    offset_t addrOffset;
    set_t addrSet;
    tag_t addrTag;
    logic [3:0] mask;
    Uop::w_t data;
    logic valid;
  } stq_entry_t;

  typedef struct packed {
    logic valid;
    tag_t addrTag;
    set_t addrSet;
    logic fired;
  } lfb_entry_t;

  typedef logic [STQ_SZ_EXP - 1:0] stq_ptr_t;
  typedef Uop::w_t [3:0] line_t;

  meta_entry_t meta[SETS];
  line_t mem[SETS];

  stq_entry_t stq[STQ_SZ];
  stq_ptr_t stqR;
  stq_ptr_t stqW;
  logic stqFull;

  lfb_entry_t lfb[LFB_SZ];

  tag_t tagHold;
  offset_t offsetHold;
  logic isStHold;

  logic stFail;

  logic forwardPresent;
  logic forwardLegal;
  Uop::w_t forwardData;
  logic [2*STQ_SZ-1:0] forwardPriority;

  meta_entry_t entry;
  line_t line;

  always_comb begin
    logic lineValid = entry.valid && entry.tag == tagHold;
    if (isStHold) begin
      core.hit = ~stFail;
    end else begin
      core.hit = forwardPresent ? forwardLegal : lineValid;
    end
    if (forwardPresent) begin
      core.respData = forwardData;
    end else if (lineValid) begin
      core.respData = line[offsetHold];
    end else begin
      core.respData = '0;
    end
  end

  always_comb begin
    logic [STQ_SZ-1:0] possibleForwards;
    for (int i = 0; i < STQ_SZ; i++) begin
      stq_entry_t e = stq[i];
      logic _unused_e = &{1'b0,e};  // TODO remove, split CAM and STQ
      possibleForwards[i]  = e.valid && e.addrTag == coreTag && e.addrSet == coreSet && e.addrOffset == coreOffset;
      forwardPriority[i] = possibleForwards[i];
      forwardPriority[i*2] = possibleForwards[i] & i < stqW; //TODO buggy when buffer full?
    end
  end

  //TODO remove
  wire _unused_ok = &{1'b0, core.kill, lfb[0], 1'b0};
  always_ff @(posedge clk) begin
    if (rst) begin
      for (int i = 0; i < SETS; i++) begin
        meta[i].valid <= '0;
      end
      for (int i = 0; i < STQ_SZ; i++) begin
        stq[i].valid <= '0;
      end
      mem <= '{default: '0};
      stqFull <= '0;
      stqR <= '0;
      stqW <= '0;
      for (int i = 0; i < LFB_SZ; i++) begin
        lfb[i].valid <= '0;
      end
    end else begin
      if (core.en) begin
        tagHold <= coreTag;
        offsetHold <= coreOffset;
        isStHold <= core.enW;
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
