`include "cpu/busdefs.vh"

module wb_cpu_bus(
		input I_en,
		input[3:0] I_op,
		input[31:0] I_addr,
		input[31:0] I_data,
		output[31:0] O_data,
		output O_busy,

		// wired to outside world, RAM, devices etc.
		//naming of signals taken from Wishbone B4 spec
		input CLK_I,
		input ACK_I,
		input[31:0] DAT_I,
		input RST_I,
		output reg[31:0] ADR_O,
		output reg[31:0] DAT_O,
      output reg[3:0] SEL_O,
		output reg CYC_O,
		output reg STB_O,
		output reg WE_O
	);
   /*verilator public_module*/ 
		
   reg [3:0] op;

   always @ (posedge CLK_I) begin
      op <= (I_en) ? I_op : op;
   end


	reg[31:0] buffer;
	assign O_data = buffer;

	reg busy = 0;
	assign O_busy = busy;

   reg [3:0] mem_sel;
	
	wire[31:0] busaddr;
	assign busaddr = I_addr;
	reg signextend = 0;
	reg write = 0;

	always @(*) begin
		// determine number of bytes to be processed
		case(I_op)
			`BUSOP_READW, `BUSOP_WRITEW: mem_sel = 4'b1111;
			`BUSOP_READH, `BUSOP_READHU, `BUSOP_WRITEH: mem_sel = 4'b0011;
			`BUSOP_READT, `BUSOP_WRITET: mem_sel = 4'b0101;
			default: mem_sel = 4'b0001; // mem_sel = 4'b0001;
		endcase

		// determine if sign extension is requested
		case(op)
			`BUSOP_READBU, `BUSOP_READHU: signextend = 0;
			default: signextend = 1;
		endcase

		// determine if a write operation is requested
		case(I_op)
			`BUSOP_WRITEB, `BUSOP_WRITEH, `BUSOP_WRITEW, `BUSOP_WRITET: write = 1;
			default: write = 0;
		endcase
	end

   reg [31:0] test = 0;

   reg [31:0] data_from_bus;

   always @ (*) begin
      case (SEL_O)
         4'b1111: begin
            data_from_bus = DAT_I;
         end
         4'b0011: begin
            data_from_bus = {{16{DAT_I[15] & signextend}}, DAT_I[15:0]};
         end
         4'b0001: begin
            data_from_bus = {{24{DAT_I[7] & signextend}}, DAT_I[7:0]};
         end
         4'b0101: begin
            data_from_bus = {28'b0, DAT_I[3:0]};
         end
         default: begin
//            data_from_bus = 32'hDEADF001;
            data_from_bus = 0;
         end
      endcase
   end

	always @(posedge CLK_I) begin
		WE_O <= WE_O;
      SEL_O <= SEL_O;
      ADR_O <= ADR_O;
      DAT_O <= DAT_O;
      CYC_O <= CYC_O;
      STB_O <= STB_O;
      busy <= busy;

      buffer <= (ACK_I) ? data_from_bus : buffer;

      if (I_en) begin
			WE_O <= write;
         SEL_O <= mem_sel;
         ADR_O <= busaddr;
         DAT_O <= I_data;
         CYC_O <= !ACK_I;
         STB_O <= !ACK_I;
         busy <= 1;
      end

      if (ACK_I) begin
         CYC_O <= 0;
         STB_O <= 0;
         WE_O <= 0;
         busy <= 0;
         SEL_O <= 0;
      end

   end

endmodule
