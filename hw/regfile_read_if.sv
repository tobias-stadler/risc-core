interface regfile_read_if();
    Uop::reg_t addr;
    Uop::val_t val;
    modport Server(input addr, output val);
    modport Client(input val, output addr);
endinterface
