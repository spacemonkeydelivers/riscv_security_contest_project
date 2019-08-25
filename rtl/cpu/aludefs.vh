`ifndef ALUOPS
	`define ALUOPS 1

	`define ALUOP_ADD  5'b00000
	`define ALUOP_SUB  5'b00001
	`define ALUOP_AND  5'b00010
	`define ALUOP_OR   5'b00011
	`define ALUOP_XOR  5'b00100
	`define ALUOP_SLT  5'b00101
	`define ALUOP_SLTU 5'b00110
	`define ALUOP_SLL  5'b00111
	`define ALUOP_SRL  5'b01000
	`define ALUOP_SRA  5'b01001

    // RV32M
    `define ALUOP_MUL       5'b01010
    `define ALUOP_MULH      5'b01011
    `define ALUOP_MULHSU    5'b01100
    `define ALUOP_MULHU     5'b01101

    `define ALUOP_DIV  5'b01110
    `define ALUOP_DIVU 5'b01111
    `define ALUOP_REM  5'b10000
    `define ALUOP_REMU 5'b10001

	
`endif
