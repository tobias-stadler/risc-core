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

  using IB = RISCSInstrBuilder;

  std::vector<RISCSInstr> instrs{
      IB::Add(IB::Reg::X12, IB::Reg::X0, -400),
      IB::Shra(IB::Reg::X13, IB::Reg::X12, 2),
      IB::Add(IB::Reg::X11, IB::Reg::X13, 3),
  };
  std::cout << "Running verilated model...\n";

  Verilated::mkdir("trace");

  ClockedTB<VPlaygroundTB> tb("trace/playground.vcd");
  tb.reset();

  VPlaygroundTB &m = tb.getModel();
  for (const RISCSInstr &in : instrs) {
    std::uint32_t inEnc = in.encode();
    std::cout<< std::hex << inEnc << "\n";
    m.instr = inEnc;
    m.valid = 1;
    tb.cycle();
  }
  m.valid = 0;
  tb.runUntil(20);

  std::cout << "Done\n";
  return EXIT_SUCCESS;
}
