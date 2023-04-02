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
#include "MemoryControllerSim.h"

int main() {

  using namespace RISCS;
  using R = Reg;

  std::vector<Instr> instrs{
      Add(R::X1, R::X0, 0x40),
      Add(R::X2, R::X0, 0x555),
      Stb(R::X1, 0, R::X2),
      Add(R::X2, R::X2, 1),
      Stb(R::X1, 1, R::X2),
      Add(R::X2, R::X2, 1),
      Stb(R::X1, 2, R::X2),
      Add(R::X2, R::X2, 1),
      Stb(R::X1, 3, R::X2),
      Add(R::X2, R::X2, 1),
      Stw(R::X1, 4, R::X2),
      Nop(),
      Ldw(R::X3, R::X1, 4),
      Nop()
  };

  Verilated::mkdir("trace");

  ClockedTB<VPlaygroundTB> tb("trace/playground.vcd");

  VPlaygroundTB &m = tb.getModel();

  MemoryControllerIf mIf{m.req_valid, m.req_ready, m.req_id,     m.req_we,
                         m.req_addr,  m.req_data,  m.resp_valid, m.resp_ready,
                         m.resp_id,   m.resp_data};

  MemoryControllerSim mem(0, 0xFFFF, mIf, 4);
  tb.registerPeripheral(mem);

  mem.writeLE32(0x40, 0x41424344);

  std::cout << "Running verilated model...\n";
  tb.reset();
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

  std::cout << "Simulation stopped\n";
  return EXIT_SUCCESS;
}
