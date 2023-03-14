module ExecuteStage (
    input logic clk,
    input logic rst,
    pipeline_if.Upstream u,
    pipeline_if.Downstream d,
    input Uop::decode_t uopIn,
    output Uop::execute_t uopOut
);

  import Uop::*;

  logic stallBufferValid;
  decode_t stalledUop;
  logic stalledUopValid;

  decode_t currUop;
  logic currUopValid;

  assign currUopValid = stallBufferValid ? stalledUopValid : u.valid;
  assign currUop = stallBufferValid ? stalledUop : uopIn;
  assign u.stall = stallBufferValid;

  val_t aluOut;

  val_t s1Bypass;
  val_t s2Bypass;

  always_comb begin
    if (d.valid && currUop.rs1 == uopOut.rd && !uopOut.memOp.en) begin
      s1Bypass = uopOut.rdVal;
    end else begin
      s1Bypass = currUop.rs1Val;
    end
    if (d.valid && currUop.rs2 == uopOut.rd && !uopOut.memOp.en) begin
      s2Bypass = uopOut.rdVal;
    end else begin
      s2Bypass = currUop.rs2Val;
    end
  end

  IntALU m_alu (
      .op(currUop.op.intalu),
      .s1(s1Bypass),
      .s2(currUop.immValid ? currUop.imm : s2Bypass),
      .d (aluOut)
  );

  always_ff @(posedge clk) begin
    if (rst) begin
      stalledUop <= 0;
      stalledUopValid <= 0;
      stallBufferValid <= 0;
      uopOut <= 0;
      d.valid <= 0;
    end else begin
      if (d.stall) begin
        stallBufferValid <= 1;
        stalledUop <= currUop;
        stalledUopValid <= currUopValid;
      end else begin
        stallBufferValid <= 0;
        d.valid <= currUopValid;
        uopOut.ex <= currUop.ex;
        uopOut.rd <= currUop.rd;
        uopOut.rs2Val <= s2Bypass;
        uopOut.memOp <= currUop.memOp;

        case (currUop.fu)
          FU_INTALU: begin
            uopOut.rdVal <= aluOut;
          end
          default: d.valid <= 0;
        endcase

      end
    end
  end

endmodule
