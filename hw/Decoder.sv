module Decoder (
    input  Instr::enc_t enc,
    output Uop::dec_t   dec
);

  Uop::val_t immI;
  assign immI = {{20{enc.i.imm[11]}}, enc.i.imm};

  Uop::val_t immS;
  assign immS = {{20{enc.s.imm7[6]}}, enc.s.imm7, enc.s.imm5};

  always_comb begin
    dec.ex = Uop::EX_DECODE;
    dec.exValid = 0;
    dec.rd = 0;
    dec.rs1 = 0;
    dec.rs2 = 0;
    dec.immValid = 0;
    dec.imm = 0;
    dec.fu = Uop::FU_NONE;
    dec.op = 0;
    dec.memOp = 0;
    dec.flagsValid = 0;
    case (enc.op.op)
      Instr::OP_NOP: ;
      Instr::OP_ARITH, Instr::OP_ARITHI: begin
        dec.fu = Uop::FU_INTALU;
        dec.flagsValid = 1;
        case (enc.r.funct3)
          Instr::OP_ARITH_ADD: dec.op.intalu = Uop::INTALU_OP_ADD;
          Instr::OP_ARITH_SUB: dec.op.intalu = Uop::INTALU_OP_SUB;
          Instr::OP_ARITH_OR: dec.op.intalu = Uop::INTALU_OP_OR;
          Instr::OP_ARITH_AND: dec.op.intalu = Uop::INTALU_OP_AND;
          Instr::OP_ARITH_XOR: dec.op.intalu = Uop::INTALU_OP_XOR;
          Instr::OP_ARITH_SHL: dec.op.intalu = Uop::INTALU_OP_SHL;
          Instr::OP_ARITH_SHR: dec.op.intalu = Uop::INTALU_OP_SHR;
          Instr::OP_ARITH_SHRA: dec.op.intalu = Uop::INTALU_OP_SHRA;
          default: dec.exValid = 1;
        endcase
        dec.rd  = enc.r.rd;
        dec.rs1 = enc.r.rs1;
        if (enc.op.op == Instr::OP_ARITHI) begin
          dec.immValid = 1;
          dec.imm = immI;
        end else begin
          dec.rs2 = enc.r.rs2;
        end
      end
      Instr::OP_LD: begin
        dec.fu = Uop::FU_INTALU;
        dec.op.intalu = Uop::INTALU_OP_ADD;
        dec.immValid = '1;
        dec.imm = immI;
        dec.rd = enc.i.rd;
        dec.rs1 = enc.i.rs1;
        dec.memOp.isLd = 1;
        case (enc.i.funct3)
          Instr::OP_LD_B: dec.memOp.sz = Uop::MEM_OP_SZ_B;
          Instr::OP_LD_H: dec.memOp.sz = Uop::MEM_OP_SZ_H;
          Instr::OP_LD_W: dec.memOp.sz = Uop::MEM_OP_SZ_W;
          Instr::OP_LD_BS: begin
            dec.memOp.sz = Uop::MEM_OP_SZ_B;
            dec.memOp.signExtend = '1;
          end
          Instr::OP_LD_HS: begin
            dec.memOp.sz = Uop::MEM_OP_SZ_H;
            dec.memOp.signExtend = '1;
          end
          default: dec.exValid = '1;
        endcase
      end
      Instr::OP_ST: begin
        dec.fu = Uop::FU_INTALU;
        dec.op.intalu = Uop::INTALU_OP_ADD;
        dec.immValid = 1;
        dec.imm = immS;
        dec.rs1 = enc.s.rs1;
        dec.rs2 = enc.s.rs2;
        dec.memOp.isSt = 1;
        case (enc.s.funct3)
          Instr::OP_ST_B: dec.memOp.sz = Uop::MEM_OP_SZ_B;
          Instr::OP_ST_H: dec.memOp.sz = Uop::MEM_OP_SZ_H;
          Instr::OP_ST_W: dec.memOp.sz = Uop::MEM_OP_SZ_W;
          default: dec.exValid = '1;
        endcase
      end
      default: dec.exValid = '1;
    endcase
  end
endmodule
