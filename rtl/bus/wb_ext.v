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
         data <= 32'hC0017A1E;
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
            data <= (wb_we) ? data : wb_data_i;
            wb_we <= 0;
         end
         if (transaction_clear_ready_i) begin
            tran_finished <= 0;
         end
      end
   end
endmodule


