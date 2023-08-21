`include "Instr.sv"
`include "Uop.sv"
`include "Mem.sv"

module PlaygroundTB (
    input logic clk,
    input logic rst,

    output logic d_req_valid,
    input logic d_req_ready,
    output logic [1:0] d_req_id,
    output logic d_req_we,
    output Mem::lineaddr_t d_req_addr,
    output Mem::line_t d_req_data,

    input logic d_resp_valid,
    output logic d_resp_ready,
    input logic [1:0] d_resp_id,
    input Mem::line_t d_resp_data,

    output logic i_req_valid,
    input logic i_req_ready,
    output logic [1:0] i_req_id,
    output logic i_req_we,
    output Mem::lineaddr_t i_req_addr,
    output Mem::line_t i_req_data,

    input logic i_resp_valid,
    output logic i_resp_ready,
    input logic [1:0] i_resp_id,
    input Mem::line_t i_resp_data
);

  pipeline_if if_fetch ();
  pipeline_if if_decode ();
  pipeline_if if_exec ();
  pipeline_if if_mem ();

  regfile_read_if read0 ();
  regfile_read_if read1 ();
  regfile_write_if write0 ();

  bypass_if if_memBypass ();
  bypass_if if_wbBypass ();

  l1dcache_core_if if_l1dStq ();
  l1dcache_core_if if_stqCore ();
  l1cache_mem_if if_dBus ();

  l1icache_core_if if_l1iCore ();
  l1cache_mem_if if_iBus ();

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

  L1ICache m_l1iCache (
      .clk (clk),
      .rst (rst),
      .core(if_l1iCore),
      .bus (if_iBus)
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

  IFetchStage m_fetchStage (
      .clk(clk),
      .rst(rst),
      .d(if_fetch),
      .uopOut(instrFetch),
      .cache(if_l1iCore)
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

  assign d_req_valid = if_dBus.req_valid;
  assign d_req_we = if_dBus.req_we;
  assign d_req_id = if_dBus.req_id;
  assign d_req_addr = if_dBus.req_addr;
  assign d_req_data = if_dBus.req_data;
  assign if_dBus.req_ready = d_req_ready;

  assign d_resp_ready = if_dBus.resp_ready;
  assign if_dBus.resp_valid = d_resp_valid;
  assign if_dBus.resp_data = d_resp_data;
  assign if_dBus.resp_id = d_resp_id;

  assign i_req_valid = if_iBus.req_valid;
  assign i_req_we = if_iBus.req_we;
  assign i_req_id = if_iBus.req_id;
  assign i_req_addr = if_iBus.req_addr;
  assign i_req_data = if_iBus.req_data;
  assign if_iBus.req_ready = i_req_ready;

  assign i_resp_ready = if_iBus.resp_ready;
  assign if_iBus.resp_valid = i_resp_valid;
  assign if_iBus.resp_data = i_resp_data;
  assign if_iBus.resp_id = i_resp_id;
endmodule
