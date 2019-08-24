module wb_ext
#(
   parameter DATA_WIDTH = 32,
   parameter ADDR_WIDTH = 32,
   parameter WB_DATA_WIDTH = 32,
   parameter WB_ADDR_WIDTH = 32,
   parameter WB_SEL_WIDTH  = WB_DATA_WIDTH / 8
)
 (
   input  wire                       clk_i,
   input  wire                       rst_i,
   input  wire [DATA_WIDTH - 1:0]    transaction_data_i,
   input  wire [ADDR_WIDTH - 1:0]    transaction_addr_i,
   output wire [DATA_WIDTH - 1:0]    transaction_data_o,
   input  wire [1:0]                 transaction_size_i,
   input  wire                       transaction_we_i,
   input  wire                       transaction_start_i,
   input  wire                       transaction_clear_ready_i,
   output wire                       transaction_ready_o,
   input  wire                       wb_ack_i,
   input  wire [WB_DATA_WIDTH - 1:0] wb_data_i,
   output wire [WB_ADDR_WIDTH - 1:0] wb_addr_o,
   output wire [WB_DATA_WIDTH - 1:0] wb_data_o,
   output wire                       wb_we_o,
   output wire [WB_SEL_WIDTH - 1:0]  wb_sel_o,
   output wire                       wb_stb_o,
   output wire                       wb_cyc_o
);
   /*verilator no_inline_module*/

   localparam TRAN_SIZE_BYTE = 0;
   localparam TRAN_SIZE_HALF = 1;
   localparam TRAN_SIZE_WORD = 2;

   localparam WB_SEL_BYTE = 4'b0001;
   localparam WB_SEL_HALF = 4'b0011;
   localparam WB_SEL_WORD = 4'b1111;

   reg tran_started;
   reg tran_finished;
   reg [WB_DATA_WIDTH - 1:0] data;
   assign transaction_data_o = data;

   reg [3:0] data_sel;
   assign wb_sel_o = data_sel;

   reg wb_we;
   assign wb_we_o = wb_we;

   assign wb_stb_o = tran_started;
   assign wb_cyc_o = tran_started;
   assign transaction_ready_o = tran_finished;
   assign wb_addr_o = transaction_addr_i;
   assign wb_data_o = transaction_data_i;

   always @ (posedge clk_i) begin
      if (rst_i) begin
         tran_started <= 0;
         tran_finished <= 0;
         data_sel <= 0;
         data <= 0;
         wb_we <= 0;
      end
      else begin
         if (transaction_start_i && !tran_started) begin
            tran_started <= 1;
            case (transaction_size_i)
               TRAN_SIZE_BYTE: data_sel <= WB_SEL_BYTE;
               TRAN_SIZE_HALF: data_sel <= WB_SEL_HALF;
               TRAN_SIZE_WORD: data_sel <= WB_SEL_WORD;
               default:        data_sel <= WB_SEL_WORD;
            endcase
            wb_we <= transaction_we_i;
         end
         if (tran_started && wb_ack_i) begin
            tran_started <= 0;
            tran_finished <= 1;
            data <= wb_data_i;
            wb_we <= 0;
         end
         if (transaction_clear_ready_i) begin
            tran_finished <= 0;
         end
      end
   end
endmodule

module soc
#(
   parameter FIRMWARE_FILE = "",
   parameter SOC_RAM_SIZE = 8192
)
(
   input  wire clk_i,
   input  wire cpu_rst_i,
   input  wire rst_i,
   input  wire uart_rx_i,
   output wire uart_tx_o,
   input  wire bus_master_selector_i,
   input  wire [WB_ADDR_WIDTH - 1:0] ext_tran_addr_i,
   input  wire [WB_DATA_WIDTH - 1:0] ext_tran_data_i,
   input  wire [1:0]                 ext_tran_size_i,
   input  wire                       ext_tran_start_i,
   input  wire                       ext_tran_write_i,
   input  wire                       ext_tran_clear_i,
   output wire [WB_DATA_WIDTH - 1:0] ext_tran_data_o,
   output wire                       ext_tran_ready_o
);
   /*verilator no_inline_module*/

   localparam WB_DATA_WIDTH = 32;
   localparam WB_ADDR_WIDTH = 32;
   localparam WB_SEL_WIDTH  = 4;

   localparam CPU_RESET_ADDR = 32'h0;
   localparam CPU_EXCEPTION_ADDR = 32'h00AA_1155;
   
   // external interface
   wire [WB_ADDR_WIDTH - 1:0] wb_ext_addr;
   wire [WB_DATA_WIDTH - 1:0] wb_ext_data_in;
   wire wb_ext_we;
   wire [WB_SEL_WIDTH - 1:0]  wb_ext_sel;
   wire wb_ext_stb;
   wire wb_ext_cyc;
   wire wb_ext_ack;
   wire [WB_DATA_WIDTH - 1:0] wb_ext_data_out;
   
   // cpu interface
   wire [WB_ADDR_WIDTH - 1:0] wb_cpu_addr;
   wire [WB_DATA_WIDTH - 1:0] wb_cpu_data_in;
   wire wb_cpu_we;
   wire [WB_SEL_WIDTH - 1:0]  wb_cpu_sel;
   wire wb_cpu_stb;
   wire wb_cpu_cyc;
   wire wb_cpu_ack;
   wire [WB_DATA_WIDTH - 1:0] wb_cpu_data_out;

   // timer interface
   wire [WB_ADDR_WIDTH - 1:0] wb_timer_addr;
   wire [WB_DATA_WIDTH - 1:0] wb_timer_data_in;
   wire wb_timer_we;
   wire [WB_SEL_WIDTH - 1:0]  wb_timer_sel;
   wire wb_timer_stb;
   wire wb_timer_cyc;
   wire wb_timer_ack;
   wire [WB_DATA_WIDTH - 1:0] wb_timer_data_out;
   wire timer_irq;
   wire tags_mismatch_irq;
   
   // uart interface
   wire [WB_ADDR_WIDTH - 1:0] wb_uart_addr;
   wire [WB_DATA_WIDTH - 1:0] wb_uart_data_in;
   wire wb_uart_we;
   wire [WB_SEL_WIDTH - 1:0]  wb_uart_sel;
   wire wb_uart_stb;
   wire wb_uart_cyc;
   wire wb_uart_ack;
   wire [WB_DATA_WIDTH - 1:0] wb_uart_data_out;

   // ram interface
   wire [WB_ADDR_WIDTH - 1:0] wb_ram_addr;
   wire [WB_DATA_WIDTH - 1:0] wb_ram_data_in;
   wire wb_ram_we;
   wire [WB_SEL_WIDTH - 1:0]  wb_ram_sel;
   wire wb_ram_stb;
   wire wb_ram_cyc;
   wire wb_ram_ack;
   wire [WB_DATA_WIDTH - 1:0] wb_ram_data_out;

   wb_timer
   #(
      .WB_DATA_WIDTH (WB_DATA_WIDTH),
      .WB_ADDR_WIDTH (WB_ADDR_WIDTH),
      .WB_SEL_WIDTH (WB_SEL_WIDTH)
   )
   timer0
   (
      .clk_i (clk_i),
      .rst_i (rst_i),
      .wb_addr_i (wb_timer_addr),
      .wb_data_i (wb_timer_data_in),
      .wb_we_i (wb_timer_we),
      .wb_sel_i (wb_timer_sel),
      .wb_stb_i (wb_timer_stb),
      .wb_cyc_i (wb_timer_cyc),
      .wb_ack_o (wb_timer_ack),
      .wb_data_o (wb_timer_data_out),
      .timer_irq_o (timer_irq)
   );
   
   wb_ext
   #(
      .DATA_WIDTH (WB_DATA_WIDTH),
      .ADDR_WIDTH (WB_ADDR_WIDTH),
      .WB_DATA_WIDTH (WB_DATA_WIDTH),
      .WB_ADDR_WIDTH (WB_ADDR_WIDTH)
   )
   ext0
   (
      .clk_i (clk_i),
      .rst_i (rst_i),
      .transaction_data_i (ext_tran_data_i),
      .transaction_addr_i (ext_tran_addr_i),
      .transaction_size_i (ext_tran_size_i),
      .transaction_we_i (ext_tran_write_i),
      .transaction_start_i (ext_tran_start_i),
      .transaction_clear_ready_i (ext_tran_clear_i),
      .wb_ack_i (wb_ext_ack),
      .transaction_ready_o (ext_tran_ready_o),
      .transaction_data_o (ext_tran_data_o),
      .wb_addr_o (wb_ext_addr),
      .wb_data_o (wb_ext_data_out),
      .wb_data_i (wb_ext_data_in),
      .wb_we_o (wb_ext_we),
      .wb_sel_o (wb_ext_sel),
      .wb_stb_o (wb_ext_stb),
      .wb_cyc_o (wb_ext_cyc)
   );
   
   wb_mux
   #(
      .WB_DATA_WIDTH (WB_DATA_WIDTH),
      .WB_ADDR_WIDTH (WB_ADDR_WIDTH),
      .WB_SEL_WIDTH (WB_SEL_WIDTH)
   )
   mux0
   (
      .bus_master_i (bus_master_selector_i),
      // external
      .wb_ext_addr_i (wb_ext_addr),
      .wb_ext_data_i (wb_ext_data_out),
      .wb_ext_we_i (wb_ext_we),
      .wb_ext_sel_i (wb_ext_sel),
      .wb_ext_stb_i (wb_ext_stb),
      .wb_ext_cyc_i (wb_ext_cyc),
      .wb_ext_ack_o (wb_ext_ack),
      .wb_ext_data_o (wb_ext_data_in),
      // cpu
      .wb_cpu_addr_i (wb_cpu_addr),
      .wb_cpu_data_i (wb_cpu_data_out),
      .wb_cpu_we_i (wb_cpu_we),
      .wb_cpu_sel_i (wb_cpu_sel),
      .wb_cpu_stb_i (wb_cpu_stb),
      .wb_cpu_cyc_i (wb_cpu_cyc),
      .wb_cpu_ack_o (wb_cpu_ack),
      .wb_cpu_data_o (wb_cpu_data_in),
      // timer
      .wb_timer_addr_o (wb_timer_addr),
      .wb_timer_data_o (wb_timer_data_in),
      .wb_timer_we_o (wb_timer_we),
      .wb_timer_sel_o (wb_timer_sel),
      .wb_timer_stb_o (wb_timer_stb),
      .wb_timer_cyc_o (wb_timer_cyc),
      .wb_timer_ack_i (wb_timer_ack),
      .wb_timer_data_i (wb_timer_data_out),
      // ram
      .wb_ram_addr_o (wb_ram_addr),
      .wb_ram_data_o (wb_ram_data_in),
      .wb_ram_we_o (wb_ram_we),
      .wb_ram_sel_o (wb_ram_sel),
      .wb_ram_stb_o (wb_ram_stb),
      .wb_ram_cyc_o (wb_ram_cyc),
      .wb_ram_ack_i (wb_ram_ack),
      .wb_ram_data_i (wb_ram_data_out),
      // uart
      .wb_uart_addr_o (wb_uart_addr),
      .wb_uart_data_o (wb_uart_data_in),
      .wb_uart_we_o (wb_uart_we),
      .wb_uart_sel_o (wb_uart_sel),
      .wb_uart_stb_o (wb_uart_stb),
      .wb_uart_cyc_o (wb_uart_cyc),
      .wb_uart_ack_i (wb_uart_ack),
      .wb_uart_data_i (wb_uart_data_out)
   );

   wb_ram_new
   #(
      .WB_DATA_WIDTH (WB_DATA_WIDTH),
      .WB_ADDR_WIDTH (WB_ADDR_WIDTH),
      .WB_RAM_WORDS (SOC_RAM_SIZE / 4)
   )
   ram0
   (
      .wb_clk_i (clk_i),
      .wb_rst_i (rst_i),
      .wb_addr_i (wb_ram_addr),
      .wb_data_i (wb_ram_data_in),
      .wb_sel_i (wb_ram_sel),
      .wb_stb_i (wb_ram_stb),
      .wb_we_i (wb_ram_we),
      .wb_cyc_i (wb_ram_cyc),
      .wb_ack_o (wb_ram_ack),
      .wb_data_o (wb_ram_data_out),
      .check_tags_i (check_tags),
      .tag_mismatch_o (tags_mismatch_irq),
      .clear_mismatch_i (clear_tags_mismatch)
   );

   reg [31:0] cpu_addr = 0;
   reg [31:0] cpu_data_in = 0;
   wire [31:0] cpu_data_out;
   reg cpu_en = 0;
   reg [2:0] cpu_op = 0;
   wire cpu_busy;
   wire check_tags;
   wire clear_tags_mismatch;

   cpu
   #(
      .VECTOR_RESET (CPU_RESET_ADDR),
      .VECTOR_EXCEPTION (CPU_EXCEPTION_ADDR)
   )
   cpu0
   (
      .TIMER_INTERRUPT_I (timer_irq),
      .TAGS_INTERRUPT_I (tags_mismatch_irq),
      .CLK_I (clk_i),
      .ACK_I (wb_cpu_ack),
      .DAT_I (wb_cpu_data_in),
      .RST_I (cpu_rst_i),
      .ADR_O (wb_cpu_addr),
      .DAT_O (wb_cpu_data_out),
      .SEL_O (wb_cpu_sel),
      .CYC_O (wb_cpu_cyc),
      .STB_O (wb_cpu_stb),
      .WE_O (wb_cpu_we),
      .check_tags_o (check_tags),
      .clear_tag_mismatch_o (clear_tags_mismatch)
   );

   wire uart_stall;
   wire uart_cts;
   wire uart_rts;
   wire uart_rx_int;
   wire uart_tx_int;
   wire uart_rx_fifo_int;
   wire uart_tx_fifo_int;

   wbuart
   #(
      .INITIAL_SETUP(31'd25),
      .LGFLEN(4),
      .HARDWARE_FLOW_CONTROL_PRESENT(0)
   )
   uart0
   (
      .i_clk(clk_i),
      .i_rst(rst_i),
      .i_wb_cyc(wb_uart_cyc),
      .i_wb_stb(wb_uart_stb),
      .i_wb_we(wb_uart_we),
      .i_wb_addr(wb_uart_addr),
      .i_wb_data(wb_uart_data_in),
      .o_wb_ack(wb_uart_ack),
      .o_wb_stall(uart_stall),
      .o_wb_data(wb_uart_data_out),
      .i_uart_rx(uart_rx_i),
      .o_uart_tx(uart_tx_o),
      .i_cts_n(uart_cts),
      .o_rts_n(uart_rts),
      .o_uart_rx_int(uart_rx_int),
      .o_uart_tx_int(uart_tx_int),
      .o_uart_rxfifo_int(uart_rx_fifo_int),
      .o_uart_txfifo_int(uart_tx_fifo_int)
   );

endmodule
