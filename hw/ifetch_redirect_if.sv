interface ifetch_redirect_if ();
  logic valid;
  Uop::iaddr_t pc;

  modport Client(output valid, pc);

  modport Server(input valid, pc);
endinterface
