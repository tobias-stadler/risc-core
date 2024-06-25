#pragma once

#include <bitset>
#include <cstdint>
#include <exception>
#include <iostream>
#include <optional>
#include <stdexcept>

namespace RISCS {
class encoding_error : public std::runtime_error {
  using std::runtime_error::runtime_error;
};

enum class Op {
  INVALID,
  NOP,
  ADD,
  ADDI,
  SUB,
  SUBI,
  OR,
  ORI,
  AND,
  ANDI,
  XOR,
  XORI,
  SHL,
  SHLI,
  SHR,
  SHRI,
  SHRA,
  SHRAI,
  LDB,
  LDH,
  LDW,
  LDBS,
  LDHS,
  STB,
  STH,
  STW,
  BR,
};

enum class Cond { Z, NZ, S, NS, C, NC, V, NV, LT, LE, GT, GE, JMP };

enum class Reg {
  NONE,
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

class Instr {
public:
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
      throw encoding_error("Invalid register cannot be encoded");
    }
  }

  static constexpr std::uint8_t encodeOp(Op op) {
    switch (op) {
    case Op::NOP:
      return 0b0000000;
    case Op::ADD:
    case Op::SUB:
    case Op::OR:
    case Op::AND:
    case Op::XOR:
    case Op::SHL:
    case Op::SHR:
    case Op::SHRA:
      return 0b0110011;
    case Op::ADDI:
    case Op::SUBI:
    case Op::ORI:
    case Op::ANDI:
    case Op::XORI:
    case Op::SHLI:
    case Op::SHRI:
    case Op::SHRAI:
      return 0b0010011;
    case Op::LDB:
    case Op::LDH:
    case Op::LDW:
    case Op::LDBS:
    case Op::LDHS:
      return 0b0000011;
    case Op::STB:
    case Op::STH:
    case Op::STW:
      return 0b0100011;
    case Op::BR:
      return 0b1100011;
    default:
      throw encoding_error("Invalid operation cannot be encoded");
    }
  }

  static constexpr std::uint8_t encodeLdOp(Op op) {
    switch (op) {

    case Op::LDB:
      return 0b000;
    case Op::LDH:
      return 0b001;
    case Op::LDW:
      return 0b010;
    case Op::LDBS:
      return 0b100;
    case Op::LDHS:
      return 0b101;
    default:
      throw encoding_error("Non-load operation cannot be encoded as load");
    }
  }

  static constexpr std::uint8_t encodeStOp(Op op) {
    switch (op) {
    case Op::STB:
      return 0b000;
    case Op::STH:
      return 0b001;
    case Op::STW:
      return 0b010;
    default:
      throw encoding_error("Non-store operation cannot be encoded as store");
    }
  }

  static constexpr std::uint8_t encodeCond(Cond cond) {
    switch (cond) {
    case Cond::Z:
      return 0;
    case Cond::NZ:
      return 1;
    case Cond::S:
      return 2;
    case Cond::NS:
      return 3;
    case Cond::C:
      return 4;
    case Cond::NC:
      return 5;
    case Cond::V:
      return 6;
    case Cond::NV:
      return 7;
    case Cond::LT:
      return 8;
    case Cond::LE:
      return 9;
    case Cond::GT:
      return 10;
    case Cond::GE:
      return 11;
    case Cond::JMP:
      return 12;
    default:
      throw encoding_error("Non-store operation cannot be encoded as store");
    }
  }

  static constexpr std::uint8_t encodeArithOp(Op op) {
    switch (op) {
    case Op::ADD:
    case Op::ADDI:
      return 0b000;
    case Op::SUB:
    case Op::SUBI:
      return 0b001;
    case Op::OR:
    case Op::ORI:
      return 0b010;
    case Op::AND:
    case Op::ANDI:
      return 0b011;
    case Op::XOR:
    case Op::XORI:
      return 0b100;
    case Op::SHL:
    case Op::SHLI:
      return 0b101;
    case Op::SHR:
    case Op::SHRI:
      return 0b110;
    case Op::SHRA:
    case Op::SHRAI:
      return 0b111;
    default:
      throw encoding_error(
          "Non-artihmetic operation cannot be encoded as arithmetic");
    }
  }

  static constexpr std::uint32_t encodeR(std::uint8_t op, std::uint8_t rd,
                                         std::uint8_t funct3, std::uint8_t rs1,
                                         std::uint8_t rs2,
                                         std::uint8_t funct7) {
    std::uint32_t instr = (op & nbits(7)) | (rd & nbits(5)) << 7 |
                          (funct3 & nbits(3)) << 12 | (rs1 & nbits(5)) << 15 |
                          (rs2 & nbits(5)) << 20 | (funct7 & nbits(7)) << 25;
    return instr;
  }

  static constexpr std::uint32_t encodeI(std::uint8_t op, std::uint8_t rd,
                                         std::uint8_t funct3, std::uint8_t rs1,
                                         std::int32_t imm) {
    if (!truncateable(imm, 12)) {
      throw encoding_error("Immediate would overflow");
    }

    std::uint32_t instr = (op & nbits(7)) | (rd & nbits(5)) << 7 |
                          (funct3 & nbits(3)) << 12 | (rs1 & nbits(5)) << 15 |
                          (imm & nbits(12)) << 20;
    return instr;
  }

  static constexpr std::uint32_t encodeS(std::uint8_t op, std::uint8_t funct3,
                                         std::uint8_t rs1, std::uint8_t rs2,
                                         std::int32_t imm) {
    if (!truncateable(imm, 12)) {
      throw encoding_error("Immediate would overflow");
    }

    std::uint32_t instr = (op & nbits(7)) | (imm & nbits(5)) << 7 |
                          (funct3 & nbits(3)) << 12 | (rs1 & nbits(5)) << 15 |
                          (rs2 & nbits(5)) << 20 |
                          ((imm >> 5) & nbits(7)) << 25;
    return instr;
  }

  static constexpr std::uint32_t encodeU(std::uint8_t op, std::uint8_t rs1,
                                         std::int32_t imm) {
    if (!truncateable(imm, 20)) {
      throw encoding_error("Immediate would overflow");
    }

    std::uint32_t instr =
        (op & nbits(7)) | (rs1 & nbits(5)) << 7 | (imm & nbits(20)) << 12;
    return instr;
  }

  constexpr std::uint32_t encode() const {
    std::uint8_t opEnc = encodeOp(op);
    switch (op) {
    case Op::NOP:
      return encodeR(opEnc, 0, 0, 0, 0, 0);
    case Op::ADD:
    case Op::SUB:
    case Op::OR:
    case Op::AND:
    case Op::XOR:
    case Op::SHL:
    case Op::SHR:
    case Op::SHRA:
      return encodeR(opEnc, encodeReg(rd), encodeArithOp(op), encodeReg(rs1),
                     encodeReg(rs2), 0);
    case Op::ADDI:
    case Op::SUBI:
    case Op::ORI:
    case Op::ANDI:
    case Op::XORI:
    case Op::SHLI:
    case Op::SHRI:
    case Op::SHRAI:
      return encodeI(opEnc, encodeReg(rd), encodeArithOp(op), encodeReg(rs1),
                     imm.value());
    case Op::LDB:
    case Op::LDH:
    case Op::LDW:
    case Op::LDBS:
    case Op::LDHS:
      return encodeI(opEnc, encodeReg(rd), encodeLdOp(op), encodeReg(rs1),
                     imm.value());
    case Op::STB:
    case Op::STH:
    case Op::STW:
      return encodeS(opEnc, encodeStOp(op), encodeReg(rs1), encodeReg(rs2),
                     imm.value());
    case Op::BR:
      return encodeU(opEnc, encodeCond(cond.value()), imm.value());
    default:
      throw encoding_error("Invalid opcode cannot be encoded");
    }
  }

  constexpr Instr(Op op, Reg rd, Reg rs1, Reg rs2,
                  std::optional<std::int32_t> imm)
      : op(op), rd(rd), rs1(rs1), rs2(rs2), imm(imm) {}

  constexpr Instr(Op op, Reg rd, Reg rs1, Reg rs2)
      : op(op), rd(rd), rs1(rs1), rs2(rs2), imm({}) {}

  constexpr Instr(Op op, Reg rd, Reg rs1, std::int32_t imm)
      : op(op), rd(rd), rs1(rs1), rs2(Reg::NONE), imm({imm}) {}

  constexpr Instr(Op op, Cond cond, std::int32_t imm)
      : op(op), rd(Reg::NONE), rs1(Reg::NONE), rs2(Reg::NONE), imm({imm}),
        cond({cond}) {}

private:
  Op op;
  Reg rd;
  Reg rs1;
  Reg rs2;
  std::optional<std::int32_t> imm;
  std::optional<Cond> cond;

  static constexpr std::uint32_t nbits(int n) { return (1U << n) - 1; }

  static constexpr bool truncateable(std::int32_t v, int n) {
    if (n < 1)
      throw std::invalid_argument("Number of remaining bits must be >= 1");
    std::uint32_t trunc = (v & ~nbits(n - 1));
    return trunc == 0 || trunc == ~nbits(n - 1);
  }
};

constexpr Instr Nop() {
  return Instr{Op::NOP, Reg::NONE, Reg::NONE, Reg::NONE};
}

constexpr Instr Add(Reg rd, Reg rs1, Reg rs2) {
  return Instr{Op::ADD, rd, rs1, rs2};
}

constexpr Instr Add(Reg rd, Reg rs1, std::int32_t imm) {
  return Instr{Op::ADDI, rd, rs1, imm};
}

constexpr Instr Sub(Reg rd, Reg rs1, Reg rs2) {
  return Instr{Op::SUB, rd, rs1, rs2};
}

constexpr Instr Sub(Reg rd, Reg rs1, std::int32_t imm) {
  return Instr{Op::SUBI, rd, rs1, imm};
}

constexpr Instr Or(Reg rd, Reg rs1, Reg rs2) {
  return Instr{Op::OR, rd, rs1, rs2};
}

constexpr Instr Or(Reg rd, Reg rs1, std::int32_t imm) {
  return Instr{Op::ORI, rd, rs1, imm};
}

constexpr Instr And(Reg rd, Reg rs1, Reg rs2) {
  return Instr{Op::AND, rd, rs1, rs2};
}

constexpr Instr And(Reg rd, Reg rs1, std::int32_t imm) {
  return Instr{Op::ANDI, rd, rs1, imm};
}

constexpr Instr Xor(Reg rd, Reg rs1, Reg rs2) {
  return Instr{Op::XOR, rd, rs1, rs2};
}

constexpr Instr Xor(Reg rd, Reg rs1, std::int32_t imm) {
  return Instr{Op::XORI, rd, rs1, imm};
}

constexpr Instr Shl(Reg rd, Reg rs1, Reg rs2) {
  return Instr{Op::SHL, rd, rs1, rs2};
}

constexpr Instr Shl(Reg rd, Reg rs1, std::int32_t imm) {
  return Instr{Op::SHLI, rd, rs1, imm};
}

constexpr Instr Shr(Reg rd, Reg rs1, Reg rs2) {
  return Instr{Op::SHR, rd, rs1, rs2};
}

constexpr Instr Shr(Reg rd, Reg rs1, std::int32_t imm) {
  return Instr{Op::SHRI, rd, rs1, imm};
}

constexpr Instr Shra(Reg rd, Reg rs1, Reg rs2) {
  return Instr{Op::SHRA, rd, rs1, rs2};
}

constexpr Instr Shra(Reg rd, Reg rs1, std::int32_t imm) {
  return Instr{Op::SHRAI, rd, rs1, imm};
}

constexpr Instr Ldb(Reg rd, Reg base, std::int32_t offset) {
  return Instr{Op::LDB, rd, base, offset};
}

constexpr Instr Ldh(Reg rd, Reg base, std::int32_t offset) {
  return Instr{Op::LDH, rd, base, offset};
}

constexpr Instr Ldw(Reg rd, Reg base, std::int32_t offset) {
  return Instr{Op::LDW, rd, base, offset};
}

constexpr Instr Ldbs(Reg rd, Reg base, std::int32_t offset) {
  return Instr{Op::LDBS, rd, base, offset};
}

constexpr Instr Ldhs(Reg rd, Reg base, std::int32_t offset) {
  return Instr{Op::LDHS, rd, base, offset};
}

constexpr Instr Stb(Reg base, std::int32_t offset, Reg val) {
  return Instr{Op::STB, Reg::NONE, base, val, offset};
}

constexpr Instr Sth(Reg base, std::int32_t offset, Reg val) {
  return Instr{Op::STH, Reg::NONE, base, val, offset};
}

constexpr Instr Stw(Reg base, std::int32_t offset, Reg val) {
  return Instr{Op::STW, Reg::NONE, base, val, offset};
}

constexpr Instr Br(Cond cond, std::int32_t offset) {
  return Instr{Op::BR, cond, offset};
}
}; // namespace RISCS
