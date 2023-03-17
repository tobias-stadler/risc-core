interface bypass_if;
    logic rValid;
    Uop::reg_t r;
    Uop::val_t rVal;
    logic flagsValid;
    Uop::flags_t flags;

    modport Observer (
        input rValid, r, rVal, flagsValid, flags
    );

    modport Subject (
        output rValid, r, rVal, flagsValid, flags
    );
endinterface
