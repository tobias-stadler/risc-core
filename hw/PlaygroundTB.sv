`include "Instr.sv"
`include "Uop.sv"
`include "Mem.sv"

module PlaygroundTB (
    input logic clk,
    input logic rst,
    input Uop::fetch_t instr,
    input logic valid,
    output logic stall
);

  regfile_read_if read0;
  regfile_read_if read1;
  regfile_write_if write0;

  pipeline_if if_fetch;
  pipeline_if if_decode;
  pipeline_if if_exec;
  pipeline_if if_mem;

  bypass_if if_memBypass;
  bypass_if if_wbBypass;

  l1dcache_core_if if_l1dCore;

  Uop::fetch_t instrFetch;
  Uop::decode_t instrDec;
  Uop::execute_t instrExec;
  Uop::memory_t instrMem;

  logic flush;

  RegisterFile m_regFile (
      .clk(clk),
      .rst(rst),
      .read0(read0),
      .read1(read1),
      .write0(write0)
  );

  L1DCache m_l1dcache (
      .clk (clk),
      .rst (rst),
      .core(if_l1dCore)
  );

  DecodeStage m_decodeStage (
      .clk(clk),
      .rst(rst|flush),
      .u(if_fetch),
      .d(if_decode),
      .read0(read0),
      .read1(read1),
      .uopIn(instrFetch),
      .uopOut(instrDec)
  );

  ExecuteStage m_execStage (
      .clk(clk),
      .rst(rst|flush),
      .u(if_decode),
      .d(if_exec),
      .uopIn(instrDec),
      .uopOut(instrExec),
      .memBypass(if_memBypass),
      .wbBypass(if_wbBypass)
  );

  MemoryStage m_memStage (
      .clk(clk),
      .rst(rst|flush),
      .u(if_exec),
      .d(if_mem),
      .uopIn(instrExec),
      .uopOut(instrMem),
      .bypass(if_memBypass),
      .cache(if_l1dCore)
  );

  WriteBackStage m_wbStage (
      .clk(clk),
      .rst(rst),
      .u(if_mem),
      .uopIn(instrMem),
      .write0(write0),
      .bypass(if_wbBypass),
      .flush(flush)
  );

  assign instrFetch = instr;
  assign if_fetch.valid = valid;
  assign stall = if_fetch.stall;
endmodule
