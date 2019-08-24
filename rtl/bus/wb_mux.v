module wb_mux
#(
   parameter WB_DATA_WIDTH = 32,
   parameter WB_ADDR_WIDTH = 32,
   parameter WB_SEL_WIDTH  = 4
)
(
   input  wire                       bus_master_i,

   input  wire [WB_ADDR_WIDTH - 1:0] wb_ext_addr_i,
   input  wire [WB_DATA_WIDTH - 1:0] wb_ext_data_i,
   input  wire                       wb_ext_we_i,
   input  wire [WB_SEL_WIDTH - 1:0]  wb_ext_sel_i,
   input  wire                       wb_ext_stb_i,
   input  wire                       wb_ext_cyc_i,
   output wire                       wb_ext_ack_o,
   output wire [WB_DATA_WIDTH - 1:0] wb_ext_data_o,

   input  wire [WB_ADDR_WIDTH - 1:0] wb_cpu_addr_i,
   input  wire [WB_DATA_WIDTH - 1:0] wb_cpu_data_i,
   input  wire                       wb_cpu_we_i,
   input  wire [WB_SEL_WIDTH - 1:0]  wb_cpu_sel_i,
   input  wire                       wb_cpu_stb_i,
   input  wire                       wb_cpu_cyc_i,
   output wire                       wb_cpu_ack_o,
   output wire [WB_DATA_WIDTH - 1:0] wb_cpu_data_o,

   output wire [WB_ADDR_WIDTH - 1:0] wb_timer_addr_o,
   output wire [WB_DATA_WIDTH - 1:0] wb_timer_data_o,
   output wire                       wb_timer_we_o,
   output wire [WB_SEL_WIDTH - 1:0]  wb_timer_sel_o,
   output wire                       wb_timer_stb_o,
   output wire                       wb_timer_cyc_o,
   input  wire                       wb_timer_ack_i,
   input  wire [WB_DATA_WIDTH - 1:0] wb_timer_data_i,

   output wire [WB_ADDR_WIDTH - 1:0] wb_ram_addr_o,
   output wire [WB_DATA_WIDTH - 1:0] wb_ram_data_o,
   output wire                       wb_ram_we_o,
   output wire [WB_SEL_WIDTH - 1:0]  wb_ram_sel_o,
   output wire                       wb_ram_stb_o,
   output wire                       wb_ram_cyc_o,
   input  wire                       wb_ram_ack_i,
   input  wire [WB_DATA_WIDTH - 1:0] wb_ram_data_i,

   output wire [WB_ADDR_WIDTH - 1:0] wb_uart_addr_o,
   output wire [WB_DATA_WIDTH - 1:0] wb_uart_data_o,
   output wire                       wb_uart_we_o,
   output wire [WB_SEL_WIDTH - 1:0]  wb_uart_sel_o,
   output wire                       wb_uart_stb_o,
   output wire                       wb_uart_cyc_o,
   input  wire                       wb_uart_ack_i,
   input  wire [WB_DATA_WIDTH - 1:0] wb_uart_data_i
);
   localparam WB_WRONG_DATA = 32'hDEAD_BEAF;

   localparam WB_ACCESS_TIMER = 1;
   localparam WB_ACCESS_RAM   = 0;
   localparam WB_ACCESS_UART  = 2;

   wire [WB_ADDR_WIDTH - 1:0] wb_master_addr_i = (bus_master_i) ? wb_ext_addr_i : wb_cpu_addr_i;
   wire [WB_DATA_WIDTH - 1:0] wb_master_data_i = (bus_master_i) ? wb_ext_data_i : wb_cpu_data_i;
   wire                       wb_master_we_i   = (bus_master_i) ? wb_ext_we_i   : wb_cpu_we_i;
   wire [WB_SEL_WIDTH - 1:0]  wb_master_sel_i  = (bus_master_i) ? wb_ext_sel_i  : wb_cpu_sel_i;
   wire                       wb_master_stb_i  = (bus_master_i) ? wb_ext_stb_i  : wb_cpu_stb_i;
   wire                       wb_master_cyc_i  = (bus_master_i) ? wb_ext_cyc_i  : wb_cpu_cyc_i;

   wire [1:0] wb_periph_select = wb_master_addr_i[WB_DATA_WIDTH - 1:WB_DATA_WIDTH - 2];

   wire access_ram   = (WB_ACCESS_RAM == wb_periph_select);
   wire access_uart  = (WB_ACCESS_UART == wb_periph_select);
   wire access_timer = (WB_ACCESS_TIMER == wb_periph_select);

   assign wb_timer_addr_o = wb_master_addr_i;
   assign wb_timer_data_o = wb_master_data_i;
   assign wb_timer_we_o = wb_master_we_i;
   assign wb_timer_sel_o = wb_master_sel_i;
   assign wb_timer_stb_o = wb_master_stb_i & access_timer;
   assign wb_timer_cyc_o = wb_master_cyc_i & access_timer;

   assign wb_ram_addr_o = wb_master_addr_i;
   assign wb_ram_data_o = wb_master_data_i;
   assign wb_ram_we_o = wb_master_we_i;
   assign wb_ram_sel_o = wb_master_sel_i;
   assign wb_ram_stb_o = wb_master_stb_i & access_ram;
   assign wb_ram_cyc_o = wb_master_cyc_i & access_ram;

   assign wb_uart_addr_o = wb_master_addr_i;
   assign wb_uart_data_o = wb_master_data_i;
   assign wb_uart_we_o = wb_master_we_i;
   assign wb_uart_sel_o = wb_master_sel_i;
   assign wb_uart_stb_o = wb_master_stb_i & access_uart;
   assign wb_uart_cyc_o = wb_master_cyc_i & access_uart;

   assign wb_cpu_ack_o = (access_timer) ? wb_timer_ack_i :
                         (access_ram)   ? wb_ram_ack_i :
                         (access_uart)  ? wb_uart_ack_i : 0;
   
   assign wb_cpu_data_o = (access_timer) ? wb_timer_data_i :
                          (access_ram)   ? wb_ram_data_i   :
                          (access_uart)  ? wb_uart_data_i  : WB_WRONG_DATA;

   assign wb_ext_ack_o = (access_timer) ? wb_timer_ack_i :
                         (access_ram)   ? wb_ram_ack_i :
                         (access_uart)  ? wb_uart_ack_i : 0;
   
   assign wb_ext_data_o = (access_timer) ? wb_timer_data_i :
                          (access_ram)   ? wb_ram_data_i   :
                          (access_uart)  ? wb_uart_data_i  : WB_WRONG_DATA;
endmodule

