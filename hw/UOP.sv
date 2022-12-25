package UOP;
  typedef logic [4:0] reg_t;
  typedef logic [31:0] val_t;
  typedef logic [31:0] imm_t;

  typedef enum logic [6:0] {
    OP_ADD,
    OP_ADDI
  } op_t;

  typedef enum logic [1:0] {
    EX_NONE,
    EX_DECODE,
    EX_MEM
  } ex_t;

  typedef struct packed {
    ex_t  ex;
    op_t  op;
    reg_t rd;
    val_t rs1val;
    val_t rs2val;
    imm_t imm;
  } decode_t;

  typedef struct packed {
    ex_t  ex;
    op_t  op;
    reg_t rd;
    reg_t rs1;
    reg_t rs2;
    imm_t imm;
  } dec_t;
endpackage
