`include "helpers.vh"

`define WB_SEL_BYTE 4'b0001
`define WB_SEL_HALF 4'b0011
`define WB_SEL_WORD 4'b1111
`define WB_SEL_TAG  4'b0101
`define BYTE_SIZE_IN_BITS 8
`define WORD_SIZE_IN_BYTES 4

module wb_ram
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
   localparam GRAMULES_ADDR_SKIP = log2(GRANULE_SIZE_BYTES);
   localparam GRANULES_ADDR_WIDTH = log2(GRANULES_NUM);
   
   reg ram_we_r;
   reg tag_we_r;
   reg next_ram_we_r;
   reg next_tag_we_r;
   reg tag_mismatch;
   reg next_tag_mismatch;
   
   reg [WB_ADDR_WIDTH - 1:0] stored_addr;
   reg [WB_DATA_WIDTH - 1:0] stored_data;

   wire [GRANULE_TAG_WIDTH - 1:0]   current_tag          =
       wb_addr_i[WB_ADDR_WIDTH - WB_ADDR_SKIP_BITS - 1:
                 WB_ADDR_WIDTH - WB_ADDR_SKIP_BITS - GRANULE_TAG_WIDTH];
   wire [GRANULES_ADDR_WIDTH - 1:0] current_granule_addr =
        wb_addr_i[GRAMULES_ADDR_SKIP + GRANULES_ADDR_WIDTH - 1:GRAMULES_ADDR_SKIP];

   reg [WB_DATA_WIDTH - 1:0] wb_data_out;
   assign wb_data_o = wb_data_out;

   wire access_byte = (wb_sel_i == `WB_SEL_BYTE);
   wire access_half = (wb_sel_i == `WB_SEL_HALF);
   wire access_word = (wb_sel_i == `WB_SEL_WORD);
   wire access_load_store = (access_byte || access_half || access_word);
   wire access_tag  = (wb_sel_i == `WB_SEL_TAG);
   wire ram_accessed = (wb_cyc_i && wb_stb_i && access_load_store);
   wire tag_accessed = (wb_cyc_i && wb_stb_i && access_tag);

   wire write_byte = (wb_we_i && access_byte);
   wire write_half = (wb_we_i && access_half);
   wire done_in_one_tick = !(write_byte || write_half);

   wire [WB_DATA_WIDTH - 1:0] tag_data_in = wb_data_i;
   wire [GRANULE_TAG_WIDTH - 1:0] tag_data;
   wire [GRANULES_ADDR_WIDTH - 1:0] tag_w_addr = current_granule_addr;
   wire [GRANULES_ADDR_WIDTH - 1:0] tag_r_addr = current_granule_addr;

   generic_ram
   #(
      .RAM_WORDS_SIZE (GRANULES_NUM),
      .RAM_WORDS_WIDTH (GRANULE_TAG_WIDTH),
      .RAM_MEM_FILE (WB_RAM_MEM_FILE)
   )
   tag0
   (
      .clk_i    (wb_clk_i),
      .we_i     (tag_we_r),
      .data_i   (tag_data_in[GRANULE_TAG_WIDTH - 1:0]),
      .w_addr_i (tag_w_addr),
      .r_addr_i (tag_r_addr),
      .data_o   (tag_data)
   );
   
   wire [WB_ADDR_WIDTH - 1:0] ram_data_in = data_to_write;
   wire [WB_ADDR_WIDTH - 1:0] ram_data_out;
   wire [WB_ADDR_WIDTH - 1:0] ram_w_addr = wb_addr_i;
   wire [WB_ADDR_WIDTH - 1:0] ram_r_addr = wb_addr_i;

   generic_ram
   #(
      .RAM_WORDS_SIZE (WB_RAM_WORDS),
      .RAM_WORDS_WIDTH (WB_DATA_WIDTH),
      .RAM_MEM_FILE (WB_RAM_MEM_FILE)
   )
   ram0
   (
      .clk_i    (wb_clk_i),
      .we_i     (ram_we_r),
      .data_i   (ram_data_in),
      .w_addr_i (ram_w_addr[log2(WB_RAM_WORDS) - 1 + 2:2]),
      .r_addr_i (ram_r_addr[log2(WB_RAM_WORDS) - 1 + 2:2]),
      .data_o   (ram_data_out)
   );
      
   localparam [1:0] STATE_IDLE       = 2'd0,
                    STATE_WRITE_WORD = 2'd1,
                    STATE_STOP       = 2'd2,
                    STATE_WRITE_TAG  = 2'd3;

   reg [1:0] state;
   reg [1:0] next_state;

   reg ack;
   reg next_ack;
   assign wb_ack_o = ack;

   reg irq;
   assign tag_mismatch_o = irq;

   wire [1:0] addr_to_check = wb_addr_i[1:0];

   wire [7:0] final_byte = (addr_to_check == 2'b00) ? ram_data_out[7:0] :
                           (addr_to_check == 2'b01) ? ram_data_out[15:8] :
                           (addr_to_check == 2'b10) ? ram_data_out[23:16] :
                                                      ram_data_out[31:24];
   wire [15:0] final_half = (addr_to_check == 2'b00) ? ram_data_out[15:0] : ram_data_out[31:16];
   wire [31:0] final_word = ram_data_out;

   always @ (*) begin
      case (wb_sel_i)
         `WB_SEL_BYTE: wb_data_out = (ram_accessed || tag_accessed) ? {24'b0, final_byte} : 32'b0;
         `WB_SEL_HALF: wb_data_out = (ram_accessed || tag_accessed) ? {16'b0, final_half} : 32'b0;
         `WB_SEL_WORD: wb_data_out = (ram_accessed || tag_accessed) ? final_word : 32'b0;
         `WB_SEL_TAG:  wb_data_out = (ram_accessed || tag_accessed) ? {28'b0, tag_data} : 32'b0;
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

`ifdef ENABLE_ASSERTS
   always @ (*) begin
      if (wb_cyc_i && (wb_sel_i != 4'hF)) begin
         case (wb_sel_i)
            `WB_SEL_WORD: assert(addr_to_check == 2'b0);
            `WB_SEL_HALF: assert(!wb_addr_i[0]);
            default: assert(1'b1);
         endcase
      end
   end
`endif

   always @ (posedge wb_clk_i) begin
      if (wb_rst_i) begin
         state <= STATE_IDLE;
         ack <= 0;
         irq <= 0;
         stored_addr <= 0;
         stored_data <= 0;
         ram_we_r <= 0;
         tag_we_r <= 0;
         tag_mismatch <= 0;
      end
      else begin
         state <= next_state;
         ack <= next_ack;
         stored_addr <= (ram_accessed || tag_accessed) ? wb_addr_i : stored_addr;
         stored_data <= (ram_accessed || tag_accessed) ? wb_data_i : stored_data;
         irq <= (clear_mismatch_i) ? 1'b0 :
                (tag_mismatch || irq) ? 1'b1 : 1'b0;
         ram_we_r <= next_ram_we_r;
         tag_we_r <= next_tag_we_r;
         tag_mismatch <= next_tag_mismatch;
      end
   end


   always @ (*) begin
      next_state = STATE_IDLE;
      next_ack = 0;
      next_tag_mismatch = 0;
      next_ram_we_r = 0;
      next_tag_we_r = 0;
      case (state)
         STATE_IDLE: begin
            if (ram_accessed) begin
               next_state = (done_in_one_tick) ? STATE_STOP : STATE_WRITE_WORD;
               next_ack = 1'b1;
               next_ram_we_r = wb_we_i;
            end
            if (tag_accessed) begin
               next_ack = 1'b1;
               next_state = STATE_STOP;
               next_tag_we_r = wb_we_i;
            end
         end
         STATE_WRITE_WORD: begin
            next_tag_we_r = 0;
            next_ram_we_r = 0;
            next_state = STATE_STOP;
            next_ack = 1'b0;
         end
         STATE_STOP: begin
//            next_tag_mismatch = (check_tags_i && (access_byte || access_half || access_word)) ? (current_tag != tag_data) : 1'b0;
            next_tag_mismatch = (check_tags_i) ? (current_tag != tag_data) : 1'b0;
            next_ram_we_r = 0;
            next_tag_we_r = 0;
            next_state = STATE_IDLE;
            next_ack = 0;
         end
         STATE_WRITE_TAG: begin
            next_state = STATE_WRITE_TAG;
            next_ram_we_r = 0;
            next_tag_we_r = 0;
         end
      endcase
   end

endmodule
