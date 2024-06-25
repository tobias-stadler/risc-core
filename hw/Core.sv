module Core (
    input logic clk,
    input logic rst,
    l1cache_mem_if.Client iBus,
    l1cache_mem_if.Client dBus
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

  l1icache_core_if if_l1iCore ();

  Uop::fetch_t instrFetch;
  Uop::decode_t instrDec;
  Uop::execute_t instrExec;
  Uop::memory_t instrMem;

  Uop::redirect_pc_t redirect;
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
      .bus (iBus)
  );

  L1DCache m_l1dCache (
      .clk (clk),
      .rst (rst),
      .core(if_l1dStq),
      .bus (dBus)
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
      .cache(if_l1iCore),
      .redirect(redirect)
  );

  DecodeStage m_decodeStage (
      .clk(clk),
      .rst(rst | flush | redirect.valid),
      .u(if_fetch),
      .d(if_decode),
      .read0(read0),
      .read1(read1),
      .uopIn(instrFetch),
      .uopOut(instrDec)
  );

  ExecuteStage m_execStage (
      .clk(clk),
      .rst(rst | flush | redirect.valid),
      .u(if_decode),
      .d(if_exec),
      .uopIn(instrDec),
      .uopOut(instrExec),
      .memBypass(if_memBypass),
      .wbBypass(if_wbBypass),
      .redirect(redirect)
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
endmodule
