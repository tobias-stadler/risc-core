`include "Instr.sv"
`include "UOP.sv"

module DecoderTB (
    input logic clk,
    input logic rst,
    input logic[31:0] in,
    output logic[56:0] out
);

import Instr::*;
import UOP::*;

Decoder mDec(in, out);

endmodule
