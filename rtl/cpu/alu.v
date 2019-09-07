`include "cpu/aludefs.vh"

`define HW_DIVISION 1

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

    // mul
    reg[63:0] muluu;
    reg[63:0] mulss;
    reg[63:0] mulsu;

    reg[63:0] tmp_src1;
    reg[63:0] tmp_src2;
    reg[63:0] tmp_src2u;

    // div
    reg[32:0] div;
    reg[31:0] divu;
    reg[32:0] rem;
    reg[31:0] remu;
   
`define SINGLE_CYCLE_SHIFTER
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

    always @(*) begin
        tmp_src1 = { {32{I_dataS1[31]}}, I_dataS1[31:0]};
        tmp_src2 = { {32{I_dataS2[31]}}, I_dataS2[31:0]};
        tmp_src2u = { {32{1'b0}}, I_dataS2[31:0]};

        mulss = tmp_src1 * tmp_src2;
        muluu = I_dataS1 * I_dataS2;
        mulsu = tmp_src1 * tmp_src2u;
    end

    reg tmp_div;
    reg tmp_rem;
    always @(*) begin
       tmp_div = 0;
       tmp_rem = 0;
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
            /*if (rem[32]) begin
                rem = {2'b0, 31'b1};
            end*/
        end
    end
`endif

	always @(*) begin
		// unsigned comparison: simply look at underflow bit
		ltu = sub[32];
		// signed comparison: xor underflow bit with xored sign bit
		lt = (sub[32] ^ myxor[31]);
		
		eq = (sub === 33'b0);
	end
	
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
                // single-cycle multiplication :)
                `ALUOP_MUL: result <= mulss[31:0];
                `ALUOP_MULH: result <= mulss[63:32];
                `ALUOP_MULHSU: result <= mulsu[63:32];
                `ALUOP_MULHU: result <= muluu[63:32];
                // single-cycle division ;)
                `ALUOP_DIV: result <= div[31:0];
                `ALUOP_DIVU: result <= divu;
                `ALUOP_REM: result <= rem[31:0];
                `ALUOP_REMU: result <= remu;
`endif
			endcase

			O_lt <= lt;
			O_ltu <= ltu;
			O_eq <= eq;

		end
	end
		
endmodule
