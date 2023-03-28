module ByteWriteSpRfRam #(
    parameter int COLS = 4,
    parameter int COL_BITS = 8,
    parameter int ADDR_BITS = 5,
    localparam int DATA_BITS = COLS * COL_BITS
) (
    input logic clk,
    input logic en,
    input logic [COLS-1:0] we,
    input logic [ADDR_BITS-1:0] addr,
    input logic [DATA_BITS-1:0] data_i,
    output logic [DATA_BITS-1:0] data_o
);

  logic [DATA_BITS-1:0] mem[2**ADDR_BITS];

  initial mem = '{default: 0};

  always_ff @(posedge clk)
    if (en) begin
      for (int i = 0; i < COLS; i++) begin
        if (we[i]) mem[addr][i*COL_BITS+:COL_BITS] <= data_i[i*COL_BITS+:COL_BITS];
      end
      data_o <= mem[addr];
    end

endmodule
