
module IntALU (
    input Uop::intalu_op_t op,
    input Uop::val_t s1,
    input Uop::val_t s2,
    output Uop::val_t d
);

import Uop::*;

always_comb begin
    case (op)
        INTALU_OP_ADD: d = $signed(s1) + $signed(s2);
        INTALU_OP_SUB: d = $signed(s1) - $signed(s2);
        INTALU_OP_AND: d = s1 & s2;
        INTALU_OP_OR: d = s1 | s2;
        INTALU_OP_XOR: d = s1 ^ s2;
        INTALU_OP_SHL: d = s1 << s2;
        INTALU_OP_SHR: d = s1 >> s2;
        INTALU_OP_SHRA: d = $signed(s1) >>> s2;
        default: d = 'x;
    endcase
end

endmodule
