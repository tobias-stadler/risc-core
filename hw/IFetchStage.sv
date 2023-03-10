module IFetchStage (
    input logic clk,
    input logic rst,
    pipeline_if.Downstream d,
    output Instr::enc_t,
    input logic redirectPCvalid,
    input Uop::val_t redirectPC,
    output Uop::val_t fetchPC,
    input Instr::enc_t fetchInstr
);

  Uop::val_t currPC;

  always_ff @(posedge clk) begin
    if (rst) begin
      currPC <= 0;
    end else begin
      if (redirectPCvalid) begin
        currPC <= redirectPC;
      end else if (!d.stall) begin
        currPC <= currPC + 4;
      end
    end
  end

endmodule
