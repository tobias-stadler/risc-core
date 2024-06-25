`include "Instr.sv"
`include "Uop.sv"
`include "Mem.sv"

module PlaygroundTB (
    input logic clk,
    input logic rst,

    output logic d_req_valid,
    input logic d_req_ready,
    output logic [1:0] d_req_id,
    output logic d_req_we,
    output Mem::lineaddr_t d_req_addr,
    output Mem::line_t d_req_data,

    input logic d_resp_valid,
    output logic d_resp_ready,
    input logic [1:0] d_resp_id,
    input Mem::line_t d_resp_data,

    output logic i_req_valid,
    input logic i_req_ready,
    output logic [1:0] i_req_id,
    output logic i_req_we,
    output Mem::lineaddr_t i_req_addr,
    output Mem::line_t i_req_data,

    input logic i_resp_valid,
    output logic i_resp_ready,
    input logic [1:0] i_resp_id,
    input Mem::line_t i_resp_data
);

  l1cache_mem_if if_iBus ();
  l1cache_mem_if if_dBus ();

  Core m_core (
      .clk(clk),
      .rst(rst),
      .iBus(if_iBus),
      .dBus(if_dBus)
  );

  assign d_req_valid = if_dBus.req_valid;
  assign d_req_we = if_dBus.req_we;
  assign d_req_id = if_dBus.req_id;
  assign d_req_addr = if_dBus.req_addr;
  assign d_req_data = if_dBus.req_data;
  assign if_dBus.req_ready = d_req_ready;

  assign d_resp_ready = if_dBus.resp_ready;
  assign if_dBus.resp_valid = d_resp_valid;
  assign if_dBus.resp_data = d_resp_data;
  assign if_dBus.resp_id = d_resp_id;

  assign i_req_valid = if_iBus.req_valid;
  assign i_req_we = if_iBus.req_we;
  assign i_req_id = if_iBus.req_id;
  assign i_req_addr = if_iBus.req_addr;
  assign i_req_data = if_iBus.req_data;
  assign if_iBus.req_ready = i_req_ready;

  assign i_resp_ready = if_iBus.resp_ready;
  assign if_iBus.resp_valid = i_resp_valid;
  assign if_iBus.resp_data = i_resp_data;
  assign if_iBus.resp_id = i_resp_id;
endmodule
