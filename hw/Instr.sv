package Instr;
  typedef logic [4:0] reg_t;
  typedef logic [4:0] cond_t;

  typedef logic [2:0] funct3_t;
  typedef logic [6:0] funct7_t;

  typedef logic [11:0] imm_i_t;
  typedef logic [19:0] imm_u_t;
  typedef logic [4:0] imm_s5_t;
  typedef logic [6:0] imm_s7_t;

  typedef enum logic [6:0] {
    OP_NOP = 7'b0000000,
    OP_ARITH = 7'b0110011,  // Standard enc: R, Non standard minor ops
    OP_ARITHI = 7'b0010011,  // Standard enc: I, Non standard minor ops
    OP_LDUI = 7'b0110111,  // Standard, enc: U
    OP_LDUIPC = 7'b0010111,  // Standard, enc: U
    OP_LD = 7'b0000011,  // Standard, enc: I
    OP_ST = 7'b0100011,  // Standard, enc: S
    OP_JAL = 7'b1101111,  // Non standard, enc: U
    OP_JALR = 7'b1100111,  // Standard, enc: I
    OP_BR = 7'b1100011,  // Completely non standard, enc: CU
    OP_BRR = 7'b1101011  // Completely non standard, enc: CI
  } op_t;

  typedef enum funct3_t {
    OP_ARITH_ADD  = 3'b000,
    OP_ARITH_SUB  = 3'b001,
    OP_ARITH_OR   = 3'b010,
    OP_ARITH_AND  = 3'b011,
    OP_ARITH_XOR  = 3'b100,
    OP_ARITH_SHL  = 3'b101,
    OP_ARITH_SHR  = 3'b110,
    OP_ARITH_SHRA = 3'b111
  } op_arith_t;

  typedef enum funct3_t {
    OP_LD_B  = 3'b000,
    OP_LD_H  = 3'b001,
    OP_LD_W  = 3'b010,
    OP_LD_BS = 3'b100,
    OP_LD_HS = 3'b101
  } op_ld_t;

  typedef enum funct3_t {
    OP_ST_B = 3'b000,
    OP_ST_H = 3'b001,
    OP_ST_W = 3'b010
  } op_st_t;

  typedef struct packed {
    funct7_t funct7;
    reg_t rs2;
    reg_t rs1;
    funct3_t funct3;
    reg_t rd;
    op_t op;
  } enc_r_t;

  typedef struct packed {
    imm_s7_t imm7;
    reg_t rs2;
    reg_t rs1;
    imm_s5_t imm5;
    op_t op;
  } enc_s_t;

  typedef struct packed {
    imm_i_t imm;
    reg_t rs1;
    funct3_t funct3;
    reg_t rd;
    op_t op;
  } enc_i_t;

  typedef struct packed {
    imm_i_t imm;
    reg_t rs1;
    funct3_t funct3;
    cond_t cond;
    op_t op;
  } enc_ci_t;

  typedef struct packed {
    imm_u_t imm;
    reg_t rd;
    op_t op;
  } enc_u_t;

  typedef struct packed {
    imm_u_t imm;
    cond_t cond;
    op_t op;
  } enc_cu_t;

  typedef struct packed {
    logic [31:7] rest;
    op_t   op;
  } enc_op_t;

  typedef union packed {
    enc_r_t  r;
    enc_i_t  i;
    enc_u_t  u;
    enc_s_t  s;
    enc_op_t op;
    logic [31:0]   raw;
  } enc_t;
endpackage
