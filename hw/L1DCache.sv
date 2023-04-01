module L1DCache #(
    parameter int SET_BITS = 3,
    parameter int WAYS = 2,
    parameter int LFB_SZ = 4
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
    logic valid;
    tag_t tag;
  } meta_way_t;

  typedef struct packed {way_ptr_t evict_next;} meta_common_t;

  typedef struct packed {
    logic valid;
    logic fired;
    logic ack;
    lineaddr_t addr;
    way_ptr_t evict;
  } lfb_entry_t;

  offset_t offset;
  set_t cacheset;
  tag_t tag;
  logic req_load;
  logic req_store;
  //logic req_idle;
  logic req_load_q;
  logic req_store_q;
  //logic req_idle_q;

  tag_t tag_q;
  set_t cacheset_q;
  offset_t offset_q;

  set_t store_cacheset_q;
  offset_t store_offset_q;
  logic [3:0] store_mask_q;
  Mem::w_t store_data_q;
  logic [WAYS-1:0] store_wayhits_q2;
  logic [WAYS-1:0] store_wayhits;
  logic store_hit_2;
  logic store_hit_valid;

  logic hit_1;
  logic [WAYS-1:0] wayhits_1;

  lfb_entry_t lfb[LFB_SZ];
  logic [LFB_SZ-1:0] lfb_hits_1;
  logic lfb_unfired_valid;
  lfb_ptr_t lfb_unfired;
  logic lfb_free_valid;
  lfb_ptr_t lfb_free;

  meta_way_t meta[WAYS][SETS];
  logic meta_en[WAYS];
  logic meta_we[WAYS];
  set_t meta_addr[WAYS];
  meta_way_t meta_din[WAYS];
  meta_way_t meta_dout_q[WAYS];

  meta_common_t meta_common[SETS];
  logic meta_common_en;
  logic meta_common_we;
  set_t meta_common_addr;
  meta_common_t meta_common_din;
  meta_common_t meta_common_dout_q;

  logic mem_en[WAYS];
  set_t mem_addr[WAYS];
  linemask_t mem_mask[WAYS];
  line_t mem_din[WAYS];
  line_t mem_dout_1[WAYS];

  logic evict_valid_q;
  line_t evict_line_q;
  lfb_ptr_t evict_id_q;
  way_ptr_t evict_way_1;
  set_t evict_set_1;
  tag_t evict_tag_1;
  //logic evict_valid_q2;
  //line_t evict_line_q2;
  //lfb_ptr_t evict_id_q2;

  //TODO Store, Load, Store hazard?
  //TODO Proper reset of controller, gate off memory when rst

  // Single port RAM with write byte-enable for every cache WAY
  // Extracted into external module because Vivado fails to infer byte-enable on 3D RAM
  // TODO make use of second Xilinx BlockRAM port
  ByteWriteSpRfRam #(
      .COLS(16),
      .ADDR_BITS(SET_BITS)
  ) m_mem[WAYS] (
      .clk(clk),
      .en(mem_en),
      .we(mem_mask),
      .addr(mem_addr),
      .data_i(mem_din),
      .data_o(mem_dout_1)
  );

  // Infer single port BlockRAM for meta data arrays
  generate
    for (genvar w = 0; w < WAYS; w++) begin : gen_meta_ports
      always_ff @(posedge clk) begin
        if (meta_en[w]) begin
          if (meta_we[w]) begin
            meta[w][meta_addr[w]] <= meta_din[w];
          end
          meta_dout_q[w] <= meta[w][meta_addr[w]];
        end
      end
    end
  endgenerate

  always_ff @(posedge clk) begin
    if (meta_common_en) begin
      if (meta_common_we) begin
        meta_common[meta_common_addr] <= meta_common_din;
      end
      meta_common_dout_q <= meta_common[meta_common_addr];
    end
  end

  initial begin
    for (int w = 0; w < WAYS; w++) begin
      meta[w] = '{default: 0};
    end
    meta_common = '{default: 0};
    lfb = '{default: 0};
  end

  always_comb begin
    offset = core.req_addr[0+:OFFSET_BITS];
    cacheset = core.req_addr[OFFSET_BITS+:SET_BITS];
    tag = core.req_addr[OFFSET_BITS+SET_BITS+:TAG_BITS];
    req_load = core.req_valid && !core.req_we;
    req_store = core.req_valid && core.req_we;
    //req_idle = !core.req_valid;
  end


  always_comb begin
    for (int w = 0; w < WAYS; w++) begin
      wayhits_1[w] = meta_dout_q[w].valid && meta_dout_q[w].tag == tag_q;
    end
    hit_1 = |wayhits_1;

    store_hit_2 = |store_wayhits_q2;
    store_hit_valid = (req_store_q && hit_1) || store_hit_2;
    store_wayhits = req_store_q ? wayhits_1 : store_wayhits_q2;

    evict_way_1 = lfb[evict_id_q].evict;
    evict_set_1 = lfb[evict_id_q].addr[0+:SET_BITS];
    evict_tag_1 = lfb[evict_id_q].addr[SET_BITS+:TAG_BITS];

    bus.resp_ready = !evict_valid_q;

    for (int w = 0; w < WAYS; w++) begin
      meta_en[w] = 0;
      meta_we[w] = 0;
      meta_addr[w] = 0;
      meta_din[w] = 0;
      meta_common_en = 0;
      meta_common_we = 0;
      meta_common_addr = 0;
      meta_common_din = 0;

      mem_en[w] = 0;
      mem_addr[w] = 0;
      mem_mask[w] = 0;
      mem_din[w] = 0;
    end
    if (rst) begin
    end else if (req_load) begin
      for (int w = 0; w < WAYS; w++) begin
        meta_en[w] = 1;
        meta_addr[w] = cacheset;
        meta_common_en = 1;
        meta_common_addr = cacheset;

        mem_en[w] = 1;
        mem_addr[w] = cacheset;
      end
    end else if (store_hit_valid) begin
      for (int w = 0; w < WAYS; w++) begin
        mem_en[w] = store_wayhits[w];
        mem_addr[w] = store_cacheset_q;
        mem_mask[w][store_offset_q*4+:4] = store_mask_q;
        mem_din[w][store_offset_q*32+:32] = store_data_q;
      end
      //TODO accept new store on store hit
    end else if (evict_valid_q) begin
      meta_en[evict_way_1] = 1;
      meta_we[evict_way_1] = 1;
      meta_addr[evict_way_1] = evict_set_1;
      meta_din[evict_way_1] = '{valid: 1, tag: evict_tag_1};
      meta_common_en = 1;
      meta_common_we = 1;
      meta_common_addr = evict_set_1;
      meta_common_din = '{evict_next: evict_way_1 + 1}; //TODO fix overflow

      mem_en[evict_way_1] = 1;
      mem_addr[evict_way_1] = evict_set_1;
      mem_mask[evict_way_1] = '1;
      mem_din[evict_way_1] = evict_line_q;
    end else if (req_store) begin
      for (int w = 0; w < WAYS; w++) begin
        meta_en[w] = 1;
        meta_addr[w] = cacheset;
        meta_common_en = 1;
        meta_common_addr = cacheset;
      end
    end
  end
  always_ff @(posedge clk) begin
    if (rst) begin
      evict_valid_q <= 0;
      store_wayhits_q2 <= 0;
      req_load_q <= 0;
      req_store_q <= 0;
      //req_idle_q <= 0;
    end else begin
      req_load_q  <= 0;
      req_store_q <= 0;
      //req_idle_q  <= !core.req_valid;
      if (bus.resp_valid && !evict_valid_q) begin
        evict_valid_q <= 1;
        evict_line_q <= bus.resp_data;
        evict_id_q <= bus.resp_id;
      end
      if (core.req_valid) begin
        tag_q <= tag;
        cacheset_q <= cacheset;
        offset_q <= offset;
      end
      if (req_store_q) begin
        store_wayhits_q2 <= wayhits_1;
      end
      if (req_load) begin
        req_load_q <= 1;
      end else if (store_hit_valid) begin
        store_wayhits_q2 <= 0;
      end else if (evict_valid_q) begin
        evict_valid_q <= 0;
        lfb[evict_id_q].valid <= 0;
        //TODO write back evicted line
      end else if (req_store) begin
        req_store_q <= 1;
        store_cacheset_q <= cacheset;
        store_offset_q <= offset;
        store_mask_q <= core.req_mask;
        store_data_q <= core.req_data;
      end
    end
  end

  // After cycle 1 (meta data lookup)
  always_comb begin
    core.resp_data = 0;
    for (int w = 0; w < WAYS; w++) begin
      if (wayhits_1[w]) begin
        core.resp_data = mem_dout_1[w][offset_q*4+:32];
      end
    end

    core.resp_ack = 0;
    if (req_load_q || req_store_q) begin
      core.resp_ack = hit_1;
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

  //LFB: Addr CAM
  always_comb begin
    for (int i = 0; i < LFB_SZ; i++) begin
      lfb_hits_1[i] = 0;
      if (lfb[i].valid && lfb[i].addr == {tag_q, cacheset_q}) begin
        lfb_hits_1[i] = 1;
      end
    end
  end

  //LFB: reserve new entry on miss that is not already in LFB
  always_ff @(posedge clk) begin
    if (req_load_q || req_store_q) begin
      if (!hit_1 && !(|lfb_hits_1) && lfb_free_valid) begin
        lfb[lfb_free] <= '{
            valid: 1,
            fired: 0,
            ack: 0,
            addr: {tag_q, cacheset_q},
            evict: meta_common_dout_q.evict_next
        };
      end
    end
  end

  //LFB: search unfired miss
  always_comb begin
    lfb_unfired_valid = 0;
    lfb_unfired = 0;
    for (int i = LFB_SZ - 1; i >= 0; i--) begin
      if (lfb[i].valid && !lfb[i].fired) begin
        lfb_unfired_valid = 1;
        lfb_unfired = i[LFB_PTR_BITS-1:0];
      end
    end
  end

  //LFB: fire requests to memory
  always_ff @(posedge clk) begin
    if (rst) begin
      bus.req_valid <= 0;
    end else begin
      if (bus.req_ready) begin
        bus.req_valid <= 0;
        if (lfb_unfired_valid) begin
          bus.req_valid <= 1;
          bus.req_we <= 0;
          bus.req_addr <= lfb[lfb_unfired].addr;
          bus.req_data <= 0;
          bus.req_id <= lfb_unfired;
          lfb[lfb_unfired].fired <= 1;
        end
      end
    end
  end

endmodule
