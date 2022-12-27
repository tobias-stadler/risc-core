#pragma once

#include <cstdint>
#include <stdexcept>

class RISCSInstr {
public:
  enum class Op {
    INVALID,
    ADD,
    ADDI,
    SUB,
    AND,
    XOR,
  };

  enum class Reg {
    INVALID,
    X0,
    X1,
    X2,
    X3,
    X4,
    X5,
    X6,
    X7,
    X8,
    X9,
    X10,
    X11,
    X12,
    X13,
    X14,
    X15,
    X16,
    X17,
    X18,
    X19,
    X20,
    X21,
    X22,
    X23,
    X24,
    X25,
    X26,
    X27,
    X28,
    X29,
    X30,
    X31
  };

  enum class Cond { Z, NZ, C, NC, S, NS, OF, NOF, LT, LE, GT, GE };

  static constexpr std::uint8_t encodeReg(Reg reg) {
    switch (reg) {
    case Reg::X0:
      return 0;
    case Reg::X1:
      return 1;
    case Reg::X2:
      return 2;
    case Reg::X3:
      return 3;
    case Reg::X4:
      return 4;
    case Reg::X5:
      return 5;
    case Reg::X6:
      return 6;
    case Reg::X7:
      return 7;
    case Reg::X8:
      return 8;
    case Reg::X9:
      return 9;
    case Reg::X10:
      return 10;
    case Reg::X11:
      return 11;
    case Reg::X12:
      return 12;
    case Reg::X13:
      return 13;
    case Reg::X14:
      return 14;
    case Reg::X15:
      return 15;
    case Reg::X16:
      return 16;
    case Reg::X17:
      return 17;
    case Reg::X18:
      return 18;
    case Reg::X19:
      return 19;
    case Reg::X20:
      return 20;
    case Reg::X21:
      return 21;
    case Reg::X22:
      return 22;
    case Reg::X23:
      return 23;
    case Reg::X24:
      return 24;
    case Reg::X25:
      return 25;
    case Reg::X26:
      return 26;
    case Reg::X27:
      return 27;
    case Reg::X28:
      return 28;
    case Reg::X29:
      return 29;
    case Reg::X30:
      return 30;
    case Reg::X31:
      return 31;
    default:
      throw std::invalid_argument("Invalid register cannot be encoded");
    }
  }

  static constexpr std::uint8_t encodeOp(Op op) {
    switch (op) {
    case Op::ADD:
    case Op::SUB:
    case Op::XOR:
    case Op::AND:
      return 0b0110011;
    case Op::ADDI:
      return 0b0010011;
    default:
      throw std::invalid_argument("Invalid operation cannot be encoded");
    }
  }

  static constexpr std::uint8_t encodeArithOp(Op op) {
      switch (op) {
          case Op::ADD:
          case Op::ADDI:
              return 0b000;
          case Op::SUB:
              return 0b001;
          default: throw std::invalid_argument("Non-artihmetic operation cannot be encoded as arithmetic");
      }
  }

  static constexpr std::uint32_t encodeR(std::uint8_t op, std::uint8_t rd, std::uint8_t funct3,
                                         std::uint8_t rs1, std::uint8_t rs2,
                                         std::uint8_t funct7) {
    std::uint32_t instr = (op & nbits(6)) | (rd & nbits(5)) << 7 |
                          (funct3 & nbits(3)) << 12 | (rs1 & nbits(5)) << 15 |
                          (rs2 & nbits(5)) << 20 | (funct7 & nbits(7)) << 25;
    return instr;
  }

  static constexpr std::uint32_t encodeI(std::uint8_t op, std::uint8_t rd, std::uint8_t funct3,
                                         std::uint8_t rs1, std::int32_t imm) {
    std::uint32_t trunc = (imm & ~nbits(12));
    if (trunc != 0 && trunc != ~nbits(12)) {
        throw std::invalid_argument("Immediate would overflow");
    }

    std::uint32_t instr = (op & nbits(6)) | (rd & nbits(5)) << 7 |
                          (funct3 & nbits(3)) << 12 | (rs1 & nbits(5)) << 15 |
                          (imm & nbits(12)) << 20;
    return instr;
  }

  constexpr std::uint32_t encode() {
    std::uint8_t opEnc = encodeOp(op);
    switch (op) {
    case Op::ADD:
      return encodeR(opEnc, encodeReg(rd), encodeArithOp(op), encodeReg(rs1), encodeReg(rs2), 0);
    case Op::ADDI:
      return encodeI(opEnc, encodeReg(rd), encodeArithOp(op), encodeReg(rs1), imm);
    default:
      throw std::invalid_argument("Invalid instruction cannot be encoded");
    }
  }

  constexpr RISCSInstr(Op op, Reg rd, Reg rs1, Reg rs2, std::int32_t imm)
   : op(op), rd(rd), rs1(rs1), rs2(rs2), imm(imm) {}

private:
  Op op;
  Reg rd;
  Reg rs1;
  Reg rs2;
  std::int32_t imm;

  static constexpr std::uint32_t nbits(int n) { return (1U << n) - 1; }
};

class RISCSInstrBuilder {
    public:
    using Reg = RISCSInstr::Reg;
    using Op = RISCSInstr::Op;

    static constexpr RISCSInstr add(Reg rd, Reg rs1, Reg rs2) {
        return RISCSInstr{Op::ADD, rd, rs1, rs2, 0};
    }

    static constexpr RISCSInstr add(Reg rd, Reg rs1, std::int32_t imm) {
        return RISCSInstr{Op::ADDI, rd, rs1, Reg::INVALID, imm};
    }
};
