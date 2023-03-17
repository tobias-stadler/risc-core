module DecodeStage (
    input logic clk,
    input logic rst,
    pipeline_if.Upstream u,
    pipeline_if.Downstream d,
    regfile_read_if.Client read0,
    regfile_read_if.Client read1,
    input Uop::fetch_t uopIn,
    output Uop::decode_t uopOut
);

  logic stallBufferValid;
  Uop::fetch_t stalledUop;
  logic stalledUopValid;

  Uop::fetch_t currUop;
  logic currUopValid;

  assign currUopValid = stallBufferValid ? stalledUopValid : u.valid;
  assign currUop = stallBufferValid ? stalledUop : uopIn;

  Uop::dec_t uopDec;
  Decoder m_dec (
      .enc(currUop.enc),
      .dec(uopDec)
  );

  assign read0.addr = uopDec.rs1;
  assign read1.addr = uopDec.rs2;
  assign u.stall = stallBufferValid;

  always_ff @(posedge clk) begin
    if (rst) begin
      stallBufferValid <= 0;
      stalledUop <= 0;
      stalledUopValid <= 0;
      d.valid <= 0;
      uopOut <= 0;
    end else begin
      if (d.stall) begin
        stalledUop <= currUop;
        stalledUopValid <= currUopValid;
        stallBufferValid <= 1;
      end else begin
        stallBufferValid <= 0;

        d.valid <= currUopValid;
        uopOut.ex <= uopDec.ex;
        uopOut.fu <= uopDec.fu;
        uopOut.op <= uopDec.op;
        uopOut.rd <= uopDec.rd;
        uopOut.rs1 <= uopDec.rs1;
        uopOut.rs1Val <= read0.val;
        uopOut.rs2 <= uopDec.rs2;
        uopOut.rs2Val <= read1.val;
        uopOut.imm <= uopDec.imm;
        uopOut.immValid <= uopDec.immValid;
        uopOut.memOp <= uopDec.memOp;
        uopOut.flagsValid <= uopDec.flagsValid;
      end
    end
  end

endmodule

