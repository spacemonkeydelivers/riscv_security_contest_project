`ifndef BUSDEFS
	`define BUSDEFS 1

	`define BUSOP_READB	4'b0000
	`define BUSOP_READBU	4'b0001
	`define BUSOP_READH	4'b0010
	`define BUSOP_READHU	4'b0011
	`define BUSOP_READW	4'b0100
	`define BUSOP_READT	4'b1100

	`define BUSOP_WRITEB	4'b0101
	`define BUSOP_WRITEH	4'b0110
	`define BUSOP_WRITEW	4'b0111
	`define BUSOP_WRITET	4'b1111

`endif
