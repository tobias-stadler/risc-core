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

  execute_t currUop;
  assign currUop = uopIn;

  logic addrUnaligned;

  //Before pipeline registers
  always_comb begin
    cache.en = '0;
    cache.enW = '0;
    cache.addr = currUop.rdVal[31:2];
    cache.reqData = currUop.rs2Val;
    addrUnaligned = '0;

    case (currUop.memOp.sz)
      MEM_OP_SZ_B: begin
        cache.mask = 4'b0001 << currUop.rdVal[1:0];  //TODO alignment
      end
      MEM_OP_SZ_H: begin
        case (currUop.rdVal[1:0])
          0: cache.mask = 4'b0011;
          2: cache.mask = 4'b1100;
          default: begin
            cache.mask = '0;
            addrUnaligned = '1;
          end
        endcase
      end
      MEM_OP_SZ_W: begin
        cache.mask = 4'b1111;
        addrUnaligned = |currUop.rdVal[1:0];
      end
      default: cache.mask = '0;
    endcase

    if (u.valid && !currUop.exValid && !addrUnaligned) begin
      if (currUop.memOp.isSt) begin
        cache.en  = '1;
        cache.enW = '1;
      end else if (currUop.memOp.isLd) begin
        cache.en = '1;
      end
    end

  end

  assign u.stall = '0;

  ex_t ex;
  logic exValid;
  reg_t rd;
  val_t rdVal;
  logic flagsValid;
  flags_t flags;
  mem_op_t memOp;

  //After pipeline registers
  always_comb begin
    uopOut.ex = ex;
    uopOut.exValid = exValid;
    uopOut.rd = rd;
    uopOut.rdVal = rdVal;
    uopOut.flagsValid = flagsValid;
    uopOut.flags = flags;
    uopOut.memNack = cache.nack;


    if (memOp.isLd) begin
      case (memOp.sz)
        MEM_OP_SZ_B: begin
          b_t b = cache.respData[rdVal[1:0]*8+:8];
          uopOut.rdVal = {memOp.signExtend ? {24{b[7]}} : 24'b0, b};
        end
        MEM_OP_SZ_H: begin
          hw_t hw = cache.respData[rdVal[1]*16+:16];
          uopOut.rdVal = {memOp.signExtend ? {16{hw[15]}} : 16'b0, hw};
        end
        MEM_OP_SZ_W: begin
          uopOut.rdVal = cache.respData;
        end
        default: ;
      endcase
    end

    bypass.rValid = d.valid && (memOp.isLd || !memOp.isSt);
    bypass.r = uopOut.rd;
    bypass.rVal = uopOut.rdVal;

    bypass.flagsValid = d.valid && uopOut.flagsValid;
    bypass.flags = flags;
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      d.valid <= 0;
    end else begin
      d.valid <= u.valid;
    end
  end

  always_ff @(posedge clk) begin
    if (u.valid) begin
      if (currUop.exValid) begin
        ex <= currUop.ex;
        exValid <= '1;
      end else if (addrUnaligned) begin
        ex <= EX_MEM_ALIGN;
        exValid <= '1;
      end else begin
        exValid <= '0;
      end

      rd <= currUop.rd;
      rdVal <= currUop.rdVal;
      flags <= currUop.flags;
      flagsValid <= currUop.flagsValid;
      memOp <= currUop.memOp;
    end
  end

endmodule
