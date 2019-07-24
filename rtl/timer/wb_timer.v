`define WB_TIMER_ENABLED 0

module wb_timer
#(
   parameter WB_DATA_WIDTH = 32,
   parameter WB_ADDR_WIDTH = 32,
   parameter WB_ADDR_START = 32'h00000000
)
(
   input  wire        clk_i,
   input  wire        rst_i,
   input  wire [WB_DATA_WIDTH - 1:0] wb_dat_i,
   input  wire [WB_ADDR_WIDTH - 1:0] wb_addr_i,
   input  wire        wb_we_i,
   input  wire        wb_cyc_i,
   output wire        irq_o,
   output wire [WB_DATA_WIDTH - 1:0] wb_dat_o
);
   // granularity of access 
   localparam WB_TIMER_ACCESS_SIZE = $clog2(WB_DATA_WIDTH);

   // address to set timer threshold
   localparam WB_TIMER_SET_THRESHOLD = WB_ADDR_START;
   // address to set control for timer
   localparam WB_TIMER_SET_CONTOL    = WB_TIMER_SET_THRESHOLD + WB_TIMER_ACCESS_SIZE;
   // address to clear timer
   localparam WB_TIMER_SET_CLEAR     = WB_TIMER_SET_CONTOL + WB_TIMER_ACCESS_SIZE;
   localparam WB_ADDR_END            = WB_TIMER_SET_CLEAR + WB_TIMER_ACCESS_SIZE;

   // irq pin, raised to HIGH if current time exceeds the threshold
   reg irq = 0;
   assign irq_o = irq;

   // contains current time
   reg [WB_DATA_WIDTH - 1:0] current_time = 0;
   // contains threshold tome
   reg [WB_DATA_WIDTH - 1:0] threshold_time = 0;
   // contains contol logic for the timer
   reg [WB_DATA_WIDTH - 1:0] control = 0;

   wire timer_accessed = ((wb_addr_i >= WB_ADDR_START) && (wb_addr_i < WB_ADDR_END));
   wire threshold_set  = (wb_addr_i == WB_TIMER_SET_THRESHOLD);
   wire contol_set     = (wb_addr_i == WB_TIMER_SET_CONTOL);
   wire clear_set      = (wb_addr_i == WB_TIMER_SET_CLEAR);

   always @ (posedge clk_i)
   begin
      if (rst_i)
      begin
         irq <= 0;
         current_time <= 0;
         threshold_time <= 0;
         control <= 0;
      end
      else
      begin
         if (control[`WB_TIMER_ENABLED])
         begin
            current_time <= current_time + 1;
            irq <= (current_time >= threshold_time);
         end
         if (wb_cyc_i && wb_we_i && timer_accessed)
         begin
            if (threshold_set)
            begin
               threshold_time <= wb_dat_i;
            end
            if (contol_set)
            begin
               control <= wb_dat_i;
            end
            if (clear_set)
            begin
               current_time <= 0;
               irq <= 0;
            end
         end
      end
   end


endmodule
