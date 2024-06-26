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
      /* Euclidean Algorithm */
      Add(R::X10, R::X0, 2 * 3 * 3 * 3),  // X10 = 54
      Add(R::X11, R::X0, 3 * 3 * 3 * 17), // X11 = 459

      // loopentry:
      Br(Cond::JMP, 5), // goto loophdr
      // loopbody:
      Br(Cond::LE, 3),             // if X10 <= X11, goto smaller
      Sub(R::X10, R::X10, R::X11), // X10 -= X11
      Br(Cond::JMP, 2),            // goto loophdr
      // smaller:
      Sub(R::X11, R::X11, R::X10), // X11 -= X10
      // loophdr:
      Sub(R::X0, R::X10, R::X11),
      Br(Cond::NZ, -5), // if X10 != X11, goto loopbody
  };

  Verilated::mkdir("trace");

  ClockedTB<VPlaygroundTB> tb("trace/playground.vcd");

  VPlaygroundTB &m = tb.getModel();

  MemoryControllerIf iMemIf{m.i_req_valid,  m.i_req_ready,  m.i_req_id,
                            m.i_req_we,     m.i_req_addr,   m.i_req_data,
                            m.i_resp_valid, m.i_resp_ready, m.i_resp_id,
                            m.i_resp_data};

  MemoryControllerIf dMemIf{m.d_req_valid,  m.d_req_ready,  m.d_req_id,
                            m.d_req_we,     m.d_req_addr,   m.d_req_data,
                            m.d_resp_valid, m.d_resp_ready, m.d_resp_id,
                            m.d_resp_data};

  MemoryControllerSim dMem(0, 0xFFFF, dMemIf, 4);
  MemoryControllerSim iMem(0, 0xFFFF, iMemIf, 4);

  tb.registerPeripheral(dMem);
  tb.registerPeripheral(iMem);
  size_t iAddr = 0;
  for (const Instr &in : instrs) {
    std::uint32_t inEnc = in.encode();
    std::cout << "Encoded: " << std::hex << inEnc << std::endl;
    iMem.writeLE32(iAddr, inEnc);
    iAddr += 4;
  }

  dMem.writeLE32(0x40, 0x41424344);

  std::cout << "Running verilated model...\n";
  tb.reset();
  tb.runCycles(200);

  std::cout << "Simulation stopped\n";
  return EXIT_SUCCESS;
}
