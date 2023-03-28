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

  //l1dcache_core_if if_l1dStq;
  l1dcache_core_if if_stqCore;
  l1cache_mem_if if_dBus;

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

  L1DCache m_l1dCache (
      .clk (clk),
      .rst (rst),
      .core(if_stqCore),
      .bus(if_dBus)
  );

  /*
  StoreQueue m_stq (
      .clk  (clk),
      .rst  (rst),
      .core (if_stqCore),
      .cache(if_l1dStq)
  );
  */

  DecodeStage m_decodeStage (
      .clk(clk),
      .rst(rst | flush),
      .u(if_fetch),
      .d(if_decode),
      .read0(read0),
      .read1(read1),
      .uopIn(instrFetch),
      .uopOut(instrDec)
  );

  ExecuteStage m_execStage (
      .clk(clk),
      .rst(rst | flush),
      .u(if_decode),
      .d(if_exec),
      .uopIn(instrDec),
      .uopOut(instrExec),
      .memBypass(if_memBypass),
      .wbBypass(if_wbBypass)
  );

  MemoryStage m_memStage (
      .clk(clk),
      .rst(rst | flush),
      .u(if_exec),
      .d(if_mem),
      .uopIn(instrExec),
      .uopOut(instrMem),
      .bypass(if_memBypass),
      .cache(if_stqCore)
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


  assign if_dBus.resp_ack = 0;
  assign if_dBus.resp_data = 0;
  assign if_dBus.req_ready = 0;
  wire _unused_ok = &{1'b0,if_dBus.req_valid,if_dBus.req_we,if_dBus.req_data,if_dBus.req_addr};

endmodule
