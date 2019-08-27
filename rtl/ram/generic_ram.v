`include "helpers.vh"

module generic_ram
   #(
      parameter RAM_WORDS_SIZE = 256,
      parameter RAM_MEM_FILE = "",
      parameter RAM_WORDS_WIDTH = 32
   )
   (
      input wire                                clk_i,
      input wire                                we_i,
      input wire [RAM_WORDS_WIDTH - 1:0]        data_i,
      input wire [log2(RAM_WORDS_SIZE) - 1:0] w_addr_i,
      input wire [log2(RAM_WORDS_SIZE) - 1:0] r_addr_i,
      output reg [RAM_WORDS_WIDTH - 1:0]        data_o
   );

   reg [RAM_WORDS_WIDTH - 1:0] mem [0:RAM_WORDS_SIZE - 1] /* verilator public */;

   always @(posedge clk_i) begin
      if (we_i) begin
         mem[w_addr_i] <= data_i;
      end
      data_o <= mem[r_addr_i];
   end

   generate
   initial
      if(|RAM_MEM_FILE) begin
         $readmemh(RAM_MEM_FILE, mem);
      end
   endgenerate

endmodule

