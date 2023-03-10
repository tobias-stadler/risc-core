interface regfile_write_if();
    Uop::reg_t addr;
    Uop::val_t val;
    logic en;
    modport Server(input en, addr, val);
    modport Client(output en, addr, val);
endinterface
