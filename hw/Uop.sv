package Uop;
  typedef logic [4:0] reg_t;
  typedef logic [29:0] iaddr_t;
  typedef logic [31:0] val_t;
  typedef logic [31:0] imm_t;

  typedef enum logic [2:0] {FU_NONE, FU_INTALU} fu_t;

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

  typedef union packed {intalu_op_t intalu;} fu_op_t;

  typedef enum logic [1:0] {
    EX_NONE,
    EX_DECODE,
    EX_MEM
  } ex_t;

  typedef struct packed {
    iaddr_t pc;
    Instr::enc_t enc;
  } fetch_t;

  typedef struct packed {
    ex_t ex;
    fu_t fu;
    fu_op_t op;
    reg_t rd;
    reg_t rs1;
    val_t rs1val;
    reg_t rs2;
    val_t rs2val;
    logic immValid;
    imm_t imm;
  } decode_t;

  typedef struct packed {
    ex_t  ex;
    reg_t rd;
    val_t rdVal;
    //logic mem;
    //logic memIsSt;
    //logic memMask;
  } execute_t;

  typedef struct packed {
    ex_t  ex;
    reg_t rd;
    val_t rdVal;
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
  } dec_t;

endpackage
