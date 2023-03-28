interface l1cache_mem_if;

  logic req_valid;
  logic req_ready;
  logic req_we;
  Mem::waddr_t req_addr;
  Mem::w_t req_data;

  Mem::w_t resp_data;
  logic resp_ack;

  modport Server(
      input req_valid, req_we, req_addr, req_data,
      output resp_ack, req_ready, resp_data
  );

  modport Client(
      output req_valid, req_we, req_addr, req_data,
      input resp_ack, req_ready, resp_data
  );
endinterface
