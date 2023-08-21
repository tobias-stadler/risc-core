module L1ICache #(
    parameter int SET_BITS = 3
) (
    input logic clk,
    input logic rst,
    l1icache_core_if.Server core,
    l1cache_mem_if.Client bus
);

  import Mem::*;

  localparam int WAYS = 2;
  localparam int ADDR_BITS = 28;
  localparam int TAG_BITS = ADDR_BITS - SET_BITS;
  localparam int SETS = 2 ** SET_BITS;

  typedef logic [TAG_BITS-1:0] tag_t;
  typedef logic [SET_BITS-1:0] set_t;

  typedef struct packed {
    logic valid;
    tag_t tag;
  } meta_way_t;

  typedef struct packed {logic mru;} meta_common_t;

  set_t cacheset;
  set_t cacheset_q;
  tag_t tag;
  tag_t tag_q;

  logic req_valid_q;
  logic fired_q;
  logic evicted_q;

  logic hit_1;
  logic [WAYS-1:0] wayhits_1;
  logic wayhits_mru_1;
  logic lru_1;

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

  line_t mem[WAYS][SETS];
  logic mem_en[WAYS];
  logic mem_we[WAYS];
  set_t mem_addr[WAYS];
  line_t mem_din[WAYS];
  line_t mem_dout_q[WAYS];

  // Infer single port BlockRAM for meta and data arrays
  generate
    for (genvar w = 0; w < WAYS; w++) begin : gen_ram_ports
      always_ff @(posedge clk) begin
        if (meta_en[w]) begin
          if (meta_we[w]) begin
            meta[w][meta_addr[w]] <= meta_din[w];
          end
          meta_dout_q[w] <= meta[w][meta_addr[w]];
        end
      end
      always_ff @(posedge clk) begin
        if (mem_en[w]) begin
          if (mem_we[w]) begin
            mem[w][mem_addr[w]] <= mem_din[w];
          end
          mem_dout_q[w] <= mem[w][mem_addr[w]];
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

  // Initialize BlockRAM (FPGA only)
  initial begin
    for (int w = 0; w < WAYS; w++) begin
      meta[w] = '{default: 0};
      mem[w]  = '{default: 0};
    end
    meta_common = '{default: 0};
  end

  always_comb begin
    cacheset = core.req_addr[0+:SET_BITS];
    tag = core.req_addr[SET_BITS+:TAG_BITS];
  end

  always_comb begin
    bus.req_we = 0;
    bus.req_id = 0;
    bus.req_data = 0;
    bus.resp_ready = 1;
  end

  always_comb begin
    case (wayhits_1)
      2'b01:   wayhits_mru_1 = 0;
      2'b10:   wayhits_mru_1 = 1;
      default: wayhits_mru_1 = 1;
    endcase
  end

  assign lru_1 = ~meta_common_dout_q.mru;

  always_comb begin
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
      mem_we[w] = 0;
      mem_addr[w] = 0;
      mem_din[w] = 0;
    end

    if (rst) begin
    end else begin
      //New load request from core
      if (core.req_ready && core.req_valid) begin
        for (int w = 0; w < WAYS; w++) begin
          meta_en[w] = 1;
          meta_addr[w] = cacheset;

          mem_en[w] = 1;
          mem_addr[w] = cacheset;
        end
      end

      if (req_valid_q) begin
        //Cacheline received from bus
        if (fired_q && bus.resp_valid && bus.resp_ready) begin
          meta_en[lru_1] = 1;
          meta_we[lru_1] = 1;
          meta_addr[lru_1] = cacheset_q;
          meta_din[lru_1] = '{valid: 1, tag: tag_q};

          mem_en[lru_1] = 1;
          mem_we[lru_1] = 1;
          mem_addr[lru_1] = cacheset_q;
          mem_din[lru_1] = bus.resp_data;
        end
        //Refetch cacheline after eviction
        if (evicted_q) begin
          for (int w = 0; w < WAYS; w++) begin
            meta_en[w] = 1;
            meta_addr[w] = cacheset_q;

            mem_en[w] = 1;
            mem_addr[w] = cacheset_q;
          end
        end
        if (hit_1) begin
          // Update MRU information if last access was a hit
          meta_common_en   = 1;
          meta_common_addr = cacheset_q;
          meta_common_we   = 1;
          meta_common_din  = '{mru: wayhits_mru_1};
        end else if (!hit_1 && !fired_q) begin
          // Load MRU information if last access was a miss
          // (bus request will be fired on same cycle)
          meta_common_en   = 1;
          meta_common_addr = cacheset_q;
        end
      end

    end
  end

  assign core.req_ready = req_valid_q ? hit_1 : 1;

  always_ff @(posedge clk) begin
    if (rst) begin
      tag_q <= 0;
      cacheset_q <= 0;

      req_valid_q <= 0;
      fired_q <= 0;
      bus.req_valid <= 0;
      evicted_q <= 1;
    end else begin
      //New load request from core
      if (core.req_ready && core.req_valid) begin
        req_valid_q <= 1;
        tag_q <= tag;
        cacheset_q <= cacheset;
      end else if (core.req_ready && !core.req_valid) begin
        req_valid_q <= 0;
      end

      // Cacheline received from bus
      if (req_valid_q && fired_q && bus.resp_ready && bus.resp_valid) begin
        evicted_q <= 1;
      end

      // Cacheline refetched
      if (req_valid_q && evicted_q) begin
        fired_q   <= 0;
        evicted_q <= 0;
      end

      // Request cacheline from bus
      if (bus.req_ready) begin
        bus.req_valid <= 0;
        if (req_valid_q && !hit_1 && !fired_q) begin
          fired_q <= 1;
          bus.req_valid <= 1;
          bus.req_addr <= {tag_q, cacheset_q};
        end
      end
    end
  end

  always_comb begin
    for (int w = 0; w < WAYS; w++) begin
      wayhits_1[w] = meta_dout_q[w].valid && meta_dout_q[w].tag == tag_q;
    end
    hit_1 = |wayhits_1;
  end

  always_comb begin
    core.resp_valid = req_valid_q ? hit_1 : 0;

    core.resp_data  = 0;
    for (int w = 0; w < WAYS; w++) begin
      if (wayhits_1[w]) begin
        core.resp_data |= mem_dout_q[w];
      end
    end
  end
endmodule
