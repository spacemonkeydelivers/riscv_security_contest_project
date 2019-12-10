module registers
#(
   parameter REG_FILE_SIZE  = 32,
   parameter REG_FILE_WIDTH = 32
)
(
   input I_clk,
   input [REG_FILE_WIDTH - 1:0] I_data,
   input [4:0] I_rs1,
   input [4:0] I_rs2,
   input [4:0] I_rd,
   input I_re,
   input I_we,
   output reg  [REG_FILE_WIDTH - 1:0] O_regval1,
   output reg  [REG_FILE_WIDTH - 1:0] O_regval2,
   output wire [REG_FILE_WIDTH - 1:0] register_flags_o
);
   /*verilator public_module*/ 

   task get_size
   (
      output int rf_size
   );
      begin
         rf_size = REG_FILE_SIZE;
      end
   endtask

   task read_word
   (
      input  int addr,
      output int word
   );
      begin
         word[REG_FILE_WIDTH - 1:0] = regfile[addr];
      end
   endtask

   task write_word
   (
      input int addr,
      input int word
   );
      begin
         regfile[addr] = word[REG_FILE_WIDTH - 1:0];
      end
   endtask

	reg [REG_FILE_WIDTH - 1:0] regfile [REG_FILE_SIZE - 1:0];

   genvar i;
   generate
      for (i = 0; i < REG_FILE_SIZE ; i = i + 1) begin
         assign register_flags_o[i] = (regfile[i] == 0);
      end
   endgenerate 

	wire read, write;

	assign read = I_re;
	assign write = I_we & (I_rd != 0);

	initial begin
		regfile[0] = 0;
	end
	
	always @ (posedge I_clk) begin
		if(write) regfile[I_rd] <= I_data;
		if(read) begin
			O_regval1 <= regfile[I_rs1];
			O_regval2 <= regfile[I_rs2];
		end
	end
	
	
endmodule
