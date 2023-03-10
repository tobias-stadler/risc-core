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

  val_t s1;
  val_t s2;

  always_comb begin
      if (d.valid && currUop.rs1 == uopOut.rd) begin
          s1 = uopOut.rdVal;
      end else begin
          s1 = currUop.rs2val;
      end

      if (currUop.immValid) begin
          s2 = currUop.imm;
      end else if (d.valid && currUop.rs2 == uopOut.rd) begin
          s2 = uopOut.rdVal;
      end else begin
          s2 = currUop.rs2val;
      end
  end

  IntALU m_alu (
      .op(currUop.op.intalu),
      .s1(s1),
      .s2(s2),
      .d(aluOut)
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
        uopOut.ex <= currUop.ex;
        uopOut.rd <= currUop.rd;
        d.valid <= currUopValid;

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
