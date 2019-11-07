module registers
(
   input I_clk,
   input [31:0] I_data,
   input [4:0] I_rs1,
   input [4:0] I_rs2,
   input [4:0] I_rd,
   input I_re,
   input I_we,
   output reg  [31:0] O_regval1,
   output reg  [31:0] O_regval2,
   output wire [31:0] register_flags_o
);
   /*verilator public_module*/ 

	reg [31:0] regfile [31:0];

   genvar i;
   generate
      for (i = 0; i < 32 ; i = i + 1) begin
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
