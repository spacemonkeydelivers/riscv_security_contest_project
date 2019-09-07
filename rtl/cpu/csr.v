`include "cpu/csrdefs.vh"
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
   input  wire [1:0]                  csr_operation_type_i, //write, set bits, clear bits
   input  wire [CSR_ADDR_WIDTH - 1:0] csr_addr_i,
   input  wire [CSR_DATA_WIDTH - 1:0] csr_data_i,
   output wire [CSR_DATA_WIDTH - 1:0] csr_data_o,
   output wire                        csr_busy_o,
   output wire                        csr_exists_o,
   output wire                        csr_ro_o
);
   
   localparam [1:0] STATE_CSR_IDLE_READ = 2'd0,
                    STATE_CSR_WRITE_REG = 2'd1,
                    STATE_CSR_STOP      = 2'd2,
                    STATE_CSR_WRONG     = 2'd3;
   reg [1:0] state;
   reg we;

   reg busy;
   assign csr_busy_o = busy;

   assign csr_exists_o = 1;


   localparam [1:0] CSR_OPER_READ  = 2'd0,
                    CSR_OPER_WRITE = 2'd1,
                    CSR_OPER_CLEAR = 2'd2,
                    CSR_OPER_WRONG = 2'd3;

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
                    M_LAST      = 13;

   reg [1:0] csr_op_type;

   always @ (posedge clk_i) begin
      if (rst_i) begin
         csr_op_type <= 0;
      end else begin
         csr_op_type <= (csr_en_i) ? csr_operation_type_i : csr_op_type;
      end
   end

   assign csr_ro_o = 0;
  
   reg [3:0] csr_index;
   always @(csr_addr_i) begin
      case (csr_addr_i)
         `MSR_MVENDORID: begin
            csr_index = M_VENDOR_ID;
         end
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
         default :        csr_index = M_VENDOR_ID;
      endcase
   end

   reg [CSR_DATA_WIDTH - 1:0] read_data;
   reg [CSR_DATA_WIDTH - 1:0] stored_data;
   wire [CSR_DATA_WIDTH - 1:0] write_data = (csr_op_type == CSR_OPER_WRITE) ? stored_data :
                                            (csr_op_type == CSR_OPER_READ)  ? read_data | stored_data :
                                            (csr_op_type == CSR_OPER_CLEAR) ? read_data & ~stored_data :
                                                                                       0;

   wire [CSR_DATA_WIDTH - 1:0] csr_data_out;
   assign csr_data_o = read_data;
    

   generic_ram
   #(
      .RAM_WORDS_SIZE (13), //mlast
      .RAM_WORDS_WIDTH (CSR_DATA_WIDTH)
   )
   csr0
   (
      .clk_i    (clk_i),
      .we_i     (we),
      .data_i   (write_data),
      .w_addr_i (csr_index),
      .r_addr_i (csr_index),
      .data_o   (csr_data_out)
   );
  
   always @ (posedge clk_i) begin
      if (rst_i) begin
         read_data <= 0;
      end
      else begin
         read_data <= ((state == STATE_CSR_IDLE_READ) && csr_en_i) ? csr_data_out : read_data;
      end
   end

   always @ (posedge clk_i) begin
      if (rst_i) begin
         stored_data <= 0;
      end
      else begin
         stored_data <= ((state == STATE_CSR_IDLE_READ) && csr_en_i) ? csr_data_i : stored_data;
      end
   end
  
   always @ (posedge clk_i) begin
      if (rst_i) begin
         state <= STATE_CSR_IDLE_READ;
         we <= 0;
         busy <= 0;
      end
      else begin
         case (state)
            STATE_CSR_IDLE_READ: begin
               state <= (csr_en_i) ? STATE_CSR_WRITE_REG : STATE_CSR_IDLE_READ;
               we <= 1'b0;
               busy <= (csr_en_i) ? 1 : 0;
            end
            STATE_CSR_WRITE_REG: begin
               state <= STATE_CSR_STOP;
               we <= 1;
               busy <= 1;
            end
            STATE_CSR_STOP: begin
               state <= STATE_CSR_IDLE_READ;
               we <= 0;
               busy <= 0;
            end
            default: begin
               state <= STATE_CSR_WRONG;
               we <= 0;
               busy <= 0;
            end
         endcase
      end
   end

endmodule


