module Core (
    input logic clk,
    input logic rst,
    input Uop::fetch_t instr,
    input logic valid,
    output logic stall,

    output logic req_valid,
    input logic req_ready,
    output logic [1:0] req_id,
    output logic req_we,
    output Mem::lineaddr_t req_addr,
    output Mem::line_t req_data,

    input logic resp_valid,
    output logic resp_ready,
    input logic [1:0] resp_id,
    input Mem::line_t resp_data
);

  pipeline_if if_fetch();
  pipeline_if if_decode();
  pipeline_if if_exec();
  pipeline_if if_mem();

  regfile_read_if read0();
  regfile_read_if read1();
  regfile_write_if write0();

  bypass_if if_memBypass();
  bypass_if if_wbBypass();

  l1dcache_core_if if_l1dStq();
  l1dcache_core_if if_stqCore();
  l1cache_mem_if if_dBus();

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
      .core(if_l1dStq),
      .bus (if_dBus)
  );

  StoreQueue m_stq (
      .clk  (clk),
      .rst  (rst),
      .core (if_stqCore),
      .cache(if_l1dStq)
  );

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

  assign req_valid = if_dBus.req_valid;
  assign req_we = if_dBus.req_we;
  assign req_id = if_dBus.req_id;
  assign req_addr = if_dBus.req_addr;
  assign req_data = if_dBus.req_data;
  assign if_dBus.req_ready = req_ready;

  assign resp_ready = if_dBus.resp_ready;
  assign if_dBus.resp_valid = resp_valid;
  assign if_dBus.resp_data = resp_data;
  assign if_dBus.resp_id = resp_id;
endmodule
