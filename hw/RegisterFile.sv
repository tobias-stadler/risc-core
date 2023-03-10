module RegisterFile (
    input logic clk,
    input logic rst,
    regfile_write_if.Server write0,
    regfile_read_if.Server read0,
    regfile_read_if.Server read1
);

  //TODO maybe move to blockram (probably not possible)
  // TODO maybe make 32 if decrement logic gets weird synthesis
  Uop::val_t ram[32];

  always_ff @(posedge clk) begin
    if (rst)
        ram <= '{default: 0};
    else if (write0.en && write0.addr != 0) ram[write0.addr] <= write0.val;
  end

  always_comb begin
      if(read0.addr == 0)
          read0.val = 0;
      else
          read0.val = ram[read0.addr];
  end

  always_comb begin
      if(read1.addr == 0)
          read1.val = 0;
      else
          read1.val = ram[read1.addr];
  end
endmodule
