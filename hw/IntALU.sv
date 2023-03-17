module IntALU (
    input Uop::intalu_op_t op,
    input Uop::val_t s1,
    input Uop::val_t s2,
    output Uop::val_t d,
    output Uop::flags_t flags
);

  import Uop::*;

  logic z, s, c, v;

  localparam int MSB = 30;

  always_comb begin
    case (op)
      INTALU_OP_ADD: begin
        {c, d} = s1 + s2;
        v = (s1[MSB] & s2[MSB] & ~d[MSB]) | (~s1[MSB] & ~s2[MSB] & d[MSB]);
      end
      INTALU_OP_SUB: begin
        {c, d} = s1 - s2;
        v = (~s1[MSB] & s2[MSB] & d[MSB]) | (s1[MSB] & ~s2[MSB] & ~d[MSB]);
      end
      INTALU_OP_AND: begin
        d = s1 & s2;
        c = 0;
        v = 0;
      end
      INTALU_OP_OR: begin
        d = s1 | s2;
        c = 0;
        v = 0;
      end
      INTALU_OP_XOR: begin
        d = s1 ^ s2;
        c = 0;
        v = 0;
      end
      INTALU_OP_SHL: begin
        {c, d} = {1'b0, s1} << s2;
        v = 0;
      end
      INTALU_OP_SHR: begin
        {d, c} = {s1, 1'b0} >> s2;
        v = 0;
      end
      INTALU_OP_SHRA: begin
        {d, c} = {$signed(s1), 1'b0} >>> s2;
        v = 0;
      end
      default: d = 0;
    endcase
    z = (d == 0);
    s = d[MSB];
    flags.v = v;
    flags.c = c;
    flags.s = s;
    flags.z = z;
  end

endmodule
