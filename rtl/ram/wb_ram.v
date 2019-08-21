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

module wb_ram_new
   #(
      parameter WB_DATA_WIDTH = 32,
      parameter WB_ADDR_WIDTH = 32,
      parameter WB_RAM_WORDS  = 256,
      parameter WB_SEL_WIDTH  = (WB_DATA_WIDTH) / 8,
      parameter WB_RAM_MEM_FILE = ""
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
      output wire                       wb_ack_o,
      output wire [WB_DATA_WIDTH - 1:0] wb_data_o
   );

   reg [WB_DATA_WIDTH - 1:0] wb_data_out;
   assign wb_data_o = wb_data_out;

   wire ram_accessed = (wb_cyc_i & wb_stb_i);
   wire access_byte = (wb_sel_i == `WB_SEL_BYTE);
   wire access_half = (wb_sel_i == `WB_SEL_HALF);
   wire access_word = (wb_sel_i == `WB_SEL_WORD);

   wire write_byte = (wb_we_i && access_byte);
   wire write_half = (wb_we_i && access_half);
   wire done_in_one_tick = !(write_byte || write_half);

   reg [WB_DATA_WIDTH - 1:0] ram_data_in;
   wire [WB_DATA_WIDTH - 1:0] ram_data_out;
   reg [WB_ADDR_WIDTH - 1:0] ram_w_addr;
   reg [WB_ADDR_WIDTH - 1:0] ram_r_addr;
   reg ram_we;

   generic_ram
   #(
      .RAM_WORDS_SIZE (WB_RAM_WORDS),
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

   always @ (posedge wb_clk_i) begin
      if (wb_rst_i) begin
         state <= STATE_IDLE;
         ack <= 0;
      end
      else begin
         state <= next_state;
         ack <= next_ack;
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
         default:      wb_data_out = 32'h0;
      endcase
   end

   reg [31:0] data_to_write;
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

   always @ (*) begin
      next_state = STATE_IDLE;
      next_ack = 0;
      case (state)
         STATE_IDLE: begin
            if (ram_accessed) begin
               ram_r_addr = wb_addr_i;
               ram_w_addr = wb_addr_i;
               ram_data_in = data_to_write;
               next_state = (done_in_one_tick) ? STATE_STOP : STATE_WRITE_WORD;
               next_ack = (done_in_one_tick) ? 1 : 0;
               ram_we = (done_in_one_tick) ? wb_we_i : 0;
            end
         end
         STATE_WRITE_WORD: begin
            ram_data_in = data_to_write;
            ram_we = wb_we_i;
            next_state = STATE_STOP;
            next_ack = 1;
         end
         STATE_STOP: begin
            ram_we = 0;
            next_state = STATE_IDLE;
            next_ack = 0;
         end
         default: begin
         end
      endcase
   end

endmodule
