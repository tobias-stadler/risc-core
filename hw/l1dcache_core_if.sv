interface l1dcache_core_if;
  logic en;
  logic enW;
  logic [3:0] mask;
  logic kill;
  Uop::waddr_t addr;
  Uop::w_t reqData;
  Uop::w_t respData;
  logic hit;

  modport Server(input en, enW, mask, kill, addr, reqData, output respData, hit);

  modport Client(input respData, hit, output en, enW, mask, kill, addr, reqData);
endinterface
