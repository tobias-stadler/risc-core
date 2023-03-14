module MemoryStage #(
    parameter int OFFSET_BITS = 4,
    parameter int SET_BITS = 5,
    parameter int TAG_BITS = 32 - SET_BITS - OFFSET_BITS
) (
    input logic clk,
    input logic rst,
    pipeline_if.Upstream u,
    pipeline_if.Downstream d,
    input Uop::execute_t uopIn,
    output Uop::memory_t uopOut
);

  import Uop::*;


  typedef logic [TAG_BITS-1:0] tag_t;
  typedef logic [SET_BITS-1:0] set_t;
  typedef logic [OFFSET_BITS-1:0] offset_t;

  typedef logic [7:0] b_t;
  typedef logic [15:0] hw_t;

  typedef union packed {
    logic [31:0] raw;
    hw_t[1:0] hw;
    b_t[3:0] b;
  } w_t;

  typedef union packed {
    logic [127:0] raw;
    w_t[3:0] w;
  } line_t;

  typedef struct packed {
    logic valid;
    tag_t tag;
  } entry_t;

  execute_t currUop;
  assign currUop = uopIn;

  offset_t offset;
  assign offset = currUop.rdVal[0+:OFFSET_BITS];
  set_t set;
  assign set = currUop.rdVal[OFFSET_BITS+:SET_BITS];
  tag_t tag;
  assign tag = currUop.rdVal[OFFSET_BITS+SET_BITS+:TAG_BITS];

  entry_t meta[2**SET_BITS];
  line_t  line[2**SET_BITS];

  always_ff @(posedge clk) begin
    if (rst) begin
      u.stall <= 0;
      d.valid <= 0;
      uopOut <= 0;
      meta <= '{default: 0};
    end else begin
      d.valid <= u.valid;
      uopOut.ex <= currUop.ex;
      uopOut.rd <= currUop.rd;
      uopOut.rdVal <= currUop.rdVal;

      if (u.valid && currUop.memOp.en) begin
        entry_t e = meta[set];
        logic [1:0] wIdx = offset[3:2];
        if (e.valid && tag == e.tag) begin
          case (currUop.memOp.sz)
            MEM_OP_SZ_B: begin
              if (currUop.memOp.isSt) begin
                line[set].w[wIdx].b[offset[1:0]] <= currUop.rs2Val[7:0];
              end else begin
                b_t b = line[set].w[wIdx].b[offset[1:0]];
                if (currUop.memOp.signExtend) uopOut.rdVal <= {{24{b[7]}}, b};
                else uopOut.rdVal <= {{24{1'b0}}, b};
              end
            end
            MEM_OP_SZ_H: begin
              if (offset[0] == '0) begin
                if (currUop.memOp.isSt) begin
                  line[set].w[wIdx].hw[offset[1]] <= currUop.rs2Val[15:0];
                end else begin
                  hw_t hw = line[set].w[wIdx].hw[offset[1]];
                  if (currUop.memOp.signExtend) uopOut.rdVal <= {{16{hw[15]}}, hw};
                  else uopOut.rdVal <= {{16{1'b0}}, hw};
                end
              end else begin
                uopOut.ex <= EX_MEM_ALIGN;
              end
            end
            MEM_OP_SZ_W: begin
              if (offset[1:0] == '0) begin
                if (currUop.memOp.isSt) begin
                  line[set].w[wIdx] <= currUop.rs2Val;
                end else begin
                  uopOut.rdVal <= line[set].w[wIdx];
                end
              end else begin
                uopOut.ex <= EX_MEM_ALIGN;
              end
            end
          default:;
          endcase
        end else begin
          uopOut.ex <= EX_MEM_MISS;
        end
      end
    end
  end

endmodule
