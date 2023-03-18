module WriteBackStage (
    input logic clk,
    input logic rst,
    pipeline_if.Upstream u,
    input Uop::memory_t uopIn,
    regfile_write_if.Client write0,
    bypass_if.Subject bypass,
    output logic flush
);

  import Uop::*;


  logic isEx;

  //Before pipeline registers
  always_comb begin
    isEx = uopIn.memNack || uopIn.exValid;

    u.stall = '0;

    if (u.valid) begin
      flush = isEx;
      write0.en = ~isEx;
    end else begin
      flush = '0;
      write0.en = '0;
    end
    write0.addr = uopIn.rd;
    write0.val  = uopIn.rdVal;
  end

  logic   valid;
  reg_t   rd;
  val_t   rdVal;

  flags_t flags;

  //After pipeline registers
  always_comb begin
    bypass.rValid = valid;
    bypass.r = rd;
    bypass.rVal = rdVal;
    bypass.flags = flags;
    bypass.flagsValid = '1;
  end


  //TODO remove
  wire _unused_ok = &{1'b0,uopIn.ex};

  always_ff @(posedge clk) begin
    if (rst) begin
      flags <= '0;
      valid <= '0;
    end else begin
      valid <= u.valid;
      if (u.valid && !isEx && uopIn.flagsValid) begin
        flags <= uopIn.flags;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (u.valid) begin
      rd <= uopIn.rd;
      rdVal <= uopIn.rdVal;
    end
  end
endmodule
