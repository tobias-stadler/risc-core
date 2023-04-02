interface l1cache_mem_if();

  //Request channel
  logic req_valid;
  logic req_ready;
  logic [1:0] req_id;
  logic req_we;
  Mem::lineaddr_t req_addr;
  Mem::line_t req_data;

  //Response channel
  logic resp_valid;
  logic resp_ready;
  logic [1:0] resp_id;
  Mem::line_t resp_data;

  modport Server(
      input req_valid, resp_ready, req_we, req_addr, req_data, req_id,
      output resp_valid, req_ready, resp_data, resp_id
  );

  modport Client(
      output req_valid, resp_ready, req_we, req_addr, req_data, req_id,
      input resp_valid, req_ready, resp_data, resp_id
  );
endinterface
