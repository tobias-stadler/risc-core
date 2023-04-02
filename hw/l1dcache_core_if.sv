interface l1dcache_core_if();
  logic req_valid;
  logic req_we;
  logic [3:0] req_mask;
  Mem::waddr_t req_addr;
  Mem::w_t req_data;

  Mem::w_t resp_data;
  logic resp_ack;

  modport Server(input req_valid, req_we, req_mask, req_addr, req_data, output resp_data, resp_ack);

  modport Client(output req_valid, req_we, req_mask, req_addr, req_data, input resp_data, resp_ack);
endinterface
