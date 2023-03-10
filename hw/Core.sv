module Core (
    input logic clk,
    input logic rst
);

  regfile_read_if read0;
  regfile_read_if read1;
  regfile_read_if write0;

  pipeline_if if_fetch;
  pipeline_if if_decode;
  pipeline_if if_exec;

  RegisterFile m_regFile (
      .clk(clk),
      .rst(rst),
      .read0(read0),
      .read1(read1),
      .write0(write0)
  );

  DecodeStage m_decodeStage (
      .clk(clk),
      .rst(rst),
      .u(if_fetch),
      .d(if_decode),
      .read0(read0),
      .read1(read1)
  );

  ExecuteStage m_execStage (
      .clk(clk),
      .rst(rst),
      .u  (if_decode),
      .d  (if_exec)
  );

endmodule;
