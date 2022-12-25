module DecodeStage (
    input logic clk,
    input logic rst,
    input logic u_valid,
    input logic d_rdy,
    input instr_enc_t instr,
    output logic d_valid,
    output logic u_rdy,
    output uop_decode_t uop
);

  always_ff @(posedge clk) begin
    //TODO register access needs to be bypassed!
    if (rst) begin
      d_valid <= 0;
      u_rdy <= 1;
      uop <= 0;
    end else begin
    end
  end

endmodule

