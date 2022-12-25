import Instr::*;
import UOP::*;

module Decoder (
    input Instr::enc_t enc,
    output UOP::dec_t dec
);

  always_comb begin
    dec.ex = UOP::EX_NONE;
    case (enc.op.op)
      Instr::OP_ARITH: begin
        case (enc.r.funct3)
          Instr::OP_ARITH_ADD: dec.op = UOP::ADD;
          default: dec.ex = UOP::EX_DECODE;
        endcase
        uop.rd  = instr.r.rd;
        uop.rs1 = instr.r.rs1;
        uop.rs2 = instr.r.rs2;
      end
      default: uop.ex = UOP::EX_DECODE;
    endcase
  end

endmodule
