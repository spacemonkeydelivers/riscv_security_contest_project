`include "cpu/busdefs.vh"

module wb_cpu_bus(
		input I_en,
		input[2:0] I_op,
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
			default: mem_sel = 4'b0001; // mem_sel = 4'b0001;
		endcase

		// determine if sign extension is requested
		case(I_op)
			`BUSOP_READBU, `BUSOP_READHU: signextend = 0;
			default: signextend = 1;
		endcase

		// determine if a write operation is requested
		case(I_op)
			`BUSOP_WRITEB, `BUSOP_WRITEH, `BUSOP_WRITEW: write = 1;
			default: write = 0;
		endcase
	end

	reg ack_rcvd = 0;

	always @(posedge CLK_I) begin
		WE_O <= 0;
      SEL_O <= 0;
      WE_O <= write;
      busy <= I_en;

		if(I_en)
      begin
         CYC_O <= !ack_rcvd;
         STB_O <= !ack_rcvd;
			WE_O <= write;
         SEL_O <= mem_sel;
         ADR_O <= busaddr;
         DAT_O <= I_data;
     end

      if (ACK_I)
      begin
         CYC_O <= 0;
         STB_O <= 0;
         ack_rcvd <= 1;
         WE_O <= 0;
      end

      if (ack_rcvd) begin
         ack_rcvd <= 0;
         busy <= 0;
      end

      case (mem_sel)
         4'b1111: begin
            buffer <= DAT_I;
         end
         4'b0011: begin
            buffer <= {{16{DAT_I[15] & signextend}}, DAT_I[15:0]};
         end
         4'b0001: begin
            buffer <= {{24{DAT_I[7] & signextend}}, DAT_I[7:0]};
         end
      endcase
   end

endmodule
