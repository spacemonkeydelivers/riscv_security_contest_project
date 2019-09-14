`include "timer/wb_timer.v"
`include "bus/wb_ext.v"
`include "bus/wb_mux.v"
`include "ram/wb_ram.v"
`include "ram/generic_ram.v"
`include "cpu/cpu.v"
`include "uart/wb_uart.v"

module soc
#(
   parameter FIRMWARE_FILE = "",
   parameter SOC_RAM_SIZE = 65536
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
   output wire                       ext_tran_ready_o,

   input wire                        ext_cpu_halt_i,
   output wire [31:0]                pc_o,
   output wire [4:0]                 state_o
);
   /*verilator no_inline_module*/

   localparam WB_DATA_WIDTH = 32;
   localparam WB_ADDR_WIDTH = 32;
   localparam WB_SEL_WIDTH  = 4;

   localparam CPU_RESET_ADDR = 32'd4096;
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
   wire timer_mtimecmp_accessed;
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
   wire check_tags;
   wire clear_tags_mismatch;

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
      .timer_irq_o (timer_irq),
      .timer_mtimecmp_accessed_o (timer_mtimecmp_accessed)
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
      .clk_i (clk_i),
      .rst_i (rst_i),
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

   wb_ram
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
      .clear_tag_mismatch_o (clear_tags_mismatch),
      .clear_mip_timer_i (timer_mtimecmp_accessed),
      .external_halt_i (ext_cpu_halt_i),
      .pc_o (pc_o),
      .state_o (state_o)
   );

   wb_uart
   #(
      .WB_DATA_WIDTH (WB_DATA_WIDTH),
      .WB_ADDR_WIDTH (WB_ADDR_WIDTH)
   )
   uart0
   (
      .clk_i (clk_i),
      .rst_i (rst_i),
      .wb_addr_i (wb_uart_addr),
      .wb_data_i (wb_uart_data_in),
      .wb_sel_i (wb_uart_sel),
      .wb_we_i (wb_uart_we),
      .wb_cyc_i (wb_uart_cyc),
      .wb_stb_i (wb_uart_stb),
      .wb_ack_o (wb_uart_ack),
      .wb_data_o (wb_uart_data_out),
      .uart_tx_o (uart_tx_o)
   );

endmodule
