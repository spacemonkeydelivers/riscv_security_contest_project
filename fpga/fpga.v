`timescale 1ns / 1ps
`define CHIP_SELECT_LOW_TO_HIGH  2'b01 // chip select pin switches from low to high
module fpga(
   inout wire  [DATA_WIDTH - 1:0] data_io, // input-output data bus
   input wire  [24:0] addr_i,              // input address bus
   input wire  read_i,                     // input read strobe
   input wire  write_i,                    // input write strobe
   input wire  [1:0] cs_i,                 // input chip select strobe
   input wire  clk_i,                      // input clk signal
   input wire  reset_i,                    // external reset signal, if low - reset
   input wire  irq_i,                      // external pin to irq to fpga
   output wire irq_o,                     // external pin to irq by fpga
   output wire [6:0] data_o               // leds out
);
   localparam DATA_WIDTH = 16;

   localparam [3:0] CONTROL_CPU_RESET      = 4'd0,
                    CONTROL_SOC_RESET      = 4'd1,
                    CONTROL_BUS_MASTER     = 4'd2,
                    CONTROL_TRAN_START     = 4'd3,
                    CONTROL_TRAN_WE        = 4'd4,
                    CONTROL_TRAN_CLEAN     = 4'd5,
                    CONTROL_TRAN_READY     = 4'd6,
                    CONTROL_TRAN_SIZE_LOW  = 4'd7,
                    CONTROL_TRAN_SIZE_HIGH = 4'd8;
   assign irq_o = 0;

   // latches to avoid metastability
   reg stage_1 = 0;
   reg stage_2 = 0;
   reg stage_3 = 0;

   //signal which controls tristate iobuf
   wire disable_io;
   assign disable_io = (read_i);
   wire chip_select = cs_i[0] && cs_i[1];

   // to deal with external io data bus
   wire [DATA_WIDTH - 1:0] data_from_cpu;
   reg  [DATA_WIDTH - 1:0] data_to_cpu = 0;

   // iobuf instance
   genvar y;
   generate
   for(y = 0; y < DATA_WIDTH; y = y + 1 ) 
   begin : iobuf_generation
      IOBUF io_y (
         .I( data_to_cpu[y] ),
         .O( data_from_cpu[y] ),
         .IO( data_io[y] ),
         .T ( disable_io )
      );
   end
   endgenerate

   // becomes true if chip select was switched from low to high
   wire iface_accessed = {stage_2, stage_3} == `CHIP_SELECT_LOW_TO_HIGH;

   // always loop to detect if fpga-to-arm iface is accessed
   always @ (posedge clk_i)
   begin
      if (!reset_i)
      begin
         {stage_1, stage_2, stage_3} <= 0;
      end
      else
      begin
         {stage_1, stage_2, stage_3} <= {chip_select, stage_1, stage_2};
      end
   end
   
   wire [2:0] addr = addr_i[3:1];
   localparam [2:0] REG_SANITY        = 3'd0,
                    REG_LOW_ADDR      = 3'd1,
                    REG_HIGH_ADDR     = 3'd2,
                    REG_LOW_DATA_IN   = 3'd3,
                    REG_HIGH_DATA_IN  = 3'd4,
                    REG_CONTROL       = 3'd5,
                    REG_LOW_DATA_OUT  = 3'd6,
                    REG_HIGH_DATA_OUT = 3'd7;

   reg [15:0] regs_internal [0:7];


   wire [15:0] data_from_soc_low;
   wire [15:0] data_from_soc_high;
   wire [15:0] to_cpu = (addr == REG_LOW_DATA_OUT)  ? data_from_soc_low :
                        (addr == REG_HIGH_DATA_OUT) ? data_from_soc_high :
                        (addr == REG_CONTROL)       ? {regs_internal[addr][15:7], tran_ready, regs_internal[addr][5:0]} :
                                                      regs_internal[addr];
   
   wire [31:0] addr_to_soc = {regs_internal[REG_HIGH_ADDR], regs_internal[REG_LOW_ADDR]};
   wire [31:0] data_to_soc = {regs_internal[REG_HIGH_DATA_IN], regs_internal[REG_LOW_DATA_IN]};
   wire [1:0]  size_to_soc = {regs_internal[REG_CONTROL][CONTROL_TRAN_SIZE_HIGH], regs_internal[REG_CONTROL][CONTROL_TRAN_SIZE_LOW]};
   
   wire uart_rx;
   wire uart_tx;

   assign data_o[0] = regs_internal[REG_CONTROL][CONTROL_CPU_RESET];
   assign data_o[1] = regs_internal[REG_CONTROL][CONTROL_SOC_RESET];
   assign data_o[2] = regs_internal[REG_CONTROL][CONTROL_BUS_MASTER];
   assign data_o[3] = regs_internal[REG_CONTROL][CONTROL_TRAN_START];
   assign data_o[4] = regs_internal[REG_CONTROL][CONTROL_TRAN_READY];
   assign data_o[5] = uart_rx;
   assign data_o[6] = uart_tx;

   wire tran_ready;
   soc
   soc0
   (
      .clk_i (clk_i),
      .cpu_rst_i (regs_internal[REG_CONTROL][CONTROL_CPU_RESET]),
      .rst_i (regs_internal[REG_CONTROL][CONTROL_SOC_RESET]),
      .uart_rx_i (uart_rx),
      .uart_tx_o (uart_tx),
      .bus_master_selector_i (regs_internal[REG_CONTROL][CONTROL_BUS_MASTER]),
      .ext_tran_addr_i (addr_to_soc),
      .ext_tran_data_i (data_to_soc),
      .ext_tran_size_i (size_to_soc),
      .ext_tran_start_i (regs_internal[REG_CONTROL][CONTROL_TRAN_START]),
      .ext_tran_write_i (regs_internal[REG_CONTROL][CONTROL_TRAN_WE]),
      .ext_tran_clear_i (regs_internal[REG_CONTROL][CONTROL_TRAN_CLEAN]),
      .ext_tran_data_o ({data_from_soc_high, data_from_soc_low}),
      .ext_tran_ready_o (tran_ready)
   );

   // always loop to deal with fpga-to-arm iface data
   always @ (posedge clk_i)
   begin
      if (!reset_i) begin
         data_to_cpu <= 0;
         regs_internal[REG_SANITY] <= 16'h50FE;
         regs_internal[REG_LOW_DATA_IN]  <= 0;
         regs_internal[REG_HIGH_DATA_IN] <= 0;
         regs_internal[REG_LOW_DATA_OUT]  <= 0;
         regs_internal[REG_HIGH_DATA_OUT] <= 0;
         regs_internal[REG_LOW_ADDR] <= 0;
         regs_internal[REG_HIGH_ADDR] <= 0;
         regs_internal[REG_CONTROL] <= 0;
      end
      else begin
         if (iface_accessed) begin
            if (!read_i) begin
               data_to_cpu <= to_cpu;
            end
            if (!write_i) begin
               regs_internal[addr] <= data_from_cpu;
               if (regs_internal[REG_CONTROL][CONTROL_TRAN_CLEAN]) begin
                  regs_internal[REG_CONTROL][CONTROL_TRAN_CLEAN] <= 0;
               end
               if (regs_internal[REG_CONTROL][CONTROL_TRAN_START]) begin
                  regs_internal[REG_CONTROL][CONTROL_TRAN_START] <= 0;
               end
            end
         end
         if (regs_internal[REG_CONTROL][CONTROL_TRAN_START]) begin
            regs_internal[REG_CONTROL][CONTROL_TRAN_START] <= 1'b0;
         end
      end
   end
   
endmodule
