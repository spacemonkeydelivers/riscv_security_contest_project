`include "cpu/csrdefs.vh"
`include "cpu/lfsr_rnd.v"
//`include "ram/generic_ram.v"

module csr
#(
   parameter CSR_DATA_WIDTH = 32,
   parameter CSR_ADDR_WIDTH = 12
)
(
   input  wire                        clk_i,
   input  wire                        rst_i,
   input  wire                        csr_en_i,
   input  wire                        csr_we_i,
   input  wire [CSR_ADDR_WIDTH - 1:0] csr_addr_i,
   input  wire [CSR_DATA_WIDTH - 1:0] csr_data_i,
   output wire [CSR_DATA_WIDTH - 1:0] csr_data_o,
   output wire                        csr_busy_o,
   output wire                        csr_exists_o,
   output wire                        csr_ro_o,
   output wire                        csr_irq_en_o,
   output wire                        csr_irq_timer_en_o,
   output wire                        csr_tags_en_o,
   output wire                        csr_tags_if_en_o,
   output wire                        csr_tags_skip_sp_en_o,
   output wire                        csr_tags_irq_clear_o
);
   // RND instance
   wire [CSR_DATA_WIDTH - 1:0] rnd_data;

   lfsr_rnd lfsr_rnd_inst
   (
      .I_clk (clk_i),
      .I_reset (rst_i),
      .O_rnd (rnd_data)
   );

   assign csr_exists_o = 1;
   assign csr_ro_o = 0;
   assign csr_busy_o = busy;

   reg irq_en;
   assign csr_irq_en_o = irq_en;
   reg irq_timer_en;
   assign csr_irq_timer_en_o = irq_timer_en;
   reg tags_en;
   assign csr_tags_en_o = tags_en;
   reg tags_if_en;
   assign csr_tags_if_en_o = tags_if_en;
   reg tags_skip_sp_en;
   assign csr_tags_skip_sp_en_o = tags_skip_sp_en;
   reg tags_irq_clear;
   assign csr_tags_irq_clear_o = tags_irq_clear;

   always @ (posedge clk_i) begin
      if (rst_i) begin
         irq_en <= 0;
         irq_timer_en <= 0;
         tags_en <= 0;
         tags_if_en <= 0;
         tags_if_en <= 0;
         tags_irq_clear <= 0;
      end else begin
         if (csr_we_i) begin
            irq_en <= (csr_addr_i == `MSR_MSTATUS) ? csr_data_i[3] : irq_en;
            tags_en <= (csr_addr_i == `MSR_MTAGS) ? csr_data_i[0] : tags_en;
            tags_if_en <= (csr_addr_i == `MSR_MTAGS) ? csr_data_i[2] : tags_if_en;
            tags_skip_sp_en <= (csr_addr_i == `MSR_MTAGS) ? csr_data_i[3] : tags_skip_sp_en;
            irq_timer_en <= (csr_addr_i == `MSR_MIE) ? csr_data_i[7] : irq_timer_en;
         end
         tags_irq_clear <= (csr_addr_i == `MSR_MTAGS) ? csr_data_i[1] : 1'b0;
      end
   end
   
   localparam [3:0] M_VENDOR_ID = 0,
                    M_HART_ID   = 1,
                    M_STATUS    = 2,
                    M_ISA       = 3,
                    M_IE        = 4,
                    M_TVEC      = 5,
                    M_COUNTEREN = 6,
                    M_SCRATCH   = 7,
                    M_EPC       = 8,
                    M_CAUSE     = 9,
                    M_TVAL      = 10,
                    M_IP        = 11,
                    M_TAGS      = 12,
                    M_RND       = 13,
                    M_LAST      = 14;


   reg [3:0] csr_index;
   always @(*) begin
      case (stored_addr)
         `MSR_MVENDORID:  csr_index = M_VENDOR_ID;
         `MSR_MHARTID:    csr_index = M_HART_ID;
         `MSR_MSTATUS:    csr_index = M_STATUS;
         `MSR_MISA:       csr_index = M_ISA;
         `MSR_MIE:        csr_index = M_IE;
         `MSR_MTVEC:      csr_index = M_TVEC;
         `MSR_MCOUNTEREN: csr_index = M_COUNTEREN;
         `MSR_MSCRATCH:   csr_index = M_SCRATCH;
         `MSR_MEPC:       csr_index = M_EPC;
         `MSR_MCAUSE:     csr_index = M_CAUSE;
         `MSR_MTVAL:      csr_index = M_TVAL;
         `MSR_MIP:        csr_index = M_IP;
         `MSR_MTAGS:      csr_index = M_TAGS;
         `MSR_MRND:       csr_index = M_RND;
         default :        csr_index = M_VENDOR_ID;
      endcase
   end
   
   reg we;
   reg busy;
   reg [CSR_ADDR_WIDTH - 1:0] stored_addr;
   reg [CSR_DATA_WIDTH - 1:0] stored_data;

   wire [CSR_DATA_WIDTH - 1:0] csr_data_out;
   assign csr_data_o = (csr_index == M_RND) ? rnd_data : csr_data_out;

   generic_ram
   #(
      .RAM_WORDS_SIZE (13), //mlast
      .RAM_WORDS_WIDTH (CSR_DATA_WIDTH)
   )
   csr0
   (
      .clk_i    (clk_i),
      .we_i     (we),
      .data_i   (stored_data),
      .w_addr_i (csr_index),
      .r_addr_i (csr_index),
      .data_o   (csr_data_out)
   );
  
   
   always @ (posedge clk_i) begin
      if (rst_i) begin
         we <= 0;
         busy <= 0;
      end
      else begin
         if (csr_en_i) begin
            busy <= 1;
            stored_addr <= csr_addr_i;
            stored_data <= csr_data_i;
            we <= csr_we_i;
         end
         if (busy) begin
            busy <= 0;
            we <= 0;
         end
      end
   end


endmodule


