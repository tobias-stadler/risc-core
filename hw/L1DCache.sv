module L1DCache #(
    parameter int SET_BITS = 5,
    parameter int WAYS = 2,
    parameter int LFB_SZ = 8
) (
    input logic clk,
    input logic rst,
    l1dcache_core_if.Server core
);

  localparam int OFFSET_BITS = 2;
  localparam int ADDR_BITS = 30;
  localparam int TAG_BITS = ADDR_BITS - SET_BITS - OFFSET_BITS;
  localparam int SETS = 2 ** SET_BITS;

  localparam int LFB_PTR_BITS = $clog2(LFB_SZ);
  localparam int WAY_PTR_BITS = $clog2(WAYS);

  typedef logic [TAG_BITS-1:0] tag_t;
  typedef logic [SET_BITS-1:0] set_t;
  typedef logic [OFFSET_BITS-1:0] offset_t;

  typedef logic [WAY_PTR_BITS-1:0] way_ptr_t;
  typedef logic [LFB_PTR_BITS-1:0] lfb_ptr_t;

  typedef struct packed {
    logic [WAYS-1:0] valid;
    tag_t [WAYS-1:0] tag;
    //way_ptr_t replaceNext;
  } meta_entry_t;

  typedef struct packed {
    logic valid;
    tag_t addrTag;
    set_t addrSet;
  } lfb_entry_t;

  typedef Mem::w_t [3:0] line_t;

  offset_t coreOffset;
  assign coreOffset = core.addr[0+:OFFSET_BITS];
  set_t coreSet;
  assign coreSet = core.addr[OFFSET_BITS+:SET_BITS];
  tag_t coreTag;
  assign coreTag = core.addr[OFFSET_BITS+SET_BITS+:TAG_BITS];

  meta_entry_t meta[SETS];
  line_t mem[WAYS][SETS];

  logic enHold;
  logic enWHold;
  tag_t tagHold;
  set_t setHold;
  offset_t offsetHold;

  set_t storeSet;
  offset_t storeOffset;
  logic [3:0] storeMask;
  Mem::w_t storeData;
  logic [WAYS-1:0] storeWayHits;

  meta_entry_t entry;
  line_t line[WAYS];

  logic hit;
  logic [WAYS-1:0] wayHits;

  lfb_entry_t lfb[LFB_SZ];
  //line_t lfbLines[LFB_SZ];
  logic [LFB_SZ-1:0] lfbHits;
  logic lfbHit;
  logic lfbFreeHit;
  lfb_ptr_t lfbFree;

  assign core.nAck = !hit;

  //TODO don't clear STQ entry on load cycle
  //TODO maybe make use of the second port of the block ram. Needs extra bypassing and
  //READ_FIRST/WRITE_FRIST though
  // Store, Load, Store hazard?

  always_ff @(posedge clk) begin
    if (rst) begin
      for (int w = 0; w < WAYS; w++) begin
        mem[w] <= '{default: '0};
      end
      meta <= '{default: '0};
      enHold <= 0;
      enWHold <= 0;
      storeWayHits <= 0;
    end else begin
      enHold  <= core.en;
      enWHold <= core.enW;

      if (core.en) begin
        tagHold <= coreTag;
        setHold <= coreSet;
        offsetHold <= coreOffset;
      end

      if (core.en && core.enW) begin  //Store
        entry <= meta[coreSet];

        storeSet <= coreSet;
        storeOffset <= coreOffset;
        storeMask <= core.mask;
        storeData <= core.reqData;
      end else if (core.en && !core.enW) begin  //Load
        entry <= meta[coreSet];

        for (int w = 0; w < WAYS; w++) begin
          line[w] <= mem[w][coreSet];
        end

        if (enHold && enWHold) begin
          storeWayHits <= wayHits;
        end
      end else if (!core.en || (core.en && core.enW)) begin  // Idle or Store
        logic [WAYS-1:0] wHs = enHold && enWHold && hit ? wayHits : storeWayHits;
        logic h = (enHold && enWHold && hit) || |storeWayHits;
        storeWayHits <= 0;
        if (h) begin
          for (int w = 0; w < WAYS; w++) begin
            if (wHs[w]) begin
              for (int i = 0; i < 4; i++) begin
                if (storeMask[i]) mem[w][storeSet][storeOffset][i*8+:8] <= storeData[i*8+:8];
              end
            end
          end
        end
      end


    end
  end


  // After meta data lookup
  always_comb begin
    for (int w = 0; w < WAYS; w++) begin
      wayHits[w] = entry.valid[w] && entry.tag[w] == tagHold;
    end
    hit = |wayHits;
    core.respData = 'x;
    for (int w = 0; w < WAYS; w++) begin
      if (wayHits[w]) begin
        core.respData = line[w][offsetHold];
      end
    end
  end

  //LFB: search free entry
  always_comb begin
    lfbFreeHit = 0;
    lfbFree = 0;
    for (int i = LFB_SZ - 1; i >= 0; i--) begin
      if (lfb[i].valid) begin
        lfbFreeHit = 1;
        lfbFree = i[LFB_PTR_BITS-1:0];
      end
    end
  end

  //LFB: Addr CAM
  always_comb begin
    for (int i = 0; i < LFB_SZ; i++) begin
      lfbHits[i] = 0;
      if (lfb[i].addrTag == coreTag && lfb[i].addrSet == coreSet) begin
        lfbHits[i] = 1;
      end
    end
  end

  always_ff @(posedge clk) begin
    lfbHit <= |lfbHits;
  end

  //LFB: reserve new entry on miss that is not already in LFB
  always_ff @(posedge clk) begin
    if (rst) begin
      lfb <= '{default: '0};
    end else begin
      if (enHold) begin
        if (!hit && !lfbHit && lfbFreeHit) begin
          lfb[lfbFree] <= '{valid: 1, addrTag: tagHold, addrSet: setHold};
        end
      end
    end
  end

endmodule
