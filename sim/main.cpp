#include <cstdint>
#include <iostream>
#include <memory.h>

#include "Vmain.h"
#include <memory>
#include <verilated.h>
#include <verilated_vcd_c.h>

template <typename T> void cycle(VerilatedContext &vContext, VerilatedVcdC &vVcd, T &vModel)
{
    vModel.clk = 0;
    vModel.eval();
    vVcd.dump(vContext.time());

    vContext.timeInc(1);
    vModel.clk = 1;
    vModel.eval();
    vVcd.dump(vContext.time());

    vContext.timeInc(1);
}

int main()
{
    const int simEnd = 60;
    std::cout << "Running verilated model...\n";

    auto vContext = std::make_unique<VerilatedContext>();
    vContext->traceEverOn(true);
    Verilated::mkdir("trace");

    auto vVcd = std::make_unique<VerilatedVcdC>();

    auto vMain = std::make_unique<Vmain>(vContext.get());
    vMain->trace(vVcd.get(), 10);

    vVcd->open("trace/main.vcd");

    vMain->rst = 1;
    cycle(*vContext, *vVcd, *vMain);
    vMain->val = 2;
    vMain->rst = 0;
    cycle(*vContext, *vVcd, *vMain);

    while (!vContext->gotFinish() && vContext->time() < simEnd)
    {
        cycle(*vContext, *vVcd, *vMain);
    }

    vMain->final();
    vVcd->close();

    std::cout << "Done\n";
    return EXIT_SUCCESS;
}
