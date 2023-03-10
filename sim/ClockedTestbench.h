#include <cstdint>
#include <utility>
#include <memory>
#include <new>
#include <string>
#include <verilated.h>
#include <verilated_vcd_c.h>

template <class T> class ClockedTB {

public:
  ClockedTB(std::string traceFileName)
      : traceFileName(std::move(traceFileName)),
        context(std::make_unique<VerilatedContext>()),
        model(std::make_unique<T>(context.get())),
        vcd(std::make_unique<VerilatedVcdC>()) {
    context->traceEverOn(true);
    model->trace(vcd.get(), 10);
    vcd->open(this->traceFileName.c_str());
  }

  virtual ~ClockedTB() {
    model->final();
    vcd->close();
  }

  virtual void cycle() {
    model->clk = 0;
    model->eval();
    vcd->dump(context->time());

    context->timeInc(1);
    model->clk = 1;
    model->eval();
    vcd->dump(context->time());

    context->timeInc(1);
  }

  virtual void reset() {
    model->rst = 1;
    cycle();
    model->rst = 0;
  }

  virtual T &getModel() { return *model; }

  virtual void runUntil(std::uint64_t endTime) {
    while (!context->gotFinish() && context->time() < endTime) {
      cycle();
    }
  }

  virtual void runCycles(std::uint64_t cycles) {
    for (std::uint64_t i = 0; !context->gotFinish() && i < cycles; cycles++) {
      cycle();
    }
  }

private:
  std::string traceFileName;
  std::unique_ptr<VerilatedContext> context;
  std::unique_ptr<T> model;
  std::unique_ptr<VerilatedVcdC> vcd;
};
