interface l1icache_core_if ();
  logic req_valid;
  logic req_ready;
  Mem::lineaddr_t req_addr;

  logic resp_valid;
  Mem::line_t resp_data;

  modport Server(
      input req_valid, req_addr,
      output resp_data, resp_valid, req_ready
  );

  modport Client(
      output req_valid,  req_addr,
      input resp_data, resp_valid, req_ready
  );
endinterface
