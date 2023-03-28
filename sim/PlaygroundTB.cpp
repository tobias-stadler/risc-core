#include <algorithm>
#include <cstdint>
#include <iostream>
#include <memory>

#include "ClockedTestbench.h"
#include <VPlaygroundTB.h>
#include <memory>
#include <new>
#include <vector>
#include <verilated.h>
#include <verilated_vcd_c.h>

#include "Instr.h"

int main() {

  using namespace RISCS;
  using R = Reg;

  std::vector<Instr> instrs{
      Add(R::X1, R::X0, 0x40),
      Add(R::X2, R::X0, 0x550),
      Stw(R::X1, 4, R::X2),
      Stw(R::X1, 4, R::X2),
      Stb(R::X1, 4, R::X2),
  };
  std::cout << "Running verilated model...\n";

  Verilated::mkdir("trace");

  ClockedTB<VPlaygroundTB> tb("trace/playground.vcd");
  tb.reset();

  VPlaygroundTB &m = tb.getModel();
  for (const Instr &in : instrs) {
    std::uint32_t inEnc = in.encode();
    std::cout << std::hex << inEnc << std::endl;
    while (m.stall) {
      tb.cycle();
      std::cout << "stalled" << std::endl;
    }
    m.instr = inEnc;
    m.valid = 1;
    tb.cycle();
  }
  m.valid = 0;
  tb.runUntil(100);

  std::cout << "Done\n";
  return EXIT_SUCCESS;
}
