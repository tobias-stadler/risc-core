This repository contains a custom 32-bit RISC CPU core written in SystemVerilog.

The implemented instruction set is a heavily modified subset of RV32I that uses an ISA-visible flags register (Zero, Sign, Carry, Overflow) for conditions instead of RISC-V's comparison-based branches.

Main characteristics of the microarchitecture:
- classic 5-stage in-order RISC pipeline 
- blocking set-associative instruction cache
- non-blocking (line-fill buffer based) set-associative data cache
- store queue with support for store-forwarding
- full bypassing of uncommitted register/flags state into the execute stage (ALU throughput of 1)
- all branches are currently "predicted" not-taken with a mispredict penalty of 3 cycles

# Example
Instructions can be assembled using C++ helper methods.
```c++
{
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
}
```
Running the above program results in the following trace. The trace shows when valid micro-ops are in certain pipeline stages, when IFetch is redirected because of branch misses, as well as the committed register state for registers X10 and X11. The first few instructions incur additional latency due to instruction cache misses.
![Screenshot 2024-06-26 at 02 45 49](https://github.com/tobias-stadler/risc-core/assets/96086497/3fffcd7e-4064-4d96-9b06-f0e2fe47acf8)
# Info
Verilator is used for simulation and currently the memory controller/bus is simulated using C++.
The implementation is synthesizable by Xilinx Vivado and where possible memories have been designed such that they infer BlockRAM on Xilinx devices. 
However, due to the current lack of a proper memory controller (or other peripherals), the implementation has not yet been tested on FPGA.
