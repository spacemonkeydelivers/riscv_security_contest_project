`define WB_TIMER_ENABLED 0

module wb_timer
#(
   parameter WB_DATA_WIDTH = 32,
   parameter WB_ADDR_WIDTH = 32,
   parameter WB_SEL_WIDTH  = 4
)
(
   input  wire                       clk_i,
   input  wire                       rst_i,
   input  wire [WB_ADDR_WIDTH - 1:0] wb_addr_i,
   input  wire [WB_DATA_WIDTH - 1:0] wb_data_i,
   input  wire                       wb_we_i,
   input  wire [WB_SEL_WIDTH - 1:0]  wb_sel_i,
   input  wire                       wb_stb_i,
   input  wire                       wb_cyc_i,
   output wire                       wb_ack_o,
   output wire [WB_DATA_WIDTH - 1:0] wb_data_o,
   output wire                       timer_irq_o
);
   // irq pin, raised to HIGH if current time exceeds the threshold
   reg irq = 0;
   assign timer_irq_o = irq;

   // ack signal for wishbone
   reg ack = 0;
   assign wb_ack_o = ack;
   // if timer is running
   reg timer_started = 0;
   // contains current time
   reg [WB_DATA_WIDTH - 1:0] current_time = 0;
   // contains threshold tome
   reg [WB_DATA_WIDTH - 1:0] threshold_time = 0;

   // TODO: WB_ACK_O

   always @ (posedge clk_i)
   begin
      if (rst_i)
      begin
         ack <= 0;
         irq <= 0;
         current_time <= 0;
         threshold_time <= 0;
         timer_started <= 0;
      end
      else
      begin
         if (timer_started)
         begin
            current_time <= current_time + 1;
            irq <= (current_time >= threshold_time);
         end
         if (wb_cyc_i)
         begin
            ack <= 1;
            if (wb_we_i)
            begin
               threshold_time <= wb_data_i;
               timer_started <= 1;
            end
            else
            begin
               current_time <= 0;
            end
         end
         ack <= 0;
      end
   end
endmodule
