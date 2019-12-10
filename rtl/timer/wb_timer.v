module wb_timer
  #(parameter WB_DATA_WIDTH = 32,
    parameter WB_ADDR_WIDTH = 32,
    parameter WB_SEL_WIDTH  = 4)
   (input wire                        clk_i,
    input wire                        rst_i,
    input wire [WB_ADDR_WIDTH - 1:0]  wb_addr_i,
    input wire [WB_DATA_WIDTH - 1:0]  wb_data_i,
    input wire                        wb_we_i,
    input wire [WB_SEL_WIDTH - 1:0]   wb_sel_i,
    input wire                        wb_stb_i,
    input wire                        wb_cyc_i,
    output wire                       wb_ack_o,
    output wire [WB_DATA_WIDTH - 1:0] wb_data_o,
    output wire                       timer_irq_o,
    output wire                       timer_mtimecmp_accessed_o);

   localparam DATA_WIDTH = 64;

   reg [DATA_WIDTH - 1:0]             mtime, // current time
                                      mtimecmp, // treshold time
                                      tgt_clk, // clocks to wait
                                      clk_cnt, // i_clk counter
                                      mtime_alw_en; // current time, always enabled

   localparam [2:0] MTIME_LO = 0;
   localparam [2:0] MTIME_HI = 1;
   localparam [2:0] MTIMECMP_LO = 2;
   localparam [2:0] MTIMECMP_HI = 3;
   localparam [2:0] TGT_CLK_LO = 4;
   localparam [2:0] TGT_CLK_HI = 5;
   localparam [2:0] MTIME_AE_LO = 6;
   localparam [2:0] MTIME_AE_HI = 7;

`define LO(reg_name) reg_name[31:0]
`define HI(reg_name) reg_name[63:32]

   // IRQ pin, raised to HIGH if current time exceeds the threshold
   reg                                irq;
   assign timer_irq_o = irq;

   // ack signal for wishbone delayed by one clock with a reg
   reg                                ack;
   assign wb_ack_o = ack;

   wire                               timer_enabled;
   assign timer_enabled = |tgt_clk;

   wire [2:0]                         addr = wb_addr_i[4:2];

   assign timer_mtimecmp_accessed_o = wb_cyc_i && wb_we_i && (addr == MTIMECMP_LO) || (addr == MTIMECMP_HI);

   assign wb_data_o = addr == MTIME_LO    ? `LO(mtime) :
                      addr == MTIME_HI    ? `HI(mtime) :
                      addr == MTIMECMP_LO ? `LO(mtimecmp) :
                      addr == MTIMECMP_HI ? `HI(mtimecmp) :
                      addr == TGT_CLK_LO  ? `LO(tgt_clk) :
                      addr == TGT_CLK_HI  ? `HI(tgt_clk) :
                      addr == MTIME_AE_LO ? `LO(mtime_alw_en) :
                      addr == MTIME_AE_HI ? `HI(mtime_alw_en) :
                      32'd0;

   always @ (posedge clk_i) begin
      if (rst_i) begin
         mtime <= 0;
         mtimecmp <= 0;
         tgt_clk <= 0;
         ack <= 0;
         irq <= 0;
         mtime_alw_en <= 0;

         // ONE
         clk_cnt <= 1;
      end
      else begin
         irq <= mtime >= mtimecmp;
         mtime_alw_en <= mtime_alw_en + 1;

         if (wb_cyc_i & wb_we_i) begin
            // No increment for MTIME on write to it
            if ((addr == MTIME_LO ) || (addr == MTIME_HI)) begin
               if (addr == MTIME_LO)
                 `LO(mtime) <= wb_data_i;
               if (addr == MTIME_HI)
                 `HI(mtime) <= wb_data_i;

               // Only update, no check
               if (timer_enabled)
                 clk_cnt <= clk_cnt + 1;
            end
            else begin
               case (addr)
                 MTIMECMP_LO: `LO(mtimecmp) <= wb_data_i;
                 MTIMECMP_HI: `HI(mtimecmp) <= wb_data_i;
                 TGT_CLK_LO:  `LO(tgt_clk)  <= wb_data_i;
                 TGT_CLK_HI:  `HI(tgt_clk)  <= wb_data_i;
                 default:;
               endcase // case (addr)

               if (timer_enabled) begin
                  if (clk_cnt >= tgt_clk) begin
                     clk_cnt <= 1;
                     mtime <= mtime + 1;
                  end
                  else begin
                     clk_cnt <= clk_cnt + 1;
                  end
               end
            end // else: !if((addr == MTIME_LO ) || (addr == MTIME_HI))
         end // if (wb_cyc_i & wb_we_i)
         else begin
            if (timer_enabled) begin
               if (clk_cnt >= tgt_clk) begin
                  clk_cnt <= 1;
                  mtime <= mtime + 1;
               end
               else begin
                  mtime <= mtime;
                  clk_cnt <= clk_cnt + 1;
               end
            end
         end // else: !if(wb_cyc_i & wb_we_i)

         ack <= (wb_cyc_i & !ack);
      end // else: !if(rst_i)

   end // always @ (posedge clk_i)

endmodule // wb_timer
