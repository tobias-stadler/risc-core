interface l1dcache_core_if;
  logic en;
  logic enW;
  logic [3:0] mask;
  Uop::waddr_t addr;
  Uop::w_t reqData;
  Uop::w_t respData;
  logic nack;

  modport Server(input en, enW, mask, addr, reqData, output respData, nack);

  modport Client(input respData, nack, output en, enW, mask, addr, reqData);
endinterface
