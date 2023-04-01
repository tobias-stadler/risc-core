#pragma once

#include "ClockedTestbench.h"
#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <deque>
#include <iterator>
#include <list>
#include <optional>
#include <vector>
#include <verilated.h>

struct MemoryControllerIf {
  CData &req_valid;
  CData &req_ready;
  CData &req_id;
  CData &req_we;
  IData &req_addr;
  VlWide<4> &req_data;
  CData &resp_valid;
  CData &resp_ready;
  CData &resp_id;
  VlWide<4> &resp_data;

  MemoryControllerIf(CData &req_valid, CData &req_ready, CData &req_id,
                     CData &req_we, IData &req_addr, VlWide<4> &req_data,
                     CData &resp_valid, CData &resp_ready, CData &resp_id,
                     VlWide<4> &resp_data)
      : req_valid(req_valid), req_ready(req_ready), req_id(req_id),
        req_we(req_we), req_addr(req_addr), req_data(req_data),
        resp_valid(resp_valid), resp_ready(resp_ready), resp_id(resp_id),
        resp_data(resp_data) {}
};

class MemoryControllerSim : public PeripheralSim {

public:
  using CacheLine = std::array<uint32_t, 4>;

  enum class RequestKind { WRITE, READ };

  struct Request {
    RequestKind kind;
    uint8_t id;
    uint32_t addr;
    CacheLine data;
    size_t remainingLatency;
  };

  MemoryControllerSim(size_t baseAddr, size_t numBytes, MemoryControllerIf mIf,
                      size_t defaultLatency)
      : baseAddr(baseAddr), defaultLatency(defaultLatency),
        mem(std::vector<uint8_t>(numBytes)), mIf(mIf) {}

  virtual void reset() override {
    mIf.req_ready = 1;
    mIf.resp_valid = 0;
    mIf.resp_data[0] = 0;
    mIf.resp_data[1] = 0;
    mIf.resp_data[2] = 0;
    mIf.resp_data[3] = 0;
    mIf.resp_id = 0;
  }

  virtual void cycle() override {
    if (mIf.req_valid && mIf.req_ready) {
      requestQueue.push_back(readRequest());
    }

    mIf.resp_valid = 0;
    if (mIf.resp_ready) {
      auto it = std::find_if(requestQueue.begin(), requestQueue.end(),
                             [](auto x) { return x.remainingLatency == 0; });
      if (it != requestQueue.end()) {
        executeRequest(*it);
        requestQueue.erase(it);
      }
    }

    for (Request &r : requestQueue) {
      if (r.remainingLatency > 0) {
        r.remainingLatency--;
      }
    }
  }

  uint8_t readLE8(size_t addr) {
    size_t offset = addr - baseAddr;
    return (uint32_t)mem.at(offset);
  }

  uint16_t readLE16(size_t addr) {
    size_t offset = addr - baseAddr;
    return (uint32_t)mem.at(offset) | (uint32_t)mem.at(offset + 1) << 8;
  }

  uint32_t readLE32(size_t addr) {
    size_t offset = addr - baseAddr;
    return (uint32_t)mem.at(offset) | (uint32_t)mem.at(offset + 1) << 8 |
           (uint32_t)mem.at(offset + 2) << 16 |
           (uint32_t)mem.at(offset + 3) << 24;
  }

  void writeLE8(size_t addr, uint8_t val) {
    size_t offset = addr - baseAddr;
    mem.at(offset) = val;
  }

  void writeLE16(size_t addr, uint16_t val) {
    size_t offset = addr - baseAddr;
    mem.at(offset) = val;
    mem.at(offset + 1) = val >> 8;
  }

  void writeLE32(size_t addr, uint32_t val) {
    size_t offset = addr - baseAddr;
    mem.at(offset) = val;
    mem.at(offset + 1) = val >> 8;
    mem.at(offset + 2) = val >> 16;
    mem.at(offset + 3) = val >> 24;
  }

private:
  size_t baseAddr;
  size_t defaultLatency;
  std::vector<uint8_t> mem;
  MemoryControllerIf mIf;
  std::list<Request> requestQueue;

  Request readRequest() {
    return Request{
        mIf.req_we ? RequestKind::WRITE : RequestKind::READ,
        mIf.req_id,
        mIf.req_addr << 4,
        {mIf.req_data[0], mIf.req_data[1], mIf.req_data[2], mIf.req_data[3]},
        defaultLatency};
  }

  void executeRequest(const Request &r) {
    if (r.kind == RequestKind::READ) {
      mIf.resp_data[0] = readLE32(r.addr);
      mIf.resp_data[1] = readLE32(r.addr + 4);
      mIf.resp_data[2] = readLE32(r.addr + 8);
      mIf.resp_data[3] = readLE32(r.addr + 12);
      mIf.resp_id = r.id;
      mIf.resp_valid = 1;
    } else if (r.kind == RequestKind::WRITE) {
      writeLE32(r.addr, r.data[0]);
      writeLE32(r.addr + 4, r.data[1]);
      writeLE32(r.addr + 8, r.data[2]);
      writeLE32(r.addr + 12, r.data[3]);
      mIf.resp_id = r.id;
      mIf.resp_valid = 1;
    }
  }
};
