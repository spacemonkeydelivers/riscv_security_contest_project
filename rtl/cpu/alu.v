`include "cpu/aludefs.vh"

`define HW_DIVISION 1
// `define SINGLE_CYCLE_MULTIPLICATION 1
// `define SINGLE_CYCLE_DIVISION 1


module alu(
	input I_clk,
	input I_en,
	input I_reset,
	input[31:0] I_dataS1,
	input[31:0] I_dataS2,
	input [4:0] I_aluop,
	output O_busy,
	output[31:0] O_data,
	output reg O_lt,
	output reg O_ltu,
	output reg O_eq);

   /*verilator public_module*/

	reg[31:0] result, sum, myor, myxor, myand;
	reg[32:0] sub; // additional bit for underflow detection
	reg eq, lt, ltu, busy = 0;
	reg[4:0] shiftcnt;

	assign O_data = result;

`ifdef HW_DIVISION
    // common mul-div wires
    wire [31:0] pos_src1;
    wire [31:0] pos_src2;
    assign pos_src1 = I_dataS1[31] ? -I_dataS1 : I_dataS1;
    assign pos_src2 = I_dataS2[31] ? -I_dataS2 : I_dataS2;

    wire sign;
    assign sign = I_dataS1[31] ^ I_dataS2[31];

    // mul
    `ifdef SINGLE_CYCLE_MULTIPLICATION
    reg[63:0] muluu;
    reg[63:0] mulss;
    reg[63:0] mulsu;

    reg[63:0] tmp_src1;
    reg[63:0] tmp_src2;
    reg[63:0] tmp_src2u;
    `else
    reg[63:0] product;
    reg[31:0] mulcand;
    wire [32:0] top_prod;

    wire[63:0] neg_product;
    assign neg_product = -product;
    `endif

    // div
    `ifdef SINGLE_CYCLE_DIVISION
    reg[32:0] div;
    reg[31:0] divu;
    reg[32:0] rem;
    reg[31:0] remu;
    `else
    reg[63:0] dividend_copy, divider_copy;
    wire [63:0] diff;
    assign diff = dividend_copy - divider_copy;
    `endif
`endif

//`define SINGLE_CYCLE_SHIFTER
`ifdef SINGLE_CYCLE_SHIFTER
	wire[31:0] sll, srl, sra;
	wire signed[31:0] I_dataS1_signed;
	assign I_dataS1_signed[31:0] = I_dataS1[31:0];
	assign sll = (I_dataS1 << I_dataS2[4:0]);
	assign srl = (I_dataS1 >> I_dataS2[4:0]);
	assign sra = (I_dataS1_signed >>> I_dataS2[4:0]);
	assign O_busy = 0;
`else
	assign O_busy = busy;
`endif

	always @(*) begin
		sum = I_dataS1 + I_dataS2;
		sub = {1'b0, I_dataS1} - {1'b0, I_dataS2};

		myor = I_dataS1 | I_dataS2;
		myxor = I_dataS1 ^ I_dataS2;
		myand = I_dataS1 & I_dataS2;
    end

`ifdef HW_DIVISION
    `ifdef SINGLE_CYCLE_MULTIPLICATION
    always @(*) begin
        tmp_src1 = { {32{I_dataS1[31]}}, I_dataS1[31:0]};
        tmp_src2 = { {32{I_dataS2[31]}}, I_dataS2[31:0]};
        tmp_src2u = { {32{1'b0}}, I_dataS2[31:0]};

        mulss = tmp_src1 * tmp_src2;
        muluu = I_dataS1 * I_dataS2;
        mulsu = tmp_src1 * tmp_src2u;
    end
    `else
    wire lsb;
    reg[5:0] bit_mul;
    initial bit_mul = 0;
    assign top_prod = product[63:32] + mulcand;
    assign lsb = product[0];
    `endif

    `ifdef SINGLE_CYCLE_DIVISION
    always @(*) begin
        if(I_dataS2 == { 32{1'b0} } ) begin
            div = {1'b0, {32{1'b1}}};
            divu = {32{1'b1}};
            rem = {1'b0, I_dataS1};
            remu = I_dataS1;
        end else begin
            divu = I_dataS1 / I_dataS2;
            remu = I_dataS1 % I_dataS2;
            div = $signed({I_dataS1[31], I_dataS1}) / $signed({I_dataS2[31], I_dataS2});
            rem = $signed({I_dataS1[31], I_dataS1}) % $signed({I_dataS2[31], I_dataS2});
        end
    end
    `else
    reg[5:0] bit_div;
    initial bit_div = 0;
    `endif
`endif

	always @(*) begin
		// unsigned comparison: simply look at underflow bit
		ltu = sub[32];
		// signed comparison: xor underflow bit with xored sign bit
		lt = (sub[32] ^ myxor[31]);

		eq = (sub === 33'b0);
	end

   wire first_corner_case = (&I_dataS1 && ((I_dataS2[31] && !(|I_dataS1[30:0])) || (!I_dataS2[31] && &I_dataS2[30:0])));

	always @(posedge I_clk) begin
		if(I_reset) begin
			busy <= 0;
		end else if(I_en || busy) begin
			case(I_aluop)
                default: result <= sum; // ALUOP_ADD
                `ALUOP_SUB: result <= sub[31:0];
                `ALUOP_AND: result <= myand;
                `ALUOP_OR:  result <= myor;
                `ALUOP_XOR: result <= myxor;

                `ALUOP_SLT: begin
                    result <= 0;
                    if(lt) result[0] <= 1;
                end

                `ALUOP_SLTU: begin
                    result <= 0;
                    if(ltu) result[0] <= 1;
                end

                `ifndef SINGLE_CYCLE_SHIFTER
                // multi-cycle shifting, slow, but compact
                `ALUOP_SLL, `ALUOP_SRL, `ALUOP_SRA: begin
                    if(!busy) begin
                        busy <= 1;
                        result <= I_dataS1;
                        shiftcnt <= I_dataS2[4:0];
                    end else if(shiftcnt !== 5'b00000) begin
                        case(I_aluop)
                            `ALUOP_SLL: result <= {result[30:0], 1'b0};
                            `ALUOP_SRL: result <= {1'b0, result[31:1]};
                            default: result <= {result[31], result[31:1]};
                        endcase
                        shiftcnt <= shiftcnt - 5'd1;
                    end else begin
                        busy <= 0;
                    end
                end
                `else
                // single-cycle shifting
                `ALUOP_SLL: result <= sll;
                `ALUOP_SRA: result <= sra;
                `ALUOP_SRL: result <= srl;
                `endif
`ifdef HW_DIVISION
                `ifdef SINGLE_CYCLE_MULTIPLICATION
                // single-cycle multiplication :)
                `ALUOP_MUL: result <= mulss[31:0];
                `ALUOP_MULH: result <= mulss[63:32];
                `ALUOP_MULHSU: result <= mulsu[63:32];
                `ALUOP_MULHU: result <= muluu[63:32];
                `else
                // multi-cycle multiplication
                `ALUOP_MUL, `ALUOP_MULH, `ALUOP_MULHSU, `ALUOP_MULHU: begin
                    if (!busy) begin
                        busy <= 1;
                        bit_mul <= 32;
                        case(I_aluop)
                            `ALUOP_MUL, `ALUOP_MULH: begin
                                product <= {32'd0, pos_src1};
                                mulcand <= pos_src2;
                            end
                            `ALUOP_MULHSU: begin
                                product <= {32'd0, pos_src1};
                                mulcand <= I_dataS2;
                            end
                            default: begin
                                product <= {32'd0, I_dataS1};
                                mulcand <= I_dataS2;
                            end
                        endcase
                    end else if(|bit_mul) begin
                        if(lsb) begin
                            product <= {top_prod, product[31:1]};
                        end else begin
                            product <= product >> 1;
                        end
                        bit_mul <= bit_mul - 1;
                    end else begin
                        case(I_aluop)
                            `ALUOP_MUL: result <= {sign ? neg_product[31:0] : product[31:0]};
                            `ALUOP_MULH: result <= {sign ? neg_product[63:32] : product[63:32]};
                            `ALUOP_MULHSU: result <= {(I_dataS1[31]) ? neg_product[63:32] : product[63:32]};
                            default: result <= product[63:32];
                        endcase
                        busy <= 0;
                    end
                end
                `endif
                `ifdef SINGLE_CYCLE_DIVISION
                // single-cycle division ;)
                `ALUOP_DIV: result <= div[31:0];
                `ALUOP_DIVU: result <= divu;
                `ALUOP_REM: result <= rem[31:0];
                `ALUOP_REMU: result <= remu;
                `else
                // multi-cycle division
                `ALUOP_DIV, `ALUOP_REM, `ALUOP_DIVU, `ALUOP_REMU: begin
                    if (!busy) begin
                       if(I_dataS2 == 32'd0) begin
                          case(I_aluop)
                             `ALUOP_DIV, `ALUOP_DIVU: result <= ~0;
                             default: result <= I_dataS1;
                          endcase
                       end else if (((I_dataS1 == 32'hffffffff && (I_dataS2 == 32'h80000000 || I_dataS2 == 32'h7fffffff)) ||
                          (I_dataS1 == 32'h80000000 && I_dataS2 == 32'h7fffffff)) &&
                          I_aluop == `ALUOP_REM) begin
                             result <= ~0;
                       end else begin
                          busy <= 1;
                          result <= 0;
                          bit_div <= 32;
                          if(I_aluop == `ALUOP_DIVU || I_aluop == `ALUOP_REMU) begin
                             dividend_copy <= {32'd0,I_dataS1};
                             divider_copy <= {1'b0,I_dataS2,31'd0};
                          end else begin
                             dividend_copy <= {32'd0,pos_src1};
                             divider_copy <= {1'b0,pos_src2,31'd0};
                          end
                       end
                    end else if(|bit_div) begin
                       if (!diff[63]) begin
                          dividend_copy <= diff;
                          result <= {result[30:0], 1'b1};
                       end else begin
                          result <= {result[30:0], 1'b0};
                       end
                       divider_copy <= {1'b0, divider_copy[63:1]};
                       bit_div <= bit_div - 1;
                    end else begin
                       case(I_aluop)
                          `ALUOP_DIV: result <= sign ? -result : result;
                          `ALUOP_DIVU: result <= result;
                          default: result <= dividend_copy[31:0];
                       endcase
                       busy <= 0;
                    end
                end
                `endif
`endif
            endcase

         O_lt <= lt;
         O_ltu <= ltu;
         O_eq <= eq;

		end
	end
endmodule
