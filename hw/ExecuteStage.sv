module ExecuteStage (
    input logic clk,
    input logic rst,
    pipeline_if.Upstream u,
    pipeline_if.Downstream d,
    input Uop::decode_t uopIn,
    output Uop::execute_t uopOut,
    bypass_if.Observer memBypass,
    bypass_if.Observer wbBypass,
    output Uop::redirect_pc_t redirect
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

  val_t rdVal;
  logic brValid;
  logic brTaken;

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
      .s1(currUop.s1IsPc ? {currUop.pc, 2'b0} : s1Bypass),
      .s2(currUop.immValid ? currUop.imm : s2Bypass),
      .d(aluOut),
      .flags(aluFlags)
  );

  //TODO remove
  wire _unused_ok = &{1'b0, brTaken};

  logic shouldStall;
  assign shouldStall = d.valid && uopOut.memOp.isLd &&
      (uopOut.rd == currUop.rs1 || uopOut.rd == currUop.rs2) && uopOut.rd != 0;

  always_comb begin
    logic lt = flagsBypass.v != flagsBypass.s;
    logic ge = flagsBypass.v == flagsBypass.s;
    case (currUop.op.brCond)
      default: brTaken = 0;
      Instr::COND_JMP: brTaken = 1;
      Instr::COND_Z: brTaken = flagsBypass.z;
      Instr::COND_NZ: brTaken = !flagsBypass.z;
      Instr::COND_S: brTaken = flagsBypass.s;
      Instr::COND_NS: brTaken = !flagsBypass.s;
      Instr::COND_C: brTaken = flagsBypass.c;
      Instr::COND_NC: brTaken = !flagsBypass.c;
      Instr::COND_V: brTaken = flagsBypass.v;
      Instr::COND_NV: brTaken = !flagsBypass.v;
      Instr::COND_LT: brTaken = lt;
      Instr::COND_LE: brTaken = flagsBypass.z || lt;
      Instr::COND_GT: brTaken = !flagsBypass.z && ge;
      Instr::COND_GE: brTaken = ge;
    endcase
  end

  always_comb begin
    brValid = 0;
    rdVal = 'x;
    case (currUop.fu)
      FU_INTALU: begin
        rdVal = aluOut;
      end
      FU_BR: begin
        rdVal = {currUop.pc, 2'b0} + 4;
        brValid = 1;
      end
      default:;
    endcase
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      stallBufferValid <= 0;
      d.valid <= 0;
      redirect.valid <= 0;
      redirect.pc <= 'x;
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
        uopOut.flags <= aluFlags;
        uopOut.rdVal <= rdVal;
        redirect.valid <= currUopValid && brValid && brTaken;
        redirect.pc <= aluOut[31:2];
      end
    end
  end

endmodule
