`include "cpu/riscvdefs.vh"
`include "cpu/aludefs.vh"
`include "cpu/cpudefs.vh"

/*
CR type: .insn cr opcode2, func4, rd, rs2
     +---------+--------+-----+---------+
     |   func4 | rd/rs1 | rs2 | opcode2 |
     +---------+--------+-----+---------+
     15        12       7     2        0
CI type: .insn ci opcode2, func3, rd, simm6
     +---------+-----+--------+-----+---------+
     |   func3 | imm | rd/rs1 | imm | opcode2 |
     +---------+-----+--------+-----+---------+
     15        13    12       7     2         0
CIW type: .insn ciw opcode2, func3, rd, uimm8
     +---------+--------------+-----+---------+
     |   func3 |          imm | rd' | opcode2 |
     +---------+--------------+-----+---------+
     15        13             7     2         0
CA type: .insn ca opcode2, func6, func2, rd, rs2
     +---------+----------+-------+------+--------+
     |   func6 | rd'/rs1' | func2 | rs2' | opcode |
     +---------+----------+-------+------+--------+
     15        10         7       5      2        0
CB type: .insn cb opcode2, func3, rs1, symbol
     +---------+--------+------+--------+---------+
     |   func3 | offset | rs1' | offset | opcode2 |
     +---------+--------+------+--------+---------+
     15        13       10     7        2         0
CJ type: .insn cj opcode2, symbol
     +---------+--------------------+---------+
     |   func3 |        jump target | opcode2 |
     +---------+--------------------+---------+
     15        13             7     2         0
*/
module decoder
(
   input  wire        I_clk,
   input  wire        I_en,
   input  wire [31:0] I_instr,
   output wire [4:0]  O_rs1,
   output wire [4:0]  O_rs2,
   output wire [4:0]  O_rd,
   output wire [31:0] O_imm,
   output reg  [5:0]  O_branchmask,
   output wire [4:0]  alu_oper_o,
   output wire        exec_mux_alu_s1_sel_o,
   output wire [1:0]  exec_mux_alu_s2_sel_o,
   output wire [2:0]  exec_next_stage_o,
   output wire        exec_writeback_from_alu_o,
   output wire        exec_writeback_from_imm_o,
   output wire        exec_next_pc_from_alu_o,
   output wire [1:0]  exec_mux_reg_input_sel_o,
   output wire [2:0]  funct3_o,
   output wire        write_reg_o
);
   /*verilator public_module*/ 

   wire [4:0] opcode = I_instr[6:2];
   reg [31:0] imm;

   assign O_imm = imm;

   // combinatorial decode of source register information to allow for register read during decode
   reg[4:0] o_rs1;
   reg[4:0] o_rs2;
   reg[4:0] o_rd;

   assign O_rs1 = o_rs1;
   assign O_rs2 = o_rs2;
   assign O_rd = o_rd;
   /*
   assign O_rs1 = I_instr[19:15];
   assign O_rs2 = I_instr[24:20];
   assign O_rd = I_instr[11:7];
   */

   assign funct3_o = funct3;

   reg isbranch = 0;

   wire [1:0] c_op   = I_instr[1:0];
   wire [6:0] funct7 = I_instr[31:25];
   wire [2:0] funct3 = (I_instr[1:0] == 2'b11) ?  I_instr[14:12] : `FUNC_LW;

   wire [2:0] c_funct3 = I_instr[15:13];
   wire [3:0] c_funct4 = I_instr[15:12];

   always @(*) begin
       case (c_op)
           2'b11: begin
               case(opcode)
                   `OP_STORE: imm = {{20{I_instr[31]}}, I_instr[31:25], I_instr[11:8], I_instr[7]}; // S-type
                   `OP_BRANCH: imm = {{19{I_instr[31]}}, I_instr[31], I_instr[7], I_instr[30:25], I_instr[11:8], 1'b0}; // SB-type
                   `OP_LUI, `OP_AUIPC: imm = {I_instr[31:12], {12{1'b0}}};
                   `OP_JAL: imm = {{11{I_instr[31]}}, I_instr[31], I_instr[19:12], I_instr[20], I_instr[30:25], I_instr[24:21], 1'b0}; // UJ-type
                   default: imm = {{20{I_instr[31]}}, I_instr[31:20]}; // I-type and R-type. Immediate has no meaning for R-type I_instructions
               endcase
           end
           2'b10: begin
/*
| 15 14 13 | 12        | 11 10 9 8 7 | 6 5 4 3 2    | 1 0  |
|      010 | uimm[5]   | rd!=0       | uimm[4:2;7:6]|  10 | C.LWSP (RES, rd=0)
*/
               imm = 0;
               if (c_funct3  == `C2_F3_LWSP) begin
                   imm = { 24'b0, I_instr[3:2], I_instr[12], I_instr[6:4], 2'b00 } ;
               end
/*
    | 15 14 13 | 12        | 11 10 9 8 7 | 6 5 4 3 2    | 1 0  |
c|  |   110    |      uimm[5:2;7:6]      | rs2          |  10  | C.SWSP
*/
               if (c_funct3  == `C2_F3_SWSP) begin
                   imm = { 24'b0, I_instr[8:7],  I_instr[12:9], 2'b00 } ;
               end

/*
    | 15 14 13 | 12        | 11 10 9 8 7 | 6 5 4 3 2    | 1 0  |
c|  |   000    | nzuimm[5] | rs1/rd!=0   | nzuimm[4:0]  |  10  | C.SLLI (HINT, rd=0; RV32 NSE, nzuimm[5]=1)
*/
               if (c_funct3 == `C2_F3_SLLI) begin
                   imm = { 27'b0, I_instr[6:2]} ;
               end
           end
           2'b01: begin
               imm = 0;
           end
           2'b00: begin
               imm = 0;
/*
    | 15 14 13 | 12        | 11 10|9 8 7| 6 5      | 4 3 2 | 1 0 |
 -  |    000   | nzuimm[5:4;9:6;2;3]               | rd   | 00  | C.ADDI4SPN (RES, nzuimm=0)
*/
                if (c_funct3 == `C0_F3_ADDI4SPN) begin
                    imm = 0;
                end
                else begin
/*
    | 15 14 13 | 12          11 10|9 8 7| 6 5      | 4 3 2 | 1 0 |
 -  |    010   | uimm[5:3]        | rs1 | uimm[2;6]| rd   | 00  | C.LW
*/
/*
    | 15 14 13 | 12          11 10|9 8 7| 6 5      | 4 3 2 | 1 0 |
 -  |    110   | uimm[5:3]        | rs1 | uimm[2;6]| rs2  | 00  | C.SW
*/
                    imm = { 25'b0, I_instr[5], I_instr[12:10], I_instr[6], 2'b00 };
                end
           end
       endcase

      isbranch = (opcode == `OP_BRANCH);
      O_branchmask = 0;
      case(funct3)
         `FUNC_BEQ:  O_branchmask[0] = isbranch;
         `FUNC_BNE:  O_branchmask[1] = isbranch;
         `FUNC_BLT:  O_branchmask[2] = isbranch;
         `FUNC_BGE:  O_branchmask[3] = isbranch;
         `FUNC_BLTU: O_branchmask[4] = isbranch;
         `FUNC_BGEU: O_branchmask[5] = isbranch;
         default:    O_branchmask    = 6'b0;
      endcase
   end

   reg [4:0] alu_oper;
   reg exec_mux_alu_s1_sel;
   reg [1:0] exec_mux_alu_s2_sel;
   reg [2:0] exec_next_stage;
   reg exec_writeback_from_alu;
   reg exec_writeback_from_imm;
   reg exec_next_pc_from_alu;
   reg [1:0] exec_mux_reg_input_sel;
   reg write_reg;
   assign alu_oper_o = alu_oper;
   assign exec_mux_alu_s1_sel_o = exec_mux_alu_s1_sel;
   assign exec_mux_alu_s2_sel_o = exec_mux_alu_s2_sel;
   assign exec_next_stage_o = exec_next_stage;
   assign exec_writeback_from_alu_o = exec_writeback_from_alu;
   assign exec_writeback_from_imm_o = exec_writeback_from_imm;
   assign exec_next_pc_from_alu_o = exec_next_pc_from_alu;
   assign exec_mux_reg_input_sel_o = exec_mux_reg_input_sel;
   assign write_reg_o = write_reg;

   always @ (*) begin

      o_rs1 = I_instr[19:15];
      o_rs2 = I_instr[24:20];
      o_rd = I_instr[11:7];

      exec_writeback_from_imm = 0;
      exec_writeback_from_alu = 0;
      exec_next_pc_from_alu = 0;
      exec_mux_reg_input_sel = 0;
      exec_mux_alu_s2_sel = 0;
      exec_mux_alu_s1_sel = 0;
      alu_oper = `ALUOP_ADD;
      write_reg = 0;
    if (c_op == 2'b11) begin
      case(opcode)
         `OP_OP: begin
            exec_mux_alu_s1_sel = `MUX_ALUDAT1_REGVAL1;
            exec_mux_alu_s2_sel = `MUX_ALUDAT2_REGVAL2;
            case(funct3)
               `FUNC_ADD_SUB:  begin
                  case(funct7)
                     7'b0100000:     alu_oper = `ALUOP_SUB;
                     `FUNC7_MUL_DIV: alu_oper = `ALUOP_MUL;
                     default:        alu_oper = `ALUOP_ADD;
                  endcase
               end
               `FUNC_SLL:      begin
                  case(funct7)
                     `FUNC7_MUL_DIV: alu_oper = `ALUOP_MULH;
                     default:        alu_oper = `ALUOP_SLL;
                  endcase
               end
               `FUNC_SLT:      begin
                  case(funct7)
                     `FUNC7_MUL_DIV: alu_oper = `ALUOP_MULHSU;
                     default:        alu_oper = `ALUOP_SLT;
                  endcase
               end
               `FUNC_SLTU:     begin
                  case(funct7)
                     `FUNC7_MUL_DIV: alu_oper = `ALUOP_MULHU;
                     default:        alu_oper = `ALUOP_SLTU;
                  endcase
               end
               `FUNC_XOR:      begin
                  case(funct7)
                     `FUNC7_MUL_DIV: alu_oper = `ALUOP_DIV;
                     default:        alu_oper = `ALUOP_XOR;
                  endcase
               end
               `FUNC_SRL_SRA:  begin
                  case(funct7)
                     7'b0100000:     alu_oper = `ALUOP_SRA;
                     `FUNC7_MUL_DIV: alu_oper = `ALUOP_DIVU;
                     default:        alu_oper = `ALUOP_SRL;
                  endcase
               end
               `FUNC_OR:       begin
                  case(funct7)
                     `FUNC7_MUL_DIV: alu_oper = `ALUOP_REM;
                     default:        alu_oper = `ALUOP_OR;
                  endcase
               end
               `FUNC_AND:      begin
                  case(funct7)
                     `FUNC7_MUL_DIV: alu_oper = `ALUOP_REMU;
                     default:        alu_oper = `ALUOP_AND;
                  endcase
               end
               default:        alu_oper = `ALUOP_ADD;
            endcase
            // do register writeback in FETCH
            exec_writeback_from_alu = 1;
            exec_next_stage = `EXEC_TO_FETCH;
         end

         `OP_OPIMM: begin
            exec_mux_alu_s1_sel = `MUX_ALUDAT1_REGVAL1;
            exec_mux_alu_s2_sel = `MUX_ALUDAT2_IMM;
            case(funct3)
               `FUNC_ADDI:         alu_oper = `ALUOP_ADD;
               `FUNC_SLLI:         alu_oper = `ALUOP_SLL;
               `FUNC_SLTI:         alu_oper = `ALUOP_SLT;
               `FUNC_SLTIU:        alu_oper = `ALUOP_SLTU;
               `FUNC_XORI:         alu_oper = `ALUOP_XOR;
               `FUNC_SRLI_SRAI:    alu_oper = funct7[5] ? `ALUOP_SRA : `ALUOP_SRL;
               `FUNC_ORI:          alu_oper = `ALUOP_OR;
               `FUNC_ANDI:         alu_oper = `ALUOP_AND;
               default:            alu_oper = `ALUOP_ADD;
            endcase
            // do register writeback in FETCH
            exec_writeback_from_alu = 1;
            exec_next_stage = `EXEC_TO_FETCH;
         end

         `OP_LOAD: begin // compute load address on ALU
            alu_oper = `ALUOP_ADD;
            exec_mux_alu_s1_sel = `MUX_ALUDAT1_REGVAL1;
            exec_mux_alu_s2_sel = `MUX_ALUDAT2_IMM;
            exec_next_stage = `EXEC_TO_LOAD;
         end

         `OP_STORE:  begin // compute store address on ALU
            alu_oper = `ALUOP_ADD;
            exec_mux_alu_s1_sel = `MUX_ALUDAT1_REGVAL1;
            exec_mux_alu_s2_sel = `MUX_ALUDAT2_IMM;
            exec_next_stage = `EXEC_TO_STORE;
         end

         `OP_JAL, `OP_JALR: begin
            // return address computed during decode, write to register
            write_reg = 1;
            exec_mux_reg_input_sel = `MUX_REGINPUT_ALU;
      
            // compute jal/jalr address
            alu_oper = `ALUOP_ADD;
            exec_mux_alu_s1_sel = (opcode[1]) ? `MUX_ALUDAT1_PC : `MUX_ALUDAT1_REGVAL1;
            exec_mux_alu_s2_sel = `MUX_ALUDAT2_IMM;
            exec_next_pc_from_alu = 1;
            exec_next_stage = `EXEC_TO_FETCH;
         end
   
         `OP_BRANCH: begin // use ALU for comparisons
            alu_oper = `ALUOP_ADD; // doesn't really matter
            exec_mux_alu_s1_sel = `MUX_ALUDAT1_REGVAL1;
            exec_mux_alu_s2_sel = `MUX_ALUDAT2_REGVAL2;
            exec_next_stage = `EXEC_TO_BRANCH;
         end

         `OP_AUIPC: begin // compute PC + IMM on ALU
            alu_oper = `ALUOP_ADD;
            exec_mux_alu_s1_sel = `MUX_ALUDAT1_PC;
            exec_mux_alu_s2_sel = `MUX_ALUDAT2_IMM;
            // do register writeback in FETCH
            exec_writeback_from_alu = 1;
            exec_next_stage = `EXEC_TO_FETCH;
         end

         `OP_LUI: begin
            exec_writeback_from_imm = 1;
            exec_mux_reg_input_sel = `MUX_REGINPUT_IMM;
            exec_next_stage = `EXEC_TO_FETCH;
         end

         `OP_MISCMEM:    exec_next_stage = `EXEC_TO_FETCH; // nop
         `OP_SYSTEM:     exec_next_stage = `EXEC_TO_SYSTEM;
         default:        exec_next_stage = `EXEC_TO_TRAP;
      endcase
    end
    else begin

      o_rs1 = I_instr[11:7];
      o_rs2 = I_instr[6:2];
      o_rd = I_instr[11:7];

      case(c_op)
        `C_OPC_C0: begin
/*
    | 15 14 13 | 12        | 11 10|9 8 7| 6 5      | 4 3 2 | 1 0 |
    |    000   | 0         |     0      |          0       | 00  | Illegal instruction
 -  |    000   | nzuimm[5:4;9:6;2;3]               | rd   | 00  | C.ADDI4SPN (RES, nzuimm=0)
 F  |    001   | uimm[5:3]        | rs1 | uimm[7:6]| rd   | 00  | C.FLD (RV32/64)
 D  |    001   | uimm[5:4;8]      | rs1 | uimm[7:6]| rd   | 00  | C.LQ (RV128)
 -  |    010   | uimm[5:3]        | rs1 | uimm[2;6]| rd   | 00  | C.LW
 F  |    011   | uimm[5:3]        | rs1 | uimm[2;6]| rd   | 00  | C.FLW (RV32)
 D  |    011   | uimm[5:3]        | rs1 | uimm[7:6]| rd   | 00  | C.LD (RV64/128)
 D  |    100   |                                          | 00  | Reserved
 D  |    101   | uimm[5:3]        | rs1 | uimm[7:6]| rs2  | 00  | C.FSD (RV32/64)
 D  |    101   | uimm[5:4;8]      | rs1 | uimm[7:6]| rs2  | 00  | C.SQ (RV128)
 -  |    110   | uimm[5:3]        | rs1 | uimm[2;6]| rs2  | 00  | C.SW
 D  |    111   | uimm[5:3]        | rs1 | uimm[2;6]| rs2  | 00  | C.FSW (RV32)
 D  |    111   | uimm[5:3]        | rs1 | uimm[7:6]| rs2  | 00  | C.SD (RV64/128)
*/
            o_rs1 = { 2'b01, I_instr[9:7] };
            o_rs2 = { 2'b01, I_instr[4:2] };
            o_rd =  { 2'b01, I_instr[4:2] };
            exec_mux_alu_s1_sel = `MUX_ALUDAT1_REGVAL1;
            exec_mux_alu_s2_sel = `MUX_ALUDAT2_IMM;
            case (c_funct3)
                `C0_F3_ADDI4SPN: begin
                    exec_next_stage = `EXEC_TO_DEAD;
                end
                `C0_F3_LW: begin
                    alu_oper = `ALUOP_ADD;
                    exec_next_stage = `EXEC_TO_LOAD;
                end
                `C0_F3_SW: begin
                    alu_oper = `ALUOP_ADD;
                    exec_next_stage = `EXEC_TO_STORE;
                end
                default: begin
                    exec_next_stage = `EXEC_TO_DEAD;
                end
            endcase
         end
        `C_OPC_C1: begin
/*
    | 15 14 13 | 12        | 11 10  | 9 8 7 | 6 5  |  4 3 2  | 1 0 |
 -  |   000    | 0         |      0         |    0           | 01  | C.NOP 
 -  |   000    | nzimm[5]  | rs1/rd6=0      | nzimm[4:0]     | 01  | C.ADDI (HINT, nzimm=0)
 -  |   001    |        imm[11;4;9:8;10;6;7;3:1;5]           | 01  | C.JAL (RV32)
 D  |   001    | imm[5]    | rs1/rd6=0      | imm[4:0]       | 01  | C.ADDIW (RV64/128; RES, rd=0)
 -  |   010    | imm[5]    |   rd6=0        | imm[4:0]       | 01  | C.LI (HINT, rd=0)
 -  |   011    | nzimm[9]  | 2              |nzimm[4;6;8:7;5]| 01  | C.ADDI16SP (RES, nzimm=0)
 -  |   011    | nzimm[17] | rd!={0, 2}     | nzimm[16:12]   | 01  | C.LUI (RES, nzimm=0; HINT, rd=0)

    | 15 14 13 | 12        | 11 10  | 9 8 7 | 6 5  |  4 3 2  | 1 0|
 -  |   100    | nzuimm[5] | 00     | rs1/rd| nzuimm[4:0]    | 01 | C.SRLI (RV32 NSE, nzuimm[5]=1)
 D  |   100    | 0         | 00     | rs1/rd| 0              | 01 | C.SRLI64 (RV128; RV32/64 HINT)
 -  |   100    | nzuimm[5] | 01     | rs1/rd| nzuimm[4:0]    | 01 | C.SRAI (RV32 NSE, nzuimm[5]=1)
 D  |   100    | 0         | 01     | rs1/rd| 0              | 01 | C.SRAI64 (RV128; RV32/64 HINT)
 -  |   100    | imm[5]    | 10     | rs1/rd| imm[4:0]       | 01 | C.ANDI
 -  |   100    | 0         | 11     | rs1/rd| 00   | rs2     | 01 | C.SUB
 -  |   100    | 0         | 11     | rs1/rd| 01   | rs2     | 01 | C.XOR
 -  |   100    | 0         | 11     | rs1/rd| 10   | rs2     | 01 | C.OR
 -  |   100    | 0         | 11     | rs1/rd| 11   | rs2     | 01 | C.AND
 D  |   100    | 1         | 11     | rs1/rd| 00   | rs2     | 01 | C.SUBW (RV64/128; RV32 RES)
 D  |   100    | 1         | 11     | rs1/rd| 01   | rs2     | 01 | C.ADDW (RV64/128; RV32 RES)
 D  |   100    | 1         | 11     |       | 10   |         | 01 | Reserved
 D  |   100    | 1         | 11     |       | 11   |         | 01 | Reserved
 -  |   101    |        imm[11;4;9:8;10;6;7;3:1;5]           | 01 | C.J
 -  |   110    | imm[8;4:3]         | rs10  | imm[7:6;2:1;5] | 01 | C.BEQZ
 -  |   111    | imm[8;4:3]         | rs10  | imm[7:6;2:1;5] | 01 | C.BNEZ
*/
            exec_next_stage = `EXEC_TO_FETCH;
         end
        `C_OPC_C2: begin
/*
    | 15 14 13 | 12        | 11 10 9 8 7 | 6 5 4 3 2    | 1 0  |
c+  |   000    | nzuimm[5] | rs1/rd!=0   | nzuimm[4:0]  |  10  | C.SLLI (HINT, rd=0; RV32 NSE, nzuimm[5]=1)
 h  |   000    | 0         | rs1/rd!=0   | 0            |  10  | C.SLLI64 (RV128; RV32/64 HINT; HINT, rd=0)
 F  |   001    | uimm[5]   | rd          | uimm[4:3;8:6]|  10  | C.FLDSP (RV32/64)
 D  |   001    | uimm[5]   | rd!=0       | uimm[4;9:6]  |  10  | C.LQSP (RV128; RES, rd=0)
c+  |   010    | uimm[5]   | rd!=0       | uimm[4:2;7:6]|  10  | C.LWSP (RES, rd=0)
 F  |   011    | uimm[5]   | rd          | uimm[4:2;7:6]|  10  | C.FLWSP (RV32)
 D  |   011    | uimm[5]   | rd!=0       | uimm[4:3;8:6]|  10  | C.LDSP (RV64/128; RES, rd=0)
c+  |   100    | 0         | rs1!=0      | 0            |  10  | C.JR (RES, rs1=0)
c+  |   100    | 0         | rd!=0       | rs2!=0       |  10  | C.MV (HINT, rd=0)
cN  |   100    | 1         | 0           |  0           |  10  | C.EBREAK
c+  |   100    | 1         | rs1!=0      |  0           |  10  | C.JALR
c+  |   100    | 1         | rs1/rd!=0   | rs2!=0       |  10  | C.ADD (HINT, rd=0)
 F  |   101    | uimm[5:3;8:6]           | rs2          |  10  | C.FSDSP (RV32/64)
 D  |   101    | uimm[5:4;9:6]           | rs2          |  10  | C.SQSP (RV128)
c+  |   110    | uimm[5:2;7:6]           | rs2          |  10  | C.SWSP
 F  |   111    | uimm[5:2;7:6]           | rs2          |  10  | C.FSWSP (RV32)
 D  |   111    | uimm[5:3;8:6]           | rs2          |  10  | C.SDSP (RV64/128)
*/
            case (c_funct3)
                `C2_F3_SLLI: begin
                    exec_mux_alu_s1_sel = `MUX_ALUDAT1_REGVAL1;
                    exec_mux_alu_s2_sel = `MUX_ALUDAT2_IMM;
                    alu_oper = `ALUOP_SLL;
                    exec_writeback_from_alu = 1;
                    exec_next_stage = `EXEC_TO_FETCH;
                    if (I_instr[12] == 1) begin exec_next_stage = `EXEC_TO_DEAD; end
                end
                `C2_F3_LWSP: begin
                    alu_oper = `ALUOP_ADD;
                    o_rs1 = 2 ;
                    exec_mux_alu_s1_sel = `MUX_ALUDAT1_REGVAL1;
                    exec_mux_alu_s2_sel = `MUX_ALUDAT2_IMM;
                    exec_next_stage = `EXEC_TO_LOAD;
                    if (o_rd == 0) begin exec_next_stage = `EXEC_TO_DEAD; end
                end
                `C2_F3_JR/*, `C2_F3_MV, `C2_F3_EBREAK,  `C2_F3_JALR, `C2_F3_CADD*/: begin
                    exec_mux_alu_s1_sel = `MUX_ALUDAT1_REGVAL1;
                    exec_mux_alu_s2_sel = `MUX_ALUDAT2_REGVAL2;

                    if (I_instr[12]) begin
                        if ( (I_instr[11:7] != 0) && (I_instr[6:2] != 0) ) begin // c.add
                            alu_oper = `ALUOP_ADD;
                            exec_writeback_from_alu = 1;
                            exec_next_stage = `EXEC_TO_FETCH;
                        end
                        if ( (I_instr[11:7] != 0) && (I_instr[6:2] == 0)) begin // c.jalr
                            write_reg = 1;
                            exec_mux_reg_input_sel = `MUX_REGINPUT_ALU;

                            alu_oper = `ALUOP_ADD;
                            exec_next_pc_from_alu = 1;
                            exec_next_stage = `EXEC_TO_FETCH;
                            o_rd = 1;
                        end
                        if ((I_instr[11:7] == 0) && (I_instr[6:2] == 0)) begin // c.ebreak
                            exec_next_stage = `EXEC_TO_DEAD; // we do not implement ebreak
                        end
                    end
                    else begin
                        if (o_rs2 == 0) begin //C.JR
                            if (o_rs1 == 0) begin //RES, when rs1 == 0
                                exec_next_stage = `EXEC_TO_DEAD;
                            end
                            else begin
                                // compute jal/jalr address
                                alu_oper = `ALUOP_ADD;
                                exec_next_pc_from_alu = 1;
                                exec_next_stage = `EXEC_TO_FETCH;
                            end
                        end
                        else begin //C.MV
                            exec_mux_alu_s1_sel = `MUX_ALUDAT1_REGVAL1;
                            exec_mux_alu_s2_sel = `MUX_ALUDAT2_REGVAL2;
                            o_rs1 = 0;
                            alu_oper = `ALUOP_ADD;
                            exec_writeback_from_alu = 1;
                            exec_next_stage = `EXEC_TO_FETCH;
                        end
                    end
                end
                `C2_F3_SWSP: begin
                    o_rs1 = 2 ;
                    alu_oper = `ALUOP_ADD;
                    exec_mux_alu_s1_sel = `MUX_ALUDAT1_REGVAL1;
                    exec_mux_alu_s2_sel = `MUX_ALUDAT2_IMM;
                    exec_next_stage = `EXEC_TO_STORE;
                end
                default: begin
                    exec_next_stage = `EXEC_TO_DEAD;
                end
            endcase
        end
        default: begin
            exec_next_stage = `EXEC_TO_DEAD;
        end
      endcase
    end
   end

endmodule
