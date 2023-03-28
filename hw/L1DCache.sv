module L1DCache #(
    parameter int SET_BITS = 3,
    parameter int WAYS = 2,
    parameter int LFB_SZ = 8
) (
    input logic clk,
    input logic rst,
    l1dcache_core_if.Server core,
    l1cache_mem_if.Client bus
);

  import Mem::*;

  localparam int ADDR_BITS = 30;
  localparam int OFFSET_BITS = 2;
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
    logic fired;
    tag_t addrTag;
    set_t addrSet;
  } lfb_entry_t;

  offset_t offset;
  set_t cacheset;
  tag_t tag;

  logic valid_q;
  logic we_q;

  tag_t tag_q;
  set_t cacheset_q;
  offset_t offset_q;

  set_t store_cacheset_q;
  offset_t store_offset_q;
  logic [3:0] store_mask_q;
  Mem::w_t store_data_q;
  logic [WAYS-1:0] store_wayhits_q2;

  logic hit_1;
  logic [WAYS-1:0] wayhits_1;

  lfb_entry_t lfb[LFB_SZ];
  logic [LFB_SZ-1:0] lfb_hits_1;
  logic lfb_unfired_valid;
  lfb_ptr_t lfb_unfired;
  logic lfb_free_valid;
  lfb_ptr_t lfb_free;

  meta_entry_t meta[SETS];
  logic meta_en;
  logic meta_we;
  set_t meta_addr;
  meta_entry_t meta_din;
  meta_entry_t meta_dout_q;

  line_t mem[WAYS][SETS];
  logic mem_en[WAYS];
  logic mem_we[WAYS];
  set_t mem_addr[WAYS];
  linemask_t mem_mask[WAYS];
  line_t mem_din[WAYS];
  line_t mem_dout_q[WAYS];

  //TODO Store, Load, Store hazard?
  //TODO gate off memory when rst

  // Initialize RAM using global reset
  // because Xilinx BlockRAM does not support manual reset
  initial begin
    for (int w = 0; w < WAYS; w++) begin
      mem[w] = '{default: '0};
    end
    meta = '{default: '0};
  end


  // Infer a single port RAM with write byte-enable for every cache WAY
  // Uses READ_FIRST behaviour to simplify cacheline replacement
  // TODO check if BlockRAM is inferred
  // TODO make use of second Xilinx BlockRAM port
  generate
    for (genvar w = 0; w < WAYS; w++) begin : g_mem_port1
      always_ff @(posedge clk) begin
        if (mem_en[w]) begin
          if (mem_we[w]) begin
            for (int i = 0; i < 16; i++) begin
              if (mem_mask[w][i]) begin
                mem[w][mem_addr[w]][i*8+:8] <= mem_din[w][i*8+:8];
              end
            end
          end
          mem_dout_q[w] <= mem[w][mem_addr[w]];
        end
      end
    end
  endgenerate

  // Infer single port RAM for meta data array
  always_ff @(posedge clk) begin
    if (meta_en) begin
      if (meta_we) begin
        meta[meta_addr] <= meta_din;
      end
      meta_dout_q <= meta[meta_addr];
    end
  end

  //Before Cycle 1
  always_comb begin
    offset = core.req_addr[0+:OFFSET_BITS];
    cacheset = core.req_addr[OFFSET_BITS+:SET_BITS];
    tag = core.req_addr[OFFSET_BITS+SET_BITS+:TAG_BITS];
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      valid_q <= 0;
      we_q <= 0;
      store_wayhits_q2 <= 0;
    end else begin
      valid_q <= core.req_valid;
      we_q <= core.req_we;

      if (core.req_valid) begin
        tag_q <= tag;
        cacheset_q <= cacheset;
        offset_q <= offset;
      end

      if (core.req_valid && core.req_we) begin  //Store
        store_cacheset_q <= cacheset;
        store_offset_q <= offset;
        store_mask_q <= core.req_mask;
        store_data_q <= core.req_data;
      end

      if (core.req_valid && !core.req_we) begin  //Load
        if (valid_q && we_q) begin  // Store (after meta lookup) is interrupted by Load
          store_wayhits_q2 <= wayhits_1;
        end
      end

      if (!core.req_valid || (core.req_valid && core.req_we)) begin  // Idle or Store
        store_wayhits_q2 <= 0;
      end

    end
  end

  //Meta RAM access
  always_comb begin
    meta_en   = core.req_valid;
    meta_we   = 0;
    meta_addr = cacheset;
    meta_din  = 0;
  end

  //Data RAM access
  always_comb begin
    logic [WAYS-1:0] wHs = valid_q && we_q ? wayhits_1 : store_wayhits_q2;

    for (int w = 0; w < WAYS; w++) begin
      mem_en[w]   = 0;
      mem_we[w]   = 0;
      mem_addr[w] = 0;
      mem_mask[w] = 0;
      mem_din[w]  = 0;
    end
    if (core.req_valid && !core.req_we) begin  //Load
      for (int w = 0; w < WAYS; w++) begin
        mem_en[w]   = 1;
        mem_addr[w] = cacheset;
      end
    end else if (!core.req_valid || (core.req_valid && core.req_we)) begin  //Idle or Store
      for (int w = 0; w < WAYS; w++) begin
        mem_en[w] = wHs[w];
        mem_we[w] = 1;
        mem_addr[w] = store_cacheset_q;
        mem_mask[w][store_offset_q*4+:4] = store_mask_q;
        mem_din[w][store_offset_q*4+:32] = store_data_q;
      end
    end
  end

  // After cycle 1 (meta data lookup)
  always_comb begin
    for (int w = 0; w < WAYS; w++) begin
      wayhits_1[w] = meta_dout_q.valid[w] && meta_dout_q.tag[w] == tag_q;
    end
    hit_1 = |wayhits_1;

    core.resp_ack = hit_1;
    core.resp_data = 0;
    for (int w = 0; w < WAYS; w++) begin
      if (wayhits_1[w]) begin
        core.resp_data = mem_dout_q[w][offset_q*4+:32];
      end
    end
  end

  //LFB: search free entry
  always_comb begin
    lfb_free_valid = 0;
    lfb_free = 0;
    for (int i = LFB_SZ - 1; i >= 0; i--) begin
      if (!lfb[i].valid) begin
        lfb_free_valid = 1;
        lfb_free = i[LFB_PTR_BITS-1:0];
      end
    end
  end

  //LFB: search unfired miss
  always_comb begin
    lfb_unfired_valid = 0;
    lfb_unfired = 0;
    for (int i = LFB_SZ - 1; i >= 0; i--) begin
      if (!lfb[i].valid) begin
        lfb_unfired_valid = 1;
        lfb_unfired = i[LFB_PTR_BITS-1:0];
      end
    end
  end

  //LFB: Addr CAM
  always_comb begin
    for (int i = 0; i < LFB_SZ; i++) begin
      lfb_hits_1[i] = 0;
      if (lfb[i].valid && lfb[i].addrTag == tag_q && lfb[i].addrSet == cacheset_q) begin
        lfb_hits_1[i] = 1;
      end
    end
  end

  //TODO remove
  wire _unused_ok = &{1'b0, lfb_unfired_valid, lfb_unfired, bus.resp_ack, bus.resp_data, bus.req_ready};

  //LFB: reserve new entry on miss that is not already in LFB
  always_ff @(posedge clk) begin
    if (rst) begin
      lfb <= '{default: '0};
    end else begin
      if (valid_q) begin
        if (!hit_1 && !(|lfb_hits_1) && lfb_free_valid) begin
          lfb[lfb_free] <= '{valid: 1, fired: 0, addrTag: tag_q, addrSet: cacheset_q};
        end
      end
    end
  end

  //LFB: fire read request to memory
  always_ff @(posedge clk) begin
    bus.req_valid <= 0;
    bus.req_we <= 0;
    bus.req_data <= 0;
    bus.req_addr <= 0;
  end



endmodule
