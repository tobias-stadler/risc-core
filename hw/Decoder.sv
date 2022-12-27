module Decoder (
    input  Instr::enc_t enc,
    output UOP::dec_t   dec
);

  always_comb begin
    dec.op = UOP::OP_NOP;
    dec.ex = UOP::EX_NONE;
    dec.rd = 0;
    dec.rs1 = 0;
    dec.rs2 = 0;
    dec.immValid = 0;
    dec.imm = 0;
    case (enc.op.op)
      Instr::OP_ARITH, Instr::OP_ARITHI: begin
        case (enc.r.funct3)
          Instr::OP_ARITH_ADD: dec.op = UOP::OP_ADD;
          Instr::OP_ARITH_SUB: dec.op = UOP::OP_SUB;
          Instr::OP_ARITH_OR: dec.op = UOP::OP_OR;
          Instr::OP_ARITH_AND: dec.op = UOP::OP_AND;
          Instr::OP_ARITH_XOR: dec.op = UOP::OP_XOR;
          Instr::OP_ARITH_SHL: dec.op = UOP::OP_SHL;
          Instr::OP_ARITH_SHR: dec.op = UOP::OP_SHR;
          Instr::OP_ARITH_SHRA: dec.op = UOP::OP_SHRA;
          default: dec.ex = UOP::EX_DECODE;
        endcase
        dec.rd  = enc.r.rd;
        dec.rs1 = enc.r.rs1;
        if (enc.op.op == Instr::OP_ARITHI) begin
          dec.immValid = 1;
          dec.imm = {{20{enc.i.imm[11]}}, enc.i.imm};
        end else begin
          dec.rs2 = enc.r.rs2;
        end
      end
      default: dec.ex = UOP::EX_DECODE;
    endcase
  end
endmodule
