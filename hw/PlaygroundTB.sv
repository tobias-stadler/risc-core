`include "Instr.sv"
`include "Uop.sv"

module PlaygroundTB (
    input logic clk,
    input logic rst,
    input Uop::fetch_t instr,
    input logic valid
);

  regfile_read_if read0;
  regfile_read_if read1;
  regfile_write_if write0;

  pipeline_if if_fetch;
  pipeline_if if_decode;
  pipeline_if if_exec;
  pipeline_if if_mem;

  Uop::fetch_t instrFetch;
  Uop::decode_t instrDec;
  Uop::execute_t instrExec;
  Uop::memory_t instrMem;

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
      .read1(read1),
      .uopIn(instrFetch),
      .uopOut(instrDec)
  );

  ExecuteStage m_execStage (
      .clk(clk),
      .rst(rst),
      .u(if_decode),
      .d(if_exec),
      .uopIn(instrDec),
      .uopOut(instrExec)
  );

  MemoryStage m_memStage (
      .clk(clk),
      .rst(rst),
      .u(if_exec),
      .d(if_mem),
      .uopIn(instrExec),
      .uopOut(instrMem)
  );

  WriteBackStage m_wbStage (
      .clk(clk),
      .rst(rst),
      .u(if_mem),
      .uopIn(instrMem),
      .write0(write0)
  );

  assign instrFetch = instr;
  assign if_fetch.valid = valid;
endmodule
