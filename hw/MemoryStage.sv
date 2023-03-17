module MemoryStage #(
) (
    input logic clk,
    input logic rst,
    pipeline_if.Upstream u,
    pipeline_if.Downstream d,
    input Uop::execute_t uopIn,
    output Uop::memory_t uopOut,
    bypass_if.Subject bypass,
    l1dcache_core_if.Client cache
);

  import Uop::*;

  assign bypass.rValid = d.valid; //TODO only valid on load or no memop
  assign bypass.r = uopOut.rd;
  assign bypass.rVal = uopOut.rdVal;
  assign bypass.flagsValid = d.valid & uopOut.flagsValid;

  execute_t currUop;
  assign currUop = uopIn;

  assign cache.kill = '0;
  assign cache.addr = '0;
  assign cache.reqData = '0;


  //TODO kill store request on exception/miss
  always_comb begin
    cache.en = '0;
    cache.enW = '0;
    cache.addr = currUop.rdVal[31:2];
    cache.reqData = currUop.rs2Val;
    if (u.valid & currUop.memOp.en) begin
      cache.en = '1;
      if (currUop.memOp.isSt) begin
        cache.enW = '1;
      end
    end
    unique case (currUop.memOp.sz)
      MEM_OP_SZ_B: begin
        cache.mask = 4'b0001; //TODO alignment
      end
      MEM_OP_SZ_H: begin
        cache.mask = 4'b0011;
      end
      MEM_OP_SZ_W: begin
        cache.mask = 4'b1111;
      end
      default: cache.mask = '0;
    endcase
  end

  /*
  val_t rdVal;
  logic selectCache;

  always_comb begin
      if(selectCache) begin
          uopOut.rdVal = cache.respData;
      end else begin
          uopOut.rdVal = rdVal;
      end
  end*/

  //TODO remove
  wire _unused_ok = &{1'b0, cache.respData, cache.hit, 1'b0};

  always_ff @(posedge clk) begin
    if (rst) begin
      u.stall <= 0;
      d.valid <= 0;
    end else begin
      d.valid <= u.valid;
      uopOut.ex <= currUop.ex;
      uopOut.rd <= currUop.rd;
      uopOut.rdVal <= currUop.rdVal;
      uopOut.flags <= currUop.flags;
      uopOut.flagsValid <= currUop.flagsValid;
      //selectCache <= currUop.memOp.en && !currUop.memOp.isSt;

      /*      if (u.valid && currUop.memOp.en && currUop.ex == EX_NONE) begin
        if (e.valid && tag == e.tag) begin
          case (currUop.memOp.sz)
            MEM_OP_SZ_B: begin
              if (currUop.memOp.isSt) begin
              end else begin
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
    */
    end
  end

endmodule
