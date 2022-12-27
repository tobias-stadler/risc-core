#include <cstdint>
#include <iostream>
#include <memory>

#include <VDecoderTB.h>
#include <memory>
#include <new>
#include <verilated.h>
#include <verilated_vcd_c.h>

#include "Instr.h"

template <typename T>
void cycle(VerilatedContext &vContext, VerilatedVcdC &vVcd, T &vModel) {
  vModel.clk = 0;
  vModel.eval();
  vVcd.dump(vContext.time());

  vContext.timeInc(1);
  vModel.clk = 1;
  vModel.eval();
  vVcd.dump(vContext.time());

  vContext.timeInc(1);
}

int main() {

    using IB = RISCSInstrBuilder;

    std::cout << "Very nice instructions!\n";
    volatile int i = 10;
    std::uint32_t in = IB::add(IB::Reg::X10, IB::Reg::X11, i).encode(); 
    std::cout << std::hex;
    std::cout << in << "\n";
  const int simEnd = 60;
  std::cout << "Running verilated model...\n";

  auto vContext = std::make_unique<VerilatedContext>();
  vContext->traceEverOn(true);
  Verilated::mkdir("trace");

  auto vVcd = std::make_unique<VerilatedVcdC>();

  auto vTB = std::make_unique<VDecoderTB>(vContext.get());
  //vTB->trace(vVcd.get(), 10);

  vVcd->open("trace/main.vcd");

  /*
  vMain->rst = 1;
  cycle(*vContext, *vVcd, *vMain);
  vMain->val = 2;
  vMain->rst = 0;
  cycle(*vContext, *vVcd, *vMain);

  while (!vContext->gotFinish() && vContext->time() < simEnd)
  {
      cycle(*vContext, *vVcd, *vMain);
  }

  */
  vTB->final();
  vVcd->close();

  std::cout << "Done\n";
  return EXIT_SUCCESS;
}
