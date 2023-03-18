module ExecuteStage (
    input logic clk,
    input logic rst,
    pipeline_if.Upstream u,
    pipeline_if.Downstream d,
    input Uop::decode_t uopIn,
    output Uop::execute_t uopOut,
    bypass_if.Observer memBypass,
    bypass_if.Observer wbBypass
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

  val_t   aluOut;
  flags_t aluFlags;

  val_t   s1Bypass;
  val_t   s2Bypass;
  flags_t flagsBypass;

  always_comb begin
    if (uopOut.flagsValid) begin
      flagsBypass = uopOut.flags;
    end else if (memBypass.flagsValid) begin
      flagsBypass = memBypass.flags;
    end else if (wbBypass.flagsValid) begin
      flagsBypass = wbBypass.flags;
    end else begin
      flagsBypass = '0;  // This should never hapen. Is this optimized out?
    end
  end

  always_comb begin
    if (currUop.rs1 == 0) begin
      s1Bypass = 0;
    end else if (d.valid && currUop.rs1 == uopOut.rd && !uopOut.memOp.isLd && !uopOut.memOp.isSt) begin
      s1Bypass = uopOut.rdVal;
    end else if (memBypass.rValid && currUop.rs1 == memBypass.r) begin
      s1Bypass = memBypass.rVal;
    end else if (wbBypass.rValid && currUop.rs1 == wbBypass.r) begin
      s1Bypass = wbBypass.rVal;
    end else begin
      s1Bypass = currUop.rs1Val;
    end

    if (currUop.rs2 == 0) begin
      s2Bypass = 0;
    end else if (d.valid && currUop.rs2 == uopOut.rd && !uopOut.memOp.isLd && !uopOut.memOp.isSt) begin
      s2Bypass = uopOut.rdVal;
    end else if (memBypass.rValid && currUop.rs2 == memBypass.r) begin
      s2Bypass = memBypass.rVal;
    end else if (wbBypass.rValid && currUop.rs2 == wbBypass.r) begin
      s2Bypass = wbBypass.rVal;
    end else begin
      s2Bypass = currUop.rs2Val;
    end
  end

  IntALU m_alu (
      .op(currUop.op.intalu),
      .s1(s1Bypass),
      .s2(currUop.immValid ? currUop.imm : s2Bypass),
      .d(aluOut),
      .flags(aluFlags)
  );

  //TODO remove
  wire _unused_ok = &{1'b0, flagsBypass};

  logic shouldStall;
  assign shouldStall = d.valid && uopOut.memOp.isLd &&
      (uopOut.rd == currUop.rs1 || uopOut.rd == currUop.rs2) && uopOut.rd != 0;

  always_ff @(posedge clk) begin
    if (rst) begin
      stallBufferValid <= 0;
      d.valid <= 0;
    end else begin
      if (shouldStall) begin
        stallBufferValid <= 1;
        stalledUop <= currUop;
        stalledUopValid <= currUopValid;
        d.valid <= 0;
      end else begin
        stallBufferValid <= 0;
        d.valid <= currUopValid;
        uopOut.ex <= currUop.ex;
        uopOut.exValid <= currUop.exValid;
        uopOut.rd <= currUop.rd;
        uopOut.rs2Val <= s2Bypass;
        uopOut.memOp <= currUop.memOp;
        uopOut.flagsValid <= currUop.flagsValid;

        case (currUop.fu)
          FU_INTALU: begin
            uopOut.rdVal <= aluOut;
            uopOut.flags <= aluFlags;
          end
          default: d.valid <= 0;
        endcase
      end
    end
  end

endmodule
