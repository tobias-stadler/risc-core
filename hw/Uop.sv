package Uop;
  typedef logic [4:0] reg_t;
  typedef logic [29:0] waddr_t;
  typedef logic [30:0] haddr_t;
  typedef logic [31:0] baddr_t;
  typedef logic [29:0] iaddr_t;
  typedef logic [31:0] val_t;
  typedef logic [31:0] w_t;
  typedef logic [15:0] hw_t;
  typedef logic [7:0] b_t;
  typedef logic [31:0] imm_t;

  typedef enum logic [2:0] {
    FU_NONE,
    FU_INTALU
  } fu_t;

  typedef struct packed {
    logic v;
    logic c;
    logic s;
    logic z;
  } flags_t;

  typedef enum logic [2:0] {
    INTALU_OP_ADD,
    INTALU_OP_SUB,
    INTALU_OP_AND,
    INTALU_OP_OR,
    INTALU_OP_XOR,
    INTALU_OP_SHL,
    INTALU_OP_SHR,
    INTALU_OP_SHRA
  } intalu_op_t;

  /*
  typedef enum logic [5:0] {
    MEM_NONE = 5'b00000,
    MEM_STW = 5'b11000,
    MEM_STHW = 5'b10100,
    MEM_STB = 5'b10010,
    MEM_LDW = 5'b01000,
    MEM_LDHW = 5'b00100,
    MEM_LDB = 5'b00010,
    MEM_LDHW_SIGNED = 5'b00101,
    MEM_LDB_SIGNED = 5'b00011
  } mem_op_e;
  */

  typedef enum logic [1:0] {
    MEM_OP_SZ_B,
    MEM_OP_SZ_H,
    MEM_OP_SZ_W
  } mem_op_sz_t;

  typedef struct packed {
    logic en;
    logic isSt;
    logic signExtend;
    mem_op_sz_t sz;
  } mem_op_t;

  typedef union packed {intalu_op_t intalu;} fu_op_t;

  typedef enum logic [1:0] {
    EX_NONE,
    EX_DECODE,
    EX_MEM_MISS,
    EX_MEM_ALIGN
  } ex_t;

  typedef struct packed {
    logic br;
    logic brTaken;
    Instr::enc_t enc;
  } fetch_t;

  typedef struct packed {
    ex_t ex;
    fu_t fu;
    fu_op_t op;
    reg_t rd;
    reg_t rs1;
    val_t rs1Val;
    reg_t rs2;
    val_t rs2Val;
    logic immValid;
    imm_t imm;
    mem_op_t memOp;
    logic flagsValid;
  } decode_t;

  typedef struct packed {
    ex_t ex;
    reg_t rd;
    val_t rdVal;
    val_t rs2Val;
    mem_op_t memOp;
    logic flagsValid;
    flags_t flags;
  } execute_t;

  typedef struct packed {
    ex_t  ex;
    reg_t rd;
    val_t rdVal;
    logic flagsValid;
    flags_t flags;
  } memory_t;

  typedef struct packed {
    ex_t ex;
    fu_t fu;
    fu_op_t op;
    reg_t rd;
    reg_t rs1;
    reg_t rs2;
    logic immValid;
    imm_t imm;
    mem_op_t memOp;
    logic flagsValid;
  } dec_t;

endpackage
