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
    cache.req_valid = 0;
    cache.req_we = 0;
    cache.req_data = 0;
    cache.req_addr = currUop.rdVal[31:2];
    cache.req_mask = 0;
    addrUnaligned = 0;

    case (currUop.memOp.sz)
      MEM_OP_SZ_B: begin
        cache.req_mask[currUop.rdVal[1:0]] = 1;
        cache.req_data[currUop.rdVal[1:0]*8+:8] = currUop.rs2Val[7:0];
      end
      MEM_OP_SZ_H: begin
        case (currUop.rdVal[1:0])
          0: begin
            cache.req_mask = 4'b0011;
            cache.req_data[15:0] = currUop.rs2Val[15:0];
          end
          2: begin
            cache.req_mask = 4'b1100;
            cache.req_data[31:16] = currUop.rs2Val[15:0];
          end
          default: begin
            addrUnaligned = 1;
          end
        endcase
      end
      MEM_OP_SZ_W: begin
        cache.req_mask = 4'b1111;
        cache.req_data = currUop.rs2Val;
        addrUnaligned  = |currUop.rdVal[1:0];
      end
      default: ;
    endcase

    if (u.valid && !rst && !currUop.exValid && !addrUnaligned) begin
      if (currUop.memOp.isSt) begin
        cache.req_valid = 1;
        cache.req_we = 1;
      end
      if (currUop.memOp.isLd) begin
        cache.req_valid = 1;
      end
    end

  end

  assign u.stall = 0;

  ex_t ex;
  logic exValid;
  reg_t rd;
  val_t rdVal;
  logic flagsValid;
  flags_t flags;
  mem_op_t memOp;

  Mem::b_t resp_data_b;
  Mem::hw_t resp_data_hw;

  //After pipeline registers
  always_comb begin
    uopOut.ex = ex;
    uopOut.exValid = exValid;
    uopOut.rd = rd;
    uopOut.rdVal = rdVal;
    uopOut.flagsValid = flagsValid;
    uopOut.flags = flags;
    uopOut.memNack = (memOp.isLd || memOp.isSt) && !cache.resp_ack;

    resp_data_b = cache.resp_data[rdVal[1:0]*8+:8];
    resp_data_hw = cache.resp_data[rdVal[1]*16+:16];

    if (memOp.isLd) begin
      case (memOp.sz)
        MEM_OP_SZ_B: begin
          uopOut.rdVal = {memOp.signExtend ? {24{resp_data_b[7]}} : 24'b0, resp_data_b};
        end
        MEM_OP_SZ_H: begin
          uopOut.rdVal = {memOp.signExtend ? {16{resp_data_hw[15]}} : 16'b0, resp_data_hw};
        end
        MEM_OP_SZ_W: begin
          uopOut.rdVal = cache.resp_data;
        end
        default: ;
      endcase
    end

    bypass.rValid = d.valid;  // && (memOp.isLd || !memOp.isSt) not needed because store rd=0
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
        exValid <= 1;
      end else if (addrUnaligned) begin
        ex <= EX_MEM_ALIGN;
        exValid <= 1;
      end else begin
        exValid <= 0;
      end

      rd <= currUop.rd;
      rdVal <= currUop.rdVal;
      flags <= currUop.flags;
      flagsValid <= currUop.flagsValid;
      memOp <= currUop.memOp;
    end
  end

endmodule
