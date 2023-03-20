interface l1dcache_core_if;
  logic en;
  logic enW;
  logic [3:0] mask;
  Mem::waddr_t addr;
  Mem::w_t reqData;
  Mem::w_t respData;
  logic nAck;

  modport Server(input en, enW, mask, addr, reqData, output respData, nAck);

  modport Client(input respData, nAck, output en, enW, mask, addr, reqData);
endinterface
