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
      input wire [$clog2(RAM_WORDS_SIZE) - 1:0] w_addr_i,
      input wire [$clog2(RAM_WORDS_SIZE) - 1:0] r_addr_i,
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

`define WB_SEL_BYTE 4'b0001
`define WB_SEL_HALF 4'b0011
`define WB_SEL_WORD 4'b1111
`define WB_SEL_TAG  4'b0101
`define BYTE_SIZE_IN_BITS 8
`define WORD_SIZE_IN_BYTES 4

module wb_ram_new
   #(
      parameter WB_DATA_WIDTH      = 32,
      parameter WB_ADDR_WIDTH      = 32,
      parameter WB_RAM_WORDS       = 256,
      parameter WB_SEL_WIDTH       = (WB_DATA_WIDTH) / `BYTE_SIZE_IN_BITS,
      parameter WB_RAM_MEM_FILE    = "",
      parameter GRANULE_SIZE_BYTES = 16,
      parameter GRANULE_TAG_WIDTH  = 4
   )
   (
      input wire                        wb_clk_i,
      input wire                        wb_rst_i,
      input wire [WB_ADDR_WIDTH - 1:0]  wb_addr_i,
      input wire [WB_DATA_WIDTH - 1:0]  wb_data_i,
      input wire [WB_SEL_WIDTH - 1:0]   wb_sel_i,
      input wire                        wb_we_i,
      input wire                        wb_cyc_i,
      input wire                        wb_stb_i,
      input wire                        check_tags_i,
      input wire                        clear_mismatch_i,
      output wire                       tag_mismatch_o,
      output wire                       wb_ack_o,
      output wire [WB_DATA_WIDTH - 1:0] wb_data_o
   );
   
   localparam WB_ADDR_SKIP_BITS = 2;
   localparam GRANULES_NUM = (WB_RAM_WORDS * `WORD_SIZE_IN_BYTES) / GRANULE_SIZE_BYTES;
   localparam GRAMULES_ADDR_SKIP = $clog2(GRANULE_SIZE_BYTES);
   localparam GRANULES_ADDR_WIDTH = $clog2(GRANULES_NUM);

   wire [GRANULE_TAG_WIDTH - 1:0] current_tag = wb_addr_i[WB_ADDR_WIDTH - WB_ADDR_SKIP_BITS:WB_ADDR_WIDTH - WB_ADDR_SKIP_BITS - GRANULE_TAG_WIDTH];
   wire [GRANULES_ADDR_WIDTH - 1:0] current_granule_addr = wb_addr_i[GRAMULES_ADDR_SKIP + GRANULES_ADDR_WIDTH - 1:GRAMULES_ADDR_SKIP];

   reg [WB_DATA_WIDTH - 1:0] wb_data_out;
   assign wb_data_o = wb_data_out;

   wire access_byte = (wb_sel_i == `WB_SEL_BYTE);
   wire access_half = (wb_sel_i == `WB_SEL_HALF);
   wire access_word = (wb_sel_i == `WB_SEL_WORD);
   wire access_tag  = (wb_sel_i == `WB_SEL_TAG);
   wire ram_accessed = (wb_cyc_i && wb_stb_i && !access_tag);
   wire tag_accessed = (wb_cyc_i && wb_stb_i && access_tag);

   wire write_byte = (wb_we_i && access_byte);
   wire write_half = (wb_we_i && access_half);
   wire done_in_one_tick = !(write_byte || write_half);

   reg [WB_DATA_WIDTH - 1:0] tag_data_in;
   wire [WB_DATA_WIDTH - 1:0] tag_data_out;
   reg [GRANULES_ADDR_WIDTH - 1:0] tag_w_addr;
   reg [GRANULES_ADDR_WIDTH - 1:0] tag_r_addr;
   reg tag_we;

   generic_ram
   #(
      .RAM_WORDS_SIZE (WB_RAM_WORDS),
      .RAM_WORDS_WIDTH (GRANULE_TAG_WIDTH),
      .RAM_MEM_FILE (WB_RAM_MEM_FILE)
   )
   tag0
   (
      .clk_i    (wb_clk_i),
      .we_i     (tag_we),
      .data_i   (tag_data_in),
      .w_addr_i (tag_w_addr),
      .r_addr_i (tag_r_addr),
      .data_o   (tag_data_out)
   );
   
   reg [WB_ADDR_WIDTH - 1:0] ram_data_in;
   wire [WB_ADDR_WIDTH - 1:0] ram_data_out;
   reg [WB_ADDR_WIDTH - 1:0] ram_w_addr;
   reg [WB_ADDR_WIDTH - 1:0] ram_r_addr;
   reg ram_we;

   generic_ram
   #(
      .RAM_WORDS_SIZE (WB_RAM_WORDS),
      .RAM_WORDS_WIDTH (WB_DATA_WIDTH),
      .RAM_MEM_FILE (WB_RAM_MEM_FILE)
   )
   ram0
   (
      .clk_i    (wb_clk_i),
      .we_i     (ram_we),
      .data_i   (ram_data_in),
      .w_addr_i (ram_w_addr[WB_ADDR_WIDTH - 1:2]),
      .r_addr_i (ram_r_addr[WB_ADDR_WIDTH - 1:2]),
      .data_o   (ram_data_out)
   );
      
   localparam [1:0] STATE_IDLE       = 3'd0,
                    STATE_WRITE_WORD = 3'd1,
                    STATE_STOP       = 3'd2;

   reg [2:0] state;
   reg [2:0] next_state;

   reg ack;
   reg next_ack;
   assign wb_ack_o = ack;

   reg irq;
   assign tag_mismatch_o = irq;

   always @ (posedge wb_clk_i) begin
      if (wb_rst_i) begin
         state <= STATE_IDLE;
         ack <= 0;
         irq <= 0;
      end
      else begin
         state <= next_state;
         ack <= next_ack;
         irq <= (clear_mismatch_i) ? 0 :
                (tag_mismatch || irq) ? 1 : 0;
      end
   end
   
   wire [1:0] addr_to_check = wb_addr_i[1:0];

   wire [7:0] final_byte = (addr_to_check == 2'b00) ? ram_data_out[7:0] :
                           (addr_to_check == 2'b01) ? ram_data_out[15:8] :
                           (addr_to_check == 2'b10) ? ram_data_out[23:16] :
                                                      ram_data_out[31:24];
   wire [15:0] final_half = (addr_to_check == 2'b00) ? ram_data_out[15:0] : ram_data_out[31:16];
   wire [31:0] final_word = ram_data_out;

   always @ (*) begin
      case (wb_sel_i)
         `WB_SEL_BYTE: wb_data_out = {24'b0, final_byte};
         `WB_SEL_HALF: wb_data_out = {16'b0, final_half};
         `WB_SEL_WORD: wb_data_out = final_word;
         `WB_SEL_TAG:  wb_data_out = {28'b0, tag_data_out};
         default:      wb_data_out = 32'h0;
      endcase
   end

   reg [WB_DATA_WIDTH - 1:0] data_to_write;
   always @ (*) begin
      case (wb_sel_i)
         `WB_SEL_BYTE: data_to_write = (addr_to_check == 2'b00) ? {ram_data_out[31:8], wb_data_i[7:0]} :
                                       (addr_to_check == 2'b01) ? {ram_data_out[31:16], wb_data_i[7:0], ram_data_out[7:0]} :
                                       (addr_to_check == 2'b10) ? {ram_data_out[31:24], wb_data_i[7:0], ram_data_out[15:0]} :
                                                                  {wb_data_i[7:0], ram_data_out[23:0]};
         `WB_SEL_HALF: data_to_write = (addr_to_check == 2'b00) ? {ram_data_out[31:16], wb_data_i[15:0]} :
                                       (addr_to_check == 2'b10) ? {wb_data_i[15:0], ram_data_out[15:0]} :
                                                                  0;
         `WB_SEL_WORD: data_to_write = wb_data_i;
         default: data_to_write = 0;
      endcase
   end

   reg tag_mismatch;

   always @ (*) begin
      next_state = STATE_IDLE;
      next_ack = 0;
      tag_mismatch = 0;
      case (state)
         STATE_IDLE: begin
            if (ram_accessed) begin
               ram_r_addr = wb_addr_i;
               ram_w_addr = wb_addr_i;
               ram_data_in = data_to_write;
               next_state = (done_in_one_tick) ? STATE_STOP : STATE_WRITE_WORD;
               next_ack = (done_in_one_tick) ? 1 : 0;
               ram_we = (done_in_one_tick) ? wb_we_i : 0;
               tag_r_addr = current_granule_addr;
            end
            if (tag_accessed) begin
               tag_r_addr = current_granule_addr;
               tag_w_addr = current_granule_addr;
               tag_data_in = wb_data_i[GRANULE_TAG_WIDTH - 1:0];
               tag_we = wb_we_i;
               next_ack = 1;
               next_state = STATE_STOP;
            end
         end
         STATE_WRITE_WORD: begin
            ram_data_in = data_to_write;
            ram_we = wb_we_i;
            next_state = STATE_STOP;
            next_ack = 1;
         end
         STATE_STOP: begin
            tag_mismatch = (check_tags_i && ram_accessed) ? (current_tag != tag_data_out) : 0;
            ram_we = 0;
            tag_we = 0;
            next_state = STATE_IDLE;
            next_ack = 0;
         end
         default: begin
         end
      endcase
   end

endmodule
